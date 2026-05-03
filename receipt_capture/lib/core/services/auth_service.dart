import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_endpoints.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  String _fingerprint(String value) {
    final codeUnits = value.runes.toList();
    final preview = codeUnits.take(6).join(',');
    return 'len=${codeUnits.length},runes=$preview${codeUnits.length > 6 ? ',...' : ''}';
  }

  String _tailFingerprint(String value) {
    final codeUnits = value.runes.toList();
    final tail = codeUnits.length <= 5 ? codeUnits : codeUnits.sublist(codeUnits.length - 5);
    return 'tail=${tail.join(',')}';
  }

  String _sha256Hex(String value) {
    final digest = sha256.convert(utf8.encode(value));
    return digest.toString();
  }

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
      final normalizedEmail = email.trim();
      final normalizedPassword = password.trim();

      print('[AuthService] API base URL: ${AppEndpoints.apiBaseUrl}');
      final endpoints = [
        AppEndpoints.apiPath('/api/auth/staff/login'),
        AppEndpoints.apiPath('/api/auth/login'),
      ];
      print('[AuthService] Login endpoints: ${endpoints.join(' -> ')}');
      print('[AuthService] Raw email length: ${email.length}, trimmed length: ${normalizedEmail.length}');
      print('[AuthService] Email fingerprint: ${_fingerprint(normalizedEmail)}');
      print('[AuthService] Email tail: ${_tailFingerprint(normalizedEmail)}');
      print('[AuthService] Email sha256: ${_sha256Hex(normalizedEmail)}');
      print('[AuthService] Password length: ${normalizedPassword.length}');
      print('[AuthService] Password fingerprint: ${_fingerprint(normalizedPassword)}');
      print('[AuthService] Password tail: ${_tailFingerprint(normalizedPassword)}');
      print('[AuthService] Password sha256: ${_sha256Hex(normalizedPassword)}');
      if (normalizedEmail != email) {
        print('[AuthService] Email was trimmed before submit');
      }
      if (normalizedPassword != password) {
        print('[AuthService] Password was trimmed before submit');
      }

      final requestBody = jsonEncode({
        'email': normalizedEmail,
        'password': normalizedPassword,
      });

      print('[AuthService] Request headers: {Content-Type: application/json}');
      print('[AuthService] Request body: {"email":"$normalizedEmail","password":"<redacted:${normalizedPassword.length}>"}');
      
      Future<({http.Response response, Map<String, dynamic> payload, String url})> postLogin(String url) async {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: requestBody,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Request timeout - cannot reach backend at $url');
          },
        );

        final bodyText = response.body;
        print('[AuthService] Response from $url status: ${response.statusCode}');
        print('[AuthService] Response from $url headers: ${response.headers}');
        print('[AuthService] Response from $url body: $bodyText');

        Map<String, dynamic> payload = <String, dynamic>{};
        if (bodyText.isNotEmpty) {
          try {
            payload = jsonDecode(bodyText) as Map<String, dynamic>;
            print('[AuthService] Parsed response keys from $url: ${payload.keys.toList()}');
          } catch (parseError) {
            print('[AuthService] Failed to parse response JSON from $url: $parseError');
            return (response: response, payload: <String, dynamic>{}, url: url);
          }
        }

        return (response: response, payload: payload, url: url);
      }

      final firstAttempt = await postLogin(endpoints[0]);

      bool shouldFallback = firstAttempt.response.statusCode == 401 || firstAttempt.response.statusCode == 403;
      if (shouldFallback) {
        print('[AuthService] Staff login rejected, trying general auth endpoint');
      }

      final resultAttempt = shouldFallback ? await postLogin(endpoints[1]) : firstAttempt;
      final response = resultAttempt.response;
      final payload = resultAttempt.payload;
      final activeUrl = resultAttempt.url;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = payload['error']?.toString() ?? 'Invalid email or password';
        print('[AuthService] Login failed with status ${response.statusCode} from $activeUrl: $error');
        return AuthResult(
          success: false,
          error: error,
        );
      }

      final token = payload['token']?.toString();
      final userPayload = payload['user'] as Map<String, dynamic>?;

      if (token == null || token.isEmpty || userPayload == null) {
        print('[AuthService] Missing token or user data in response from $activeUrl');
        return AuthResult(
          success: false,
          error: 'Login response is missing token or user data',
        );
      }

      print('[AuthService] Login successful for ${userPayload['email']} via $activeUrl');
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
      final errorMsg = 'Login failed: ${e.toString()}';
      print('[AuthService] Exception during login: $errorMsg');
      return AuthResult(
        success: false,
        error: errorMsg,
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