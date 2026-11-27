import '../models/api/user_dto.dart';
import 'api_client.dart';

/// Typed access to the Aawaaz backend. Methods return DTOs or throw [ApiException].
/// Grows one endpoint per build step (F2+).
class BackendService {
  final ApiClient _api;
  BackendService([ApiClient? api]) : _api = api ?? ApiClient();

  /// Logs in a manager or worker. Throws [ApiException] (401 on bad credentials).
  Future<UserDto> login(String username, String password) async {
    final json = await _api.post('/api/auth/login', {
      'username': username,
      'password': password,
    });
    return UserDto.fromJson(json as Map<String, dynamic>);
  }

  /// Registers a worker. Throws [ApiException] (409 if the username is taken).
  Future<UserDto> registerWorker({
    required String username,
    required String name,
    required String password,
    String? profession,
    required String languageCode,
  }) async {
    final json = await _api.post('/api/workers', {
      'username': username,
      'name': name,
      'password': password,
      'profession': profession,
      'languageCode': languageCode,
    });
    return UserDto.fromJson(json as Map<String, dynamic>);
  }
}
