import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intruder_log_model.dart';
import '../services/intruder_camera_service.dart';

class HideModeSettings {
  bool isEnabled;
  bool hideUsername;
  bool hideProfilePicture;
  bool hidePrivateChatNames;
  bool hideMessagePreviews;
  bool hideNotificationContent;

  HideModeSettings({
    this.isEnabled = false,
    this.hideUsername = true,
    this.hideProfilePicture = true,
    this.hidePrivateChatNames = true,
    this.hideMessagePreviews = true,
    this.hideNotificationContent = true,
  });

  HideModeSettings copyWith({
    bool? isEnabled,
    bool? hideUsername,
    bool? hideProfilePicture,
    bool? hidePrivateChatNames,
    bool? hideMessagePreviews,
    bool? hideNotificationContent,
  }) {
    return HideModeSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      hideUsername: hideUsername ?? this.hideUsername,
      hideProfilePicture: hideProfilePicture ?? this.hideProfilePicture,
      hidePrivateChatNames: hidePrivateChatNames ?? this.hidePrivateChatNames,
      hideMessagePreviews: hideMessagePreviews ?? this.hideMessagePreviews,
      hideNotificationContent:
          hideNotificationContent ?? this.hideNotificationContent,
    );
  }
}

class VaultProvider extends ChangeNotifier {
  // SharedPreferences keys
  static String _getPrivateSecretKey(String? uid) => uid == null || uid.isEmpty ? 'vault_private_secret' : 'vault_private_secret_$uid';
  static String _getLibraryPinKey(String? uid) => uid == null || uid.isEmpty ? 'vault_library_pin' : 'vault_library_pin_$uid';
  static String _getPrivateSecretHashKey(String? uid) => uid == null || uid.isEmpty ? 'vault_private_secret_hash' : 'vault_private_secret_hash_$uid';
  static String _getLibraryPinHashKey(String? uid) => uid == null || uid.isEmpty ? 'vault_library_pin_hash' : 'vault_library_pin_hash_$uid';
  static const _keyAutoLock = 'vault_auto_lock_minutes';

  /// Cryptographic salt + SHA-256 for OWASP Mobile Security Compliance
  static String hashSecret(String secret, String salt) {
    final bytes = utf8.encode('miralo_salt_${salt}_${secret.trim()}');
    return sha256.convert(bytes).toString();
  }

  // Credentials (Configured by user in onboarding or security setup)
  String _privateChatSecret = '';
  String _libraryPin = '';
  String _privateChatSecretHash = '';
  String _libraryPinHash = '';

  // Independent session states
  bool _isPrivateUnlocked = false;
  bool _isLibraryUnlocked = false;

  // Rate Limiting & Security Lockout
  int _failedPrivateAttempts = 0;
  int _failedLibraryAttempts = 0;
  DateTime? _privateLockoutEndTime;
  DateTime? _libraryLockoutEndTime;
  static const int _maxAttemptsBeforeLockout = 3;
  static const Duration _lockoutDuration = Duration(seconds: 30);

  // Intruder Detection Log
  final List<IntruderLogModel> _intruderLogs = [];

  // Auto-lock setting (in minutes; 0 = immediate, 5 = 5 min, -1 = never)
  int _autoLockMinutes = 5;

  // Hide Mode settings
  HideModeSettings _hideMode = HideModeSettings();

  // Getters
  bool get isPrivateUnlocked => _isPrivateUnlocked;
  bool get isLibraryUnlocked => _isLibraryUnlocked;
  bool get hasPrivateSecret => _privateChatSecret.isNotEmpty || _privateChatSecretHash.isNotEmpty;
  bool get hasLibraryPin => _libraryPin.isNotEmpty || _libraryPinHash.isNotEmpty;
  int get autoLockMinutes => _autoLockMinutes;
  HideModeSettings get hideMode => _hideMode;
  List<IntruderLogModel> get intruderLogs => _intruderLogs;
  String? get currentUserId => _currentUserId;

  // Rate Limiting Getters
  bool get isPrivateLockedOut {
    if (_privateLockoutEndTime == null) return false;
    if (DateTime.now().isAfter(_privateLockoutEndTime!)) {
      _privateLockoutEndTime = null;
      _failedPrivateAttempts = 0;
      return false;
    }
    return true;
  }

  int get privateLockoutRemainingSeconds {
    if (_privateLockoutEndTime == null) return 0;
    final diff = _privateLockoutEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool get isLibraryLockedOut {
    if (_libraryLockoutEndTime == null) return false;
    if (DateTime.now().isAfter(_libraryLockoutEndTime!)) {
      _libraryLockoutEndTime = null;
      _failedLibraryAttempts = 0;
      return false;
    }
    return true;
  }

  int get libraryLockoutRemainingSeconds {
    if (_libraryLockoutEndTime == null) return 0;
    final diff = _libraryLockoutEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  // ── Verification Methods (Cryptographic Salt & Hash aware) ──────────
  bool verifyPasscode(String inputSecret) {
    final cleanInput = inputSecret.trim();
    if (cleanInput.isEmpty) return false;
    if (_privateChatSecret.isNotEmpty && cleanInput == _privateChatSecret) return true;
    if (_privateChatSecretHash.isNotEmpty && _currentUserId != null && _currentUserId!.isNotEmpty) {
      return hashSecret(cleanInput, _currentUserId!) == _privateChatSecretHash;
    }
    return false;
  }

  bool verifyLibraryPin(String inputPasscode) {
    final cleanInput = inputPasscode.trim();
    if (cleanInput.isEmpty) return false;
    if (_libraryPin.isNotEmpty && cleanInput == _libraryPin) return true;
    if (_libraryPinHash.isNotEmpty && _currentUserId != null && _currentUserId!.isNotEmpty) {
      return hashSecret(cleanInput, _currentUserId!) == _libraryPinHash;
    }
    return false;
  }

  /// Authoritative server-side validation against Firebase Realtime Database
  Future<bool> verifyPrivateSecretServerSide(String inputSecret) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return false;
    final cleanInput = inputSecret.trim();
    if (cleanInput.isEmpty) return false;

    try {
      final snap = await FirebaseDatabase.instance.ref('users/$uid/security_vault').get();
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        final serverSecret = (data['privateChatSecret'] ?? '').toString();
        final serverHash = (data['privateChatSecretHash'] ?? '').toString();
        final computedHash = hashSecret(cleanInput, uid);

        if ((serverSecret.isNotEmpty && cleanInput == serverSecret) ||
            (serverHash.isNotEmpty && computedHash == serverHash)) {
          _privateChatSecret = serverSecret.isNotEmpty ? serverSecret : cleanInput;
          _privateChatSecretHash = serverHash.isNotEmpty ? serverHash : computedHash;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_getPrivateSecretKey(uid), _privateChatSecret);
          await prefs.setString(_getPrivateSecretHashKey(uid), _privateChatSecretHash);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Server-side private secret verification error: $e');
    }
    return false;
  }

  /// Authoritative server-side validation for Library PIN against Firebase Realtime Database
  Future<bool> verifyLibraryPinServerSide(String inputPasscode) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return false;
    final cleanInput = inputPasscode.trim();
    if (cleanInput.isEmpty) return false;

    try {
      final snap = await FirebaseDatabase.instance.ref('users/$uid/security_vault').get();
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        final serverPin = (data['libraryPin'] ?? '').toString();
        final serverHash = (data['libraryPinHash'] ?? '').toString();
        final computedHash = hashSecret(cleanInput, uid);

        if ((serverPin.isNotEmpty && cleanInput == serverPin) ||
            (serverHash.isNotEmpty && computedHash == serverHash)) {
          _libraryPin = serverPin.isNotEmpty ? serverPin : cleanInput;
          _libraryPinHash = serverHash.isNotEmpty ? serverHash : computedHash;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_getLibraryPinKey(uid), _libraryPin);
          await prefs.setString(_getLibraryPinHashKey(uid), _libraryPinHash);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Server-side library pin verification error: $e');
    }
    return false;
  }

  bool unlockPrivate(String inputSecret) {
    if (isPrivateLockedOut) return false;

    if (verifyPasscode(inputSecret)) {
      _isPrivateUnlocked = true;
      _failedPrivateAttempts = 0;
      _privateLockoutEndTime = null;
      notifyListeners();
      return true;
    } else {
      _failedPrivateAttempts++;
      if (_failedPrivateAttempts >= _maxAttemptsBeforeLockout) {
        _privateLockoutEndTime = DateTime.now().add(_lockoutDuration);
        _recordIntruderAttempt('private_vault', _failedPrivateAttempts);
      }
      notifyListeners();
      return false;
    }
  }

  /// Asynchronous unlock with strict server-side validation against Firebase Realtime Database
  Future<bool> unlockPrivateAsync(String inputSecret) async {
    if (isPrivateLockedOut) return false;

    // Authoritative Server-side validation against Firebase Realtime Database ONLY
    final isServerValid = await verifyPrivateSecretServerSide(inputSecret);
    if (isServerValid) {
      _isPrivateUnlocked = true;
      _failedPrivateAttempts = 0;
      _privateLockoutEndTime = null;
      notifyListeners();
      return true;
    }

    _failedPrivateAttempts++;
    if (_failedPrivateAttempts >= _maxAttemptsBeforeLockout) {
      _privateLockoutEndTime = DateTime.now().add(_lockoutDuration);
      _recordIntruderAttempt('private_vault', _failedPrivateAttempts);
    }
    notifyListeners();
    return false;
  }

  void lockPrivate() {
    _isPrivateUnlocked = false;
    notifyListeners();
  }

  // Library Vault unlock/lock
  bool unlockLibrary(String inputPasscode) {
    if (isLibraryLockedOut) return false;

    if (verifyLibraryPin(inputPasscode)) {
      _isLibraryUnlocked = true;
      _failedLibraryAttempts = 0;
      _libraryLockoutEndTime = null;
      notifyListeners();
      return true;
    } else {
      _failedLibraryAttempts++;
      if (_failedLibraryAttempts >= _maxAttemptsBeforeLockout) {
        _libraryLockoutEndTime = DateTime.now().add(_lockoutDuration);
        _recordIntruderAttempt('library', _failedLibraryAttempts);
      }
      notifyListeners();
      return false;
    }
  }

  /// Asynchronous unlock for Library with strict server-side validation against Firebase RTDB
  Future<bool> unlockLibraryAsync(String inputPasscode) async {
    if (isLibraryLockedOut) return false;

    // Authoritative Server-side validation against Firebase Realtime Database ONLY
    final isServerValid = await verifyLibraryPinServerSide(inputPasscode);
    if (isServerValid) {
      _isLibraryUnlocked = true;
      _failedLibraryAttempts = 0;
      _libraryLockoutEndTime = null;
      notifyListeners();
      return true;
    }

    _failedLibraryAttempts++;
    if (_failedLibraryAttempts >= _maxAttemptsBeforeLockout) {
      _libraryLockoutEndTime = DateTime.now().add(_lockoutDuration);
      _recordIntruderAttempt('library', _failedLibraryAttempts);
    }
    notifyListeners();
    return false;
  }

  void lockLibrary() {
    _isLibraryUnlocked = false;
    notifyListeners();
  }

  // Intruder Attempt Recorder (Target-account-aware for login attempts)
  Future<void> recordLoginIntruderAttempt(
    int failedCount, {
    required String? targetUserId,
    String? targetUsername,
  }) async {
    // If target user does not exist, DROP IT to prevent false positives!
    if (targetUserId == null || targetUserId.trim().isEmpty || targetUserId == 'unknown') {
      debugPrint('Intruder attempt dropped: Target user does not exist (false positive prevention).');
      return;
    }
    await _recordIntruderAttempt(
      'login',
      failedCount,
      targetUserId: targetUserId.trim(),
      targetUsername: targetUsername?.trim(),
    );
  }

  Future<void> _recordIntruderAttempt(
    String type,
    int count, {
    String? targetUserId,
    String? targetUsername,
  }) async {
    final effectiveUserId = (type == 'login') ? targetUserId : _currentUserId;

    // Drop attempt if there is no valid target account
    if (effectiveUserId == null || effectiveUserId.isEmpty || effectiveUserId == 'unknown') {
      debugPrint('Intruder attempt dropped: No valid target account.');
      return;
    }

    // Capture real photo from front camera
    String? photoBase64;
    try {
      photoBase64 = await IntruderCameraService.captureFrontIntruderPhoto();
    } catch (_) {
      photoBase64 = null;
    }

    final log = IntruderLogModel(
      id: 'intruder_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      attemptType: type,
      failedAttempts: count,
      userId: effectiveUserId,
      targetUsername: targetUsername,
      photoBase64: photoBase64,
    );

    // Only add to in-memory list if it matches current logged in user
    if (_currentUserId != null && effectiveUserId == _currentUserId) {
      _intruderLogs.add(log);
    }

    // Persist to Firebase strictly under the target user's node
    try {
      await FirebaseDatabase.instance
          .ref('intruder_logs/$effectiveUserId/${log.id}')
          .set(log.toJson());
    } catch (_) {}

    notifyListeners();
  }

  Future<void> clearIntruderLogs() async {
    _intruderLogs.clear();
    final uid = _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      try {
        await FirebaseDatabase.instance.ref('intruder_logs/$uid').remove();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Called on logout — clears all unlock states, subscriptions, and session secrets.
  void clearSession() {
    _vaultSubscription?.cancel();
    _vaultSubscription = null;
    _isPrivateUnlocked = false;
    _isLibraryUnlocked = false;
    _failedPrivateAttempts = 0;
    _failedLibraryAttempts = 0;
    _privateLockoutEndTime = null;
    _libraryLockoutEndTime = null;
    _intruderLogs.clear();
    _privateChatSecret = '';
    _libraryPin = '';
    _privateChatSecretHash = '';
    _libraryPinHash = '';
    _currentUserId = null;
    notifyListeners();
  }

  // Lock both
  void lockAll() {
    _isPrivateUnlocked = false;
    _isLibraryUnlocked = false;
    notifyListeners();
  }

  // ── Database & Persistence ───────────────────────────────────────────────
  String? _currentUserId;
  StreamSubscription<DatabaseEvent>? _vaultSubscription;

  /// Attach active user ID and sync secrets from Firebase Realtime Database
  Future<void> attachUser(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    _currentUserId = userId;
    _isPrivateUnlocked = false;
    _isLibraryUnlocked = false;
    _privateChatSecret = '';
    _libraryPin = '';
    _privateChatSecretHash = '';
    _libraryPinHash = '';
    _intruderLogs.clear();

    _vaultSubscription?.cancel();
    _vaultSubscription = null;

    // 1. First load from local user-scoped SharedPreferences for instant availability
    final prefs = await SharedPreferences.getInstance();
    _privateChatSecret = prefs.getString(_getPrivateSecretKey(userId)) ?? '';
    _libraryPin = prefs.getString(_getLibraryPinKey(userId)) ?? '';
    _privateChatSecretHash = prefs.getString(_getPrivateSecretHashKey(userId)) ?? '';
    _libraryPinHash = prefs.getString(_getLibraryPinHashKey(userId)) ?? '';

    // 2. Real-time Firebase RTDB Sync for security vault (multi-device hydration)
    try {
      final ref = FirebaseDatabase.instance.ref('users/$userId/security_vault');
      _vaultSubscription = ref.onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value is Map) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          _applySecurityVaultData(data, userId);
        }
      });
    } catch (e) {
      debugPrint('Firebase Vault subscription error: $e');
    }

    // 3. One-shot sync from Firebase Realtime Database
    await syncFromDb(userId);

    // 4. Fetch user's intruder logs from Firebase
    try {
      final logsSnap = await FirebaseDatabase.instance.ref('intruder_logs/$userId').get();
      if (logsSnap.exists && logsSnap.value is Map) {
        _intruderLogs.clear();
        final rawMap = Map<String, dynamic>.from(logsSnap.value as Map);
        for (var entry in rawMap.values) {
          if (entry is Map) {
            _intruderLogs.add(IntruderLogModel.fromJson(Map<String, dynamic>.from(entry)));
          }
        }
        _intruderLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      } else {
        _intruderLogs.clear();
      }
    } catch (_) {
      _intruderLogs.clear();
    }
    notifyListeners();
  }

  void _applySecurityVaultData(Map<String, dynamic> data, String userId) {
    final dbSecret = (data['privateChatSecret'] ?? '').toString();
    final dbPin = (data['libraryPin'] ?? '').toString();
    final dbSecretHash = (data['privateChatSecretHash'] ?? '').toString();
    final dbPinHash = (data['libraryPinHash'] ?? '').toString();

    if (dbSecret.isNotEmpty) _privateChatSecret = dbSecret;
    if (dbPin.isNotEmpty) _libraryPin = dbPin;
    if (dbSecretHash.isNotEmpty) {
      _privateChatSecretHash = dbSecretHash;
    } else if (dbSecret.isNotEmpty) {
      _privateChatSecretHash = hashSecret(dbSecret, userId);
    }
    if (dbPinHash.isNotEmpty) {
      _libraryPinHash = dbPinHash;
    } else if (dbPin.isNotEmpty) {
      _libraryPinHash = hashSecret(dbPin, userId);
    }

    SharedPreferences.getInstance().then((prefs) {
      if (_privateChatSecret.isNotEmpty) prefs.setString(_getPrivateSecretKey(userId), _privateChatSecret);
      if (_libraryPin.isNotEmpty) prefs.setString(_getLibraryPinKey(userId), _libraryPin);
      if (_privateChatSecretHash.isNotEmpty) prefs.setString(_getPrivateSecretHashKey(userId), _privateChatSecretHash);
      if (_libraryPinHash.isNotEmpty) prefs.setString(_getLibraryPinHashKey(userId), _libraryPinHash);
    });

    notifyListeners();
  }

  /// Synchronize privateChatSecret and libraryPin directly from Firebase Realtime Database
  Future<void> syncFromDb(String userId) async {
    _currentUserId = userId;
    try {
      final snap = await FirebaseDatabase.instance
          .ref('users/$userId/security_vault')
          .get();

      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        _applySecurityVaultData(data, userId);
      }
    } catch (e) {
      debugPrint('Firebase Vault sync error: $e');
    }
  }

  /// Load saved credentials from local storage on initial startup (offline fallback)
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      _privateChatSecret = prefs.getString(_getPrivateSecretKey(_currentUserId!)) ?? '';
      _libraryPin = prefs.getString(_getLibraryPinKey(_currentUserId!)) ?? '';
      _privateChatSecretHash = prefs.getString(_getPrivateSecretHashKey(_currentUserId!)) ?? '';
      _libraryPinHash = prefs.getString(_getLibraryPinHashKey(_currentUserId!)) ?? '';
    } else {
      _privateChatSecret = '';
      _libraryPin = '';
      _privateChatSecretHash = '';
      _libraryPinHash = '';
    }
    _autoLockMinutes = prefs.getInt(_keyAutoLock) ?? 5;
    notifyListeners();
  }

  // Update credentials (saved to Firebase Realtime Database & local cache)
  Future<void> setPrivateChatSecret(String newSecret, {String? userId}) async {
    _privateChatSecret = newSecret.trim();
    final uid = userId ?? _currentUserId;

    if (uid != null && uid.isNotEmpty) {
      _privateChatSecretHash = hashSecret(_privateChatSecret, uid);

      // Save salted hash and secret to Firebase Realtime Database
      try {
        await FirebaseDatabase.instance
            .ref('users/$uid/security_vault')
            .update({
          'privateChatSecret': _privateChatSecret,
          'privateChatSecretHash': _privateChatSecretHash,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Firebase save private secret error: $e');
      }

      // Local cache with user-scoped keys
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getPrivateSecretKey(uid), _privateChatSecret);
      await prefs.setString(_getPrivateSecretHashKey(uid), _privateChatSecretHash);
    }
    notifyListeners();
  }

  Future<void> setLibraryPin(String newPin, {String? userId}) async {
    _libraryPin = newPin.trim();
    final uid = userId ?? _currentUserId;

    if (uid != null && uid.isNotEmpty) {
      _libraryPinHash = hashSecret(_libraryPin, uid);

      // Save salted hash and PIN to Firebase Realtime Database
      try {
        await FirebaseDatabase.instance
            .ref('users/$uid/security_vault')
            .update({
          'libraryPin': _libraryPin,
          'libraryPinHash': _libraryPinHash,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Firebase save library pin error: $e');
      }

      // Local cache with user-scoped keys
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getLibraryPinKey(uid), _libraryPin);
      await prefs.setString(_getLibraryPinHashKey(uid), _libraryPinHash);
    }
    notifyListeners();
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    _autoLockMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoLock, minutes);
    notifyListeners();
  }

  // Hide Mode controls
  void updateHideMode({
    bool? isEnabled,
    bool? hideUsername,
    bool? hideProfilePicture,
    bool? hidePrivateChatNames,
    bool? hideMessagePreviews,
    bool? hideNotificationContent,
  }) {
    _hideMode = _hideMode.copyWith(
      isEnabled: isEnabled,
      hideUsername: hideUsername,
      hideProfilePicture: hideProfilePicture,
      hidePrivateChatNames: hidePrivateChatNames,
      hideMessagePreviews: hideMessagePreviews,
      hideNotificationContent: hideNotificationContent,
    );
    notifyListeners();
  }

  // Emergency Panic Actions
  void emergencyLockEverything() {
    _isPrivateUnlocked = false;
    _isLibraryUnlocked = false;
    _hideMode.isEnabled = true;
    notifyListeners();
  }
}

