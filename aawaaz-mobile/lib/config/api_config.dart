import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Backend connection settings, read from the bundled `.env` (see §1.1 of SPEC_V3).
/// Falls back to emulator defaults if `.env` isn't loaded (e.g. in widget tests).
class ApiConfig {
  static String _get(String key, String fallback) =>
      dotenv.isInitialized ? (dotenv.maybeGet(key) ?? fallback) : fallback;

  static String get scheme => _get('API_SCHEME', 'http');
  static String get host => _get('API_HOST', '10.0.2.2');
  static String get port => _get('API_PORT', '8080');

  static String get baseUrl => '$scheme://$host:$port';
}
