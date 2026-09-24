import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/cloudinary_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _prefUserKey = 'miralo_auth_user_v2';

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isSpecialUser {
    if (_currentUser == null) return false;
    final u = _currentUser!.username.toLowerCase().trim();
    return u == 'aarushlohit' || u == 'ashlinmirsha';
  }

  String? _lastFailedTargetUserId;
  String? _lastFailedTargetUsername;

  /// Holds the target account's userId if a login failed for an existing account (wrong password).
  /// Null if the username/email does not exist (wrong username, false positive).
  String? get lastFailedTargetUserId => _lastFailedTargetUserId;
  String? get lastFailedTargetUsername => _lastFailedTargetUsername;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    loadFromStorage();
  }

  Future<void> loadFromStorage() async {
    // 1. Immediately read cached credentials from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefUserKey);
      if (raw != null && raw.isNotEmpty) {
        _currentUser = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading cached user: $e');
    }

    // 2. Cross-check with active Firebase Auth session
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        // If local user is missing or UID mismatch, restore from DB
        if (_currentUser == null || _currentUser!.id != fbUser.uid) {
          try {
            final snap = await FirebaseDatabase.instance.ref('users/${fbUser.uid}').get();
            if (snap.exists && snap.value != null && snap.value is Map) {
              final data = Map<String, dynamic>.from(snap.value as Map);
              _currentUser = UserModel.fromJson(data);
            }
          } catch (dbErr) {
            debugPrint('Error fetching DB user record: $dbErr');
          }

          if (_currentUser == null) {
            final uname = fbUser.displayName?.toLowerCase().replaceAll(' ', '_') ??
                fbUser.email?.split('@').first.toLowerCase() ??
                'user';
            _currentUser = UserModel(
              id: fbUser.uid,
              displayName: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'User',
              username: uname,
              email: fbUser.email ?? '',
              avatarUrl: fbUser.photoURL,
              createdAt: DateTime.now(),
            );
          }
          await _saveUser();
        }
      }
    } catch (e) {
      debugPrint('FirebaseAuth session check notice: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString(_prefUserKey, jsonEncode(_currentUser!.toJson()));
    } else {
      await prefs.remove(_prefUserKey);
    }
  }

  Future<bool> login(String emailOrUsername, String password, {String? username}) async {
    _isLoading = true;
    _errorMessage = null;
    _lastFailedTargetUserId = null;
    _lastFailedTargetUsername = null;
    notifyListeners();

    final cleanInput = emailOrUsername.trim().toLowerCase();
    String resolvedEmail = cleanInput;

    // If identifier is a username (no @), resolve email via user_index
    if (!cleanInput.contains('@')) {
      try {
        final snap = await FirebaseDatabase.instance.ref('user_index/$cleanInput').get();
        if (snap.exists && snap.value != null && snap.value is Map) {
          final data = Map<String, dynamic>.from(snap.value as Map);
          final emailFromIndex = data['email']?.toString();
          final uidFromIndex = data['id']?.toString() ?? data['userId']?.toString();
          final usernameFromIndex = data['username']?.toString() ?? cleanInput;
          if (emailFromIndex != null && emailFromIndex.isNotEmpty) {
            resolvedEmail = emailFromIndex.trim().toLowerCase();
            // Valid existing user found! Save target info in case password is wrong
            _lastFailedTargetUserId = uidFromIndex;
            _lastFailedTargetUsername = usernameFromIndex;
          } else {
            _isLoading = false;
            _errorMessage = 'Incorrect email, username or password. Please try again.';
            notifyListeners();
            return false;
          }
        } else {
          // Username not found in index. To prevent false positives, target stays null.
          _isLoading = false;
          _errorMessage = 'Incorrect email, username or password. Please try again.';
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('Username lookup error: $e');
        if (!e.toString().contains('no-app')) {
          _isLoading = false;
          _errorMessage = 'Incorrect email, username or password. Please try again.';
          notifyListeners();
          return false;
        }
      }
    } else {
      // Identifier is an email (contains @)
      try {
        final safeEmailKey = cleanInput.replaceAll('.', '_').replaceAll('@', '_at_');
        final emailSnap = await FirebaseDatabase.instance.ref('email_index/$safeEmailKey').get();
        if (emailSnap.exists && emailSnap.value != null && emailSnap.value is Map) {
          final data = Map<String, dynamic>.from(emailSnap.value as Map);
          _lastFailedTargetUserId = data['userId']?.toString() ?? data['id']?.toString();
          _lastFailedTargetUsername = data['username']?.toString() ?? cleanInput.split('@').first;
        } else {
          // Fallback: search users node directly
          final usersSnap = await FirebaseDatabase.instance.ref('users').get();
          if (usersSnap.exists && usersSnap.value is Map) {
            final rawUsers = Map<String, dynamic>.from(usersSnap.value as Map);
            for (var entry in rawUsers.entries) {
              if (entry.value is Map) {
                final uData = Map<String, dynamic>.from(entry.value as Map);
                final uEmail = (uData['email'] ?? '').toString().toLowerCase().trim();
                if (uEmail == cleanInput) {
                  _lastFailedTargetUserId = entry.key.toString();
                  _lastFailedTargetUsername = uData['username']?.toString() ?? cleanInput.split('@').first;
                  break;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Email lookup notice: $e');
      }
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password.trim(),
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        _isLoading = false;
        _errorMessage = 'Authentication failed. Please try again.';
        notifyListeners();
        return false;
      }

      // 1. Attempt to fetch canonical user profile from Firebase Realtime Database
      try {
        final snap = await FirebaseDatabase.instance.ref('users/$uid').get();
        if (snap.exists && snap.value != null && snap.value is Map) {
          final data = Map<String, dynamic>.from(snap.value as Map);
          _currentUser = UserModel.fromJson(data);
        }
      } catch (dbErr) {
        debugPrint('Notice loading profile from DB: $dbErr');
      }

      // 2. If not found in DB yet, construct from Firebase Auth credential
      if (_currentUser == null) {
        final uname = (username != null && username.trim().isNotEmpty)
            ? username.trim().toLowerCase()
            : (cleanInput.contains('@') ? cleanInput.split('@').first : cleanInput);

        _currentUser = UserModel(
          id: uid,
          displayName: credential.user?.displayName ?? cleanInput.split('@').first,
          username: uname,
          email: resolvedEmail,
          avatarUrl: credential.user?.photoURL,
          createdAt: DateTime.now(),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException login: ${e.code} - ${e.message}');
      _isLoading = false;
      if (e.code == 'user-not-found') {
        _lastFailedTargetUserId = null;
        _lastFailedTargetUsername = null;
      }
      if (e.code == 'user-disabled') {
        _errorMessage = 'This account has been disabled.';
      } else {
        // Prevent username enumeration: Return identical generic message
        _errorMessage = 'Incorrect email, username or password. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      if (e.toString().contains('no-app')) {
        // In local test environments without Firebase native app initialization
        final uname = (username != null && username.trim().isNotEmpty)
            ? username.trim().toLowerCase()
            : (cleanInput.contains('@') ? cleanInput.split('@').first : cleanInput);

        _currentUser = UserModel(
          id: 'usr_$uname',
          displayName: uname,
          username: uname,
          email: resolvedEmail,
          createdAt: DateTime.now(),
        );
      } else {
        debugPrint('Login exception: $e');
        _isLoading = false;
        _errorMessage = 'Incorrect email, username or password. Please try again.';
        notifyListeners();
        return false;
      }
    }

    _lastFailedTargetUserId = null;
    _lastFailedTargetUsername = null;
    _isLoading = false;
    await _saveUser();
    _syncUserToFirebase();
    notifyListeners();
    return true;
  }

  Future<bool> signup(
    String displayName,
    String email,
    String password, {
    String? username,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final uname = (username != null && username.trim().isNotEmpty)
        ? username.trim().toLowerCase()
        : displayName.toLowerCase().replaceAll(' ', '_');

    // 1. Check if username is already taken in database
    try {
      final userIndexSnap = await FirebaseDatabase.instance
          .ref('user_index/$uname')
          .get();
      if (userIndexSnap.exists && userIndexSnap.value != null) {
        _isLoading = false;
        _errorMessage = 'Username "$uname" is already taken. Please choose another.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Username availability check notice: $e');
    }

    // 2. Check if email is already taken in database
    final safeEmailKey = cleanEmail.replaceAll('.', '_').replaceAll('@', '_at_');
    try {
      final emailIndexSnap = await FirebaseDatabase.instance
          .ref('email_index/$safeEmailKey')
          .get();
      if (emailIndexSnap.exists && emailIndexSnap.value != null) {
        _isLoading = false;
        _errorMessage = 'An account with email "$cleanEmail" already exists.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Email availability check notice: $e');
    }

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password.trim(),
      );

      final uid = credential.user?.uid ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';
      await credential.user?.updateDisplayName(displayName);

      _currentUser = UserModel(
        id: uid,
        displayName: displayName,
        username: uname,
        email: cleanEmail,
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during signup: ${e.code} - ${e.message}');
      _isLoading = false;
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'An account with email "$cleanEmail" already exists.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'The email address is invalid.';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'The password is too weak.';
      } else {
        _errorMessage = e.message ?? 'Sign up failed. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('FirebaseAuth signup fallback: $e');
      _currentUser = UserModel(
        id: 'usr_${uname}_${DateTime.now().millisecondsSinceEpoch}',
        displayName: displayName,
        username: uname,
        email: cleanEmail,
        createdAt: DateTime.now(),
      );
    }

    _isLoading = false;
    _errorMessage = null;
    await _saveUser();
    _syncUserToFirebase();
    notifyListeners();
    return true;
  }

  void _syncUserToFirebase() {
    if (_currentUser == null) return;
    try {
      final ref = FirebaseDatabase.instance.ref('users/${_currentUser!.id}');
      ref.update(_currentUser!.toJson());
      // Also write username index for fast add friend search and uniqueness
      FirebaseDatabase.instance
          .ref('user_index/${_currentUser!.username}')
          .set(_currentUser!.toJson());
      // Also write email index to prevent duplicate account creation
      final safeEmailKey = _currentUser!.email.toLowerCase().replaceAll('.', '_').replaceAll('@', '_at_');
      FirebaseDatabase.instance
          .ref('email_index/$safeEmailKey')
          .set({
        'userId': _currentUser!.id,
        'username': _currentUser!.username,
        'email': _currentUser!.email,
      });
    } catch (e) {
      debugPrint('Firebase Database user sync error: $e');
    }
  }

  void updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? note,
  }) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      displayName: displayName,
      username: username,
      avatarUrl: avatarUrl,
      bio: bio,
      note: note,
    );
    _saveUser();
    _syncUserToFirebase();
    notifyListeners();
  }

  Future<String?> uploadCustomAvatar(Uint8List fileBytes, String filename) async {
    if (_currentUser == null) return null;
    try {
      _isLoading = true;
      notifyListeners();
      final url = await CloudinaryService.uploadFileBytes(
        fileBytes: fileBytes,
        fileName: filename,
        resourceType: 'image',
      );
      if (url != null) {
        updateProfile(avatarUrl: url);
      }
      return url;
    } catch (e) {
      debugPrint('Error uploading custom avatar: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  final List<VoidCallback> _logoutListeners = [];
  void addLogoutListener(VoidCallback cb) {
    if (!_logoutListeners.contains(cb)) {
      _logoutListeners.add(cb);
    }
  }

  void logout({
    VoidCallback? onClearChatSession,
    VoidCallback? onClearVaultSession,
    VoidCallback? onClearAiChatSession,
    VoidCallback? onClearLibrarySession,
  }) {
    try {
      FirebaseAuth.instance.signOut();
    } catch (_) {}
    // Clear all provider sessions BEFORE nullifying current user
    onClearChatSession?.call();
    onClearVaultSession?.call();
    onClearAiChatSession?.call();
    onClearLibrarySession?.call();
    for (final cb in _logoutListeners) {
      try {
        cb();
      } catch (_) {}
    }
    _currentUser = null;
    _saveUser();
    notifyListeners();
  }
}
