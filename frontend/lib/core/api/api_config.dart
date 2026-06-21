class ApiConfig {
  // Use --dart-define=BASE_URL=... during build/run
  // Default to localhost for development
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.29.27:8000',
  );

  static String get uploadsUrl => '$baseUrl/uploads';
}
