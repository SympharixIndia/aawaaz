import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// A failed API call. [statusCode] is 0 for network/connection errors.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON HTTP client over the backend. Returns decoded JSON (Map/List) or
/// throws [ApiException]. Base URL comes from [ApiConfig].
class ApiClient {
  final http.Client _client;
  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query
          .map((k, v) => MapEntry(k, v?.toString()))
        ..removeWhere((_, v) => v == null),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _jsonHeaders));

  Future<dynamic> post(String path, Object body) => _send(
      () => _client.post(_uri(path), headers: _jsonHeaders, body: jsonEncode(body)));

  Future<dynamic> patch(String path, Object body) => _send(
      () => _client.patch(_uri(path), headers: _jsonHeaders, body: jsonEncode(body)));

  Future<dynamic> put(String path, Object body) => _send(
      () => _client.put(_uri(path), headers: _jsonHeaders, body: jsonEncode(body)));

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call();
    } catch (e) {
      throw ApiException(0, 'Cannot reach the server. Check your connection.');
    }
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    throw ApiException(res.statusCode, _errorMessage(body));
  }

  /// Spring returns a ProblemDetail with a `detail` field for ResponseStatusException.
  String _errorMessage(dynamic body) {
    if (body is Map) {
      for (final key in ['detail', 'message', 'error']) {
        if (body[key] != null) return body[key].toString();
      }
    }
    return 'Request failed';
  }
}
