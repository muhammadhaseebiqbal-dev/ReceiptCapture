import 'package:equatable/equatable.dart';
import '../../../core/models/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthInitialize extends AuthEvent {}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  const AuthLogin({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

// Note: User registration is handled by admin through web portal

class AuthLogout extends AuthEvent {}

class AuthChangePassword extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const AuthChangePassword({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}

class AuthResetPassword extends AuthEvent {
  final String email;

  const AuthResetPassword({required this.email});

  @override
  List<Object> get props => [email];
}