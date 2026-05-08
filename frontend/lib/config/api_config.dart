class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  static const String apiPrefix = '/api/v1';
  static const String wsUrl = 'ws://localhost:8000/ws';

  static String get apiUrl => '$baseUrl$apiPrefix';

  static String wsUrlWithToken(String token) => '$wsUrl?token=$token';
}
