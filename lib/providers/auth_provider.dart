import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

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

  Future<bool> login(String email, String password, {String? username}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
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
            : email.split('@').first.toLowerCase();

        _currentUser = UserModel(
          id: uid,
          displayName: credential.user?.displayName ?? email.split('@').first,
          username: uname,
          email: email.trim(),
          avatarUrl: credential.user?.photoURL,
          createdAt: DateTime.now(),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException login: ${e.code} - ${e.message}');
      _isLoading = false;
      if (e.code == 'user-not-found') {
        _errorMessage = 'No user account found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Please enter a valid email address.';
      } else if (e.code == 'user-disabled') {
        _errorMessage = 'This account has been disabled.';
      } else {
        _errorMessage = e.message ?? 'Login failed. Please check your credentials.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      if (e.toString().contains('no-app')) {
        // In local test environments without Firebase native app initialization
        final uname = (username != null && username.trim().isNotEmpty)
            ? username.trim().toLowerCase()
            : email.split('@').first.toLowerCase();

        _currentUser = UserModel(
          id: 'usr_${email.split('@').first}',
          displayName: email.split('@').first,
          username: uname,
          email: email.trim(),
          createdAt: DateTime.now(),
        );
      } else {
        debugPrint('Login exception: $e');
        _isLoading = false;
        _errorMessage = 'Login failed. Please check your network connection.';
        notifyListeners();
        return false;
      }
    }

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

  void updateProfile({String? displayName, String? username, String? avatarUrl}) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      displayName: displayName,
      username: username,
      avatarUrl: avatarUrl,
    );
    _saveUser();
    _syncUserToFirebase();
    notifyListeners();
  }

  void logout() {
    try {
      FirebaseAuth.instance.signOut();
    } catch (_) {}
    _currentUser = null;
    _saveUser();
    notifyListeners();
  }
}

