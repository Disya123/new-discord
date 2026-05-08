import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String apiPrefix = '/api/v1';

  static String get apiUrl {
    if (kIsWeb) {
      // Web: nginx proxies /api/ to backend, use relative path
      return apiPrefix;
    }
    // Mobile/Desktop: direct backend connection
    return 'http://localhost:8000$apiPrefix';
  }

  static String get wsUrl {
    if (kIsWeb) {
      // Web: derive from current page location
      return _webWsUrl;
    }
    return 'ws://localhost:8000/ws';
  }

  static String get _webWsUrl {
    try {
      final uri = Uri.base;
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/ws';
    } catch (_) {
      return 'ws://localhost:8080/ws';
    }
  }

  static String wsUrlWithToken(String token) => '$wsUrl?token=$token';
}
