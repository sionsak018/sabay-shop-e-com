class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static const String appId = String.fromEnvironment(
    'APP_ID',
    defaultValue: 'sabay_shop_app',
  );

  static const String secretKey = String.fromEnvironment(
    'SECRET_KEY',
    defaultValue: '',
  );

  // Helper to get the base host (without /api) for image storage
  static String get baseHost {
    try {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    } catch (_) {
      return baseUrl.replaceAll('/api', '');
    }
  }
}
