import 'dart:convert';
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

    await Future.delayed(const Duration(milliseconds: 400));

    final uname = (username != null && username.trim().isNotEmpty)
        ? username.trim().toLowerCase()
        : email.split('@').first.toLowerCase();

    _currentUser = UserModel(
      id: 'usr_me_001',
      displayName: email.split('@').first,
      username: uname,
      email: email,
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    await _saveUser();
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

    await Future.delayed(const Duration(milliseconds: 400));

    final uname = (username != null && username.trim().isNotEmpty)
        ? username.trim().toLowerCase()
        : displayName.toLowerCase().replaceAll(' ', '_');

    _currentUser = UserModel(
      id: 'usr_me_${DateTime.now().millisecondsSinceEpoch}',
      displayName: displayName,
      username: uname,
      email: email,
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    await _saveUser();
    notifyListeners();
    return true;
  }

  void updateProfile({String? displayName, String? username, String? avatarUrl}) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      displayName: displayName,
      username: username,
      avatarUrl: avatarUrl,
    );
    _saveUser();
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _saveUser();
    notifyListeners();
  }
}

