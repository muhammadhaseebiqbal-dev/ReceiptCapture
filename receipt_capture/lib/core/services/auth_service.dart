import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Hardcoded users for development (normally managed through web portal)
  static const List<Map<String, dynamic>> _hardcodedUsers = [
    {
      'id': '1',
      'email': 'user@company.com',
      'password': 'user123',
      'name': 'John Doe',
      'role': 'employee',
      'organization': 'Acme Corporation',
      'isActive': true,
    },
    {
      'id': '2',
      'email': 'manager@company.com',
      'password': 'manager123',
      'name': 'Jane Smith',
      'role': 'manager',
      'organization': 'Acme Corporation',
      'isActive': true,
    },
    {
      'id': '3',
      'email': 'employee1@techcorp.com',
      'password': 'emp123',
      'name': 'Mike Johnson',
      'role': 'employee',
      'organization': 'Tech Corp',
      'isActive': true,
    },
    {
      'id': '4',
      'email': 'manager2@techcorp.com',
      'password': 'mgr123',
      'name': 'Sarah Wilson',
      'role': 'manager',
      'organization': 'Tech Corp',
      'isActive': true,
    },
    {
      'id': '5',
      'email': 'inactive@company.com',
      'password': 'test123',
      'name': 'Inactive User',
      'role': 'employee',
      'organization': 'Test Company',
      'isActive': false,
    },
  ];

  final StreamController<User?> _userController = StreamController<User?>.broadcast();
  Stream<User?> get userStream => _userController.stream;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (isLoggedIn) {
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        try {
          final userData = jsonDecode(userJson);
          _currentUser = User.fromJson(userData);
          _userController.add(_currentUser);
        } catch (e) {
          // Invalid stored user data, clear it
          await logout();
        }
      }
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Find user in hardcoded list
      final userMap = _hardcodedUsers.firstWhere(
        (user) => user['email'] == email && user['password'] == password,
        orElse: () => {},
      );

      if (userMap.isEmpty) {
        return AuthResult(
          success: false,
          error: 'Invalid email or password',
        );
      }

      if (!userMap['isActive']) {
        return AuthResult(
          success: false,
          error: 'Account is deactivated. Please contact your manager.',
        );
      }

      // Create user object
      _currentUser = User.fromJson(userMap);

      // Generate mock JWT token
      final token = _generateMockToken(_currentUser!);

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

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.setBool(_isLoggedInKey, false);

      _currentUser = null;
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

      // Check if user exists
      final userExists = _hardcodedUsers.any((user) => user['email'] == email);
      if (!userExists) {
        return AuthResult(
          success: false,
          error: 'No account found with this email address',
        );
      }

      // Simulate sending reset email
      return AuthResult(
        success: true,
        message: 'Password reset instructions sent to your email',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to send reset email: ${e.toString()}',
      );
    }
  }

  String _generateMockToken(User user) {
    // Generate a mock JWT token (in real app, this comes from backend)
    final header = base64Encode(utf8.encode(jsonEncode({'typ': 'JWT', 'alg': 'HS256'})));
    final payload = base64Encode(utf8.encode(jsonEncode({
      'sub': user.id,
      'email': user.email,
      'role': user.role,
      'exp': DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    })));
    final signature = base64Encode(utf8.encode('mock_signature_${user.id}'));
    
    return '$header.$payload.$signature';
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