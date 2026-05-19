import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(
    this._authService,
    this._sharedPreferences,
    this._apiClient,
  );

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final AuthService _authService;
  final SharedPreferences _sharedPreferences;
  final ApiClient _apiClient;

  User? _user;
  String? _token;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  User? get user => _user;
  String get displayName => _user?.fullName ?? 'Cliente invitado';

  Future<void> restoreSession() async {
    _token = _sharedPreferences.getString(_tokenKey);
    final userJson = _sharedPreferences.getString(_userKey);
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }

    if (_token != null) {
      _apiClient.setToken(_token);
      if (_user == null) {
        await _refreshProfile();
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final loginResult = await _authService.login(email, password);
      _applyAuthPayload(loginResult);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final registerResult = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
      );
      _applyAuthPayload(registerResult);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _apiClient.setToken(null);
    await _sharedPreferences.remove(_tokenKey);
    await _sharedPreferences.remove(_userKey);
    notifyListeners();
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    _setLoading(true);
    try {
      return await _authService.requestPasswordReset(email);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email, token, newPassword);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    _setLoading(true);
    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
      );
      _user = updatedUser;
      await _saveUser();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _refreshProfile() async {
    try {
      _user = await _authService.fetchProfile();
      await _saveUser();
    } catch (_) {
      _token = null;
      await logout();
    }
  }

  void _applyAuthPayload(Map<String, dynamic> payload) {
    final token = payload['token'] as String?;
    final userData = payload['user'];
    if (token == null || userData is! Map<String, dynamic>) {
      throw StateError('Respuesta de autenticacion invalida.');
    }

    _token = token;
    _user = User.fromJson(userData);
    _apiClient.setToken(token);
    _sharedPreferences.setString(_tokenKey, token);
    _saveUser();
    notifyListeners();
  }

  Future<void> _saveUser() async {
    if (_user != null) {
      await _sharedPreferences.setString(_userKey, jsonEncode(_user!.toJson()));
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
