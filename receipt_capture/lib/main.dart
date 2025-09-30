import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/camera_service.dart';
import 'core/services/auth_service.dart';
import 'features/receipt/bloc/receipt_bloc.dart';
import 'features/receipt/bloc/receipt_event.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/theme/bloc/theme_bloc.dart';
import 'features/theme/bloc/theme_event.dart';
import 'features/theme/bloc/theme_state.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cameras
  await CameraService.instance.initializeCameras();

  runApp(const ReceiptCaptureApp());
}

class ReceiptCaptureApp extends StatelessWidget {
  const ReceiptCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(ThemeInitialize()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authService: AuthService())..add(AuthInitialize()),
        ),
        BlocProvider<ReceiptBloc>(
          create: (context) => ReceiptBloc()..add(const LoadReceipts()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Receipt Capture',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is AuthAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
