import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AuthInitialize>(_onInitialize);
    on<AuthLogin>(_onLogin);
    on<AuthLogout>(_onLogout);
    on<AuthChangePassword>(_onChangePassword);
    on<AuthResetPassword>(_onResetPassword);
  }

  Future<void> _onInitialize(AuthInitialize event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      
      await _authService.initialize();
      
      if (_authService.isLoggedIn && _authService.currentUser != null) {
        emit(AuthAuthenticated(
          user: _authService.currentUser!,
          token: 'mock_token', // In real app, get from secure storage
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to initialize auth: ${e.toString()}'));
    }
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      
      final result = await _authService.login(event.email, event.password);
      
      if (result.success && result.user != null && result.token != null) {
        emit(AuthAuthenticated(
          user: result.user!,
          token: result.token!,
        ));
      } else {
        emit(AuthError(message: result.error ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: 'Login failed: ${e.toString()}'));
    }
  }

  // Note: User registration is handled by admin through web portal

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      await _authService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _onChangePassword(AuthChangePassword event, Emitter<AuthState> emit) async {
    try {
      if (state is! AuthAuthenticated) {
        emit(const AuthError(message: 'User not authenticated'));
        return;
      }

      final currentState = state as AuthAuthenticated;
      emit(AuthLoading());
      
      final result = await _authService.changePassword(
        event.currentPassword,
        event.newPassword,
      );
      
      if (result.success) {
        emit(currentState); // Return to authenticated state
        emit(AuthSuccess(message: result.message ?? 'Password changed successfully'));
      } else {
        emit(currentState); // Return to authenticated state
        emit(AuthError(message: result.error ?? 'Failed to change password'));
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to change password: ${e.toString()}'));
    }
  }

  Future<void> _onResetPassword(AuthResetPassword event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      
      final result = await _authService.resetPassword(event.email);
      
      if (result.success) {
        emit(AuthUnauthenticated());
        emit(AuthSuccess(message: result.message ?? 'Reset instructions sent'));
      } else {
        emit(AuthUnauthenticated());
        emit(AuthError(message: result.error ?? 'Failed to send reset email'));
      }
    } catch (e) {
      emit(AuthError(message: 'Reset failed: ${e.toString()}'));
    }
  }
}