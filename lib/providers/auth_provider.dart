import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  static const String _prefUserKey = 'miralo_auth_user_v2';

  UserModel? _currentUser = UserModel(
    id: 'usr_me_001',
    displayName: 'Alex Morgan',
    username: 'alexm',
    email: 'alex.morgan@miralo.ai',
    avatarUrl: null,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  bool get isSpecialUser {
    if (_currentUser == null) return false;
    final u = _currentUser!.username.toLowerCase().trim();
    return u == 'aarushlohit' || u == 'ashlinmirsha';
  }

  AuthProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefUserKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
        return;
      } catch (_) {}
    }
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
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user?.uid ?? 'usr_me_001';
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
    } catch (e) {
      debugPrint('FirebaseAuth login error (falling back to offline local profile): $e');
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
    notifyListeners();

    final uname = (username != null && username.trim().isNotEmpty)
        ? username.trim().toLowerCase()
        : displayName.toLowerCase().replaceAll(' ', '_');

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user?.uid ?? 'usr_me_${DateTime.now().millisecondsSinceEpoch}';
      await credential.user?.updateDisplayName(displayName);

      _currentUser = UserModel(
        id: uid,
        displayName: displayName,
        username: uname,
        email: email.trim(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('FirebaseAuth signup error (falling back to offline local profile): $e');
      _currentUser = UserModel(
        id: 'usr_${uname}_${DateTime.now().millisecondsSinceEpoch}',
        displayName: displayName,
        username: uname,
        email: email.trim(),
        createdAt: DateTime.now(),
      );
    }

    _isLoading = false;
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
      // Also write username index for fast add friend search
      FirebaseDatabase.instance
          .ref('user_index/${_currentUser!.username}')
          .set(_currentUser!.toJson());
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

