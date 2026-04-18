class AppEndpoints {
  // Use --dart-define to override these for staging/production builds.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  static const String portalBaseUrl = String.fromEnvironment(
    'PORTAL_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static String apiPath(String path) {
    return '$apiBaseUrl$path';
  }

  static Uri get registerAsRepUri => Uri.parse('$portalBaseUrl/pricing');
}
