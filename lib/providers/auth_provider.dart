import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initUser();
  }

  void _initUser() {
    // Default logged in user for realistic smooth frontend experience
    _currentUser = UserModel(
      id: 'usr_me_001',
      displayName: 'Alex Morgan',
      username: 'alexm',
      email: 'alex.morgan@miralo.ai',
      avatarUrl: null,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _currentUser = UserModel(
      id: 'usr_me_001',
      displayName: email.split('@').first,
      username: email.split('@').first.toLowerCase(),
      email: email,
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> signup(String displayName, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _currentUser = UserModel(
      id: 'usr_me_${DateTime.now().millisecondsSinceEpoch}',
      displayName: displayName,
      username: displayName.toLowerCase().replaceAll(' ', '_'),
      email: email,
      createdAt: DateTime.now(),
    );

    _isLoading = false;
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
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
