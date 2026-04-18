import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_endpoints.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  final StreamController<User?> _userController = StreamController<User?>.broadcast();
  Stream<User?> get userStream => _userController.stream;

  User? _currentUser;
  String? _currentToken;
  User? get currentUser => _currentUser;
  String? get currentToken => _currentToken;

  bool get isLoggedIn => _currentUser != null;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final token = prefs.getString(_tokenKey);
    
    if (isLoggedIn && token != null && token.isNotEmpty) {
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        try {
          final userData = jsonDecode(userJson);
          _currentUser = User.fromJson(userData);
          _currentToken = token;
          _userController.add(_currentUser);
        } catch (e) {
          // Invalid stored user data, clear it
          await logout();
        }
      } else {
        await logout();
      }
    } else if (isLoggedIn) {
      await logout();
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppEndpoints.apiPath('/api/auth/staff/login')),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final bodyText = response.body;
      final Map<String, dynamic> payload = bodyText.isNotEmpty
          ? (jsonDecode(bodyText) as Map<String, dynamic>)
          : <String, dynamic>{};

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AuthResult(
          success: false,
          error: payload['error']?.toString() ?? 'Invalid email or password',
        );
      }

      final token = payload['token']?.toString();
      final userPayload = payload['user'] as Map<String, dynamic>?;

      if (token == null || token.isEmpty || userPayload == null) {
        return AuthResult(
          success: false,
          error: 'Login response is missing token or user data',
        );
      }

      _currentUser = _mapBackendUser(userPayload);
      _currentToken = token;

      // Store in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      await prefs.setBool(_isLoggedInKey, true);

      _userController.add(_currentUser);

      return AuthResult(
        success: true,
        user: _currentUser,
        token: token,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Note: User registration is handled by admin through web portal

  Future<String?> getStoredToken() async {
    if (_currentToken != null && _currentToken!.isNotEmpty) {
      return _currentToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    _currentToken = token;
    return token;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.setBool(_isLoggedInKey, false);

      _currentUser = null;
      _currentToken = null;
      _userController.add(null);
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<AuthResult> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_currentUser == null) {
        return AuthResult(
          success: false,
          error: 'User not logged in',
        );
      }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real app, verify current password with backend
      // For now, just simulate success
      return AuthResult(
        success: true,
        message: 'Password changed successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to change password: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Simulate sending reset email
      return AuthResult(
        success: true,
        message: 'Please contact your manager to reset your password',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to send reset email: ${e.toString()}',
      );
    }
  }

  User _mapBackendUser(Map<String, dynamic> userPayload) {
    final companyId = userPayload['companyId']?.toString();
    return User.fromJson({
      'id': userPayload['id']?.toString() ?? '',
      'email': userPayload['email']?.toString() ?? '',
      'name': userPayload['name']?.toString() ?? '',
      'role': userPayload['role']?.toString() ?? 'employee',
      'organization': companyId == null || companyId.isEmpty
          ? 'Company'
          : 'Company $companyId',
      'isActive': userPayload['isActive'] ?? true,
    });
  }

  void dispose() {
    _userController.close();
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? error;
  final String? message;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.error,
    this.message,
  });
}