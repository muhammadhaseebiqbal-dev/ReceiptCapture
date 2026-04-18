class AppEndpoints {
  // Use --dart-define to override these for staging/production builds.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://receipt-capture-4xda.vercel.app',
  );

  static const String portalBaseUrl = String.fromEnvironment(
    'PORTAL_BASE_URL',
    defaultValue: 'https://receipt-capture-nine.vercel.app',
  );

  static String apiPath(String path) {
    return '$apiBaseUrl$path';
  }

  static Uri get registerAsRepUri => Uri.parse('$portalBaseUrl/pricing');
}
