import 'package:flutter/foundation.dart';

class AppEndpoints {
  // Use --dart-define to override these for staging/production builds.
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://receipt-capture-4xda.vercel.app',
  );

  static const String portalBaseUrl = String.fromEnvironment(
    'PORTAL_BASE_URL',
    defaultValue: 'https://receipt-capture-nine.vercel.app',
  );

  static String get apiBaseUrl {
    // Android emulators cannot reach host machine with localhost.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _apiBaseUrlFromEnv
          .replaceAll('://localhost', '://10.0.2.2')
          .replaceAll('://127.0.0.1', '://10.0.2.2');
    }
    return _apiBaseUrlFromEnv;
  }

  static String apiPath(String path) {
    return '${apiBaseUrl}$path';
  }

  static Uri get registerAsRepUri => Uri.parse('$portalBaseUrl/pricing');
}
