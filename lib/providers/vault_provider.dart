import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intruder_log_model.dart';

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
  static const _keyPrivateSecret = 'vault_private_secret';
  static const _keyLibraryPin = 'vault_library_pin';
  static const _keyAutoLock = 'vault_auto_lock_minutes';

  // Credentials (Configured by user in onboarding or security setup)
  String _privateChatSecret = '';
  String _libraryPin = '';

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
  bool get hasPrivateSecret => _privateChatSecret.isNotEmpty;
  bool get hasLibraryPin => _libraryPin.isNotEmpty;
  int get autoLockMinutes => _autoLockMinutes;
  HideModeSettings get hideMode => _hideMode;
  List<IntruderLogModel> get intruderLogs => _intruderLogs;

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

  // Private Chat unlock/lock
  bool verifyPasscode(String inputSecret) =>
      inputSecret.trim() == _privateChatSecret;

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

  void lockPrivate() {
    _isPrivateUnlocked = false;
    notifyListeners();
  }

  // Library Vault unlock/lock (Accepts ANY passcode, string, or digits)
  bool unlockLibrary(String inputPasscode) {
    if (isLibraryLockedOut) return false;

    final cleanInput = inputPasscode.trim();
    if (cleanInput == _libraryPin) {
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

  void lockLibrary() {
    _isLibraryUnlocked = false;
    notifyListeners();
  }

  // Intruder Attempt Recorder
  void recordLoginIntruderAttempt(int failedCount) {
    _recordIntruderAttempt('login', failedCount);
  }

  void _recordIntruderAttempt(String type, int count) {
    final log = IntruderLogModel(
      id: 'intruder_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      attemptType: type,
      failedAttempts: count,
      // Simulated camera capture frame placeholder
      photoBase64: 'captured_intruder_frame',
    );
    _intruderLogs.add(log);
    notifyListeners();
  }

  void clearIntruderLogs() {
    _intruderLogs.clear();
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

  /// Attach active user ID and sync secrets from Firebase Realtime Database
  Future<void> attachUser(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    _currentUserId = userId;
    await syncFromDb(userId);
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
        final dbSecret = (data['privateChatSecret'] ?? '').toString();
        final dbPin = (data['libraryPin'] ?? '').toString();

        if (dbSecret.isNotEmpty) {
          _privateChatSecret = dbSecret;
        }
        if (dbPin.isNotEmpty) {
          _libraryPin = dbPin;
        }

        // Cache locally for offline availability
        final prefs = await SharedPreferences.getInstance();
        if (_privateChatSecret.isNotEmpty) {
          await prefs.setString(_keyPrivateSecret, _privateChatSecret);
        }
        if (_libraryPin.isNotEmpty) {
          await prefs.setString(_keyLibraryPin, _libraryPin);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Firebase Vault sync error: $e');
    }
  }

  /// Load saved credentials from local storage on initial startup (offline fallback)
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _privateChatSecret = prefs.getString(_keyPrivateSecret) ?? '';
    _libraryPin = prefs.getString(_keyLibraryPin) ?? '';
    _autoLockMinutes = prefs.getInt(_keyAutoLock) ?? 5;
    notifyListeners();
  }

  // Update credentials (saved to Firebase Realtime Database & local cache)
  Future<void> setPrivateChatSecret(String newSecret, {String? userId}) async {
    _privateChatSecret = newSecret.trim();
    final uid = userId ?? _currentUserId;

    // Save to Firebase Realtime Database
    if (uid != null && uid.isNotEmpty) {
      try {
        await FirebaseDatabase.instance
            .ref('users/$uid/security_vault/privateChatSecret')
            .set(_privateChatSecret);
      } catch (e) {
        debugPrint('Firebase save private secret error: $e');
      }
    }

    // Local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrivateSecret, _privateChatSecret);
    notifyListeners();
  }

  Future<void> setLibraryPin(String newPin, {String? userId}) async {
    _libraryPin = newPin.trim();
    final uid = userId ?? _currentUserId;

    // Save to Firebase Realtime Database
    if (uid != null && uid.isNotEmpty) {
      try {
        await FirebaseDatabase.instance
            .ref('users/$uid/security_vault/libraryPin')
            .set(_libraryPin);
      } catch (e) {
        debugPrint('Firebase save library pin error: $e');
      }
    }

    // Local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLibraryPin, _libraryPin);
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

