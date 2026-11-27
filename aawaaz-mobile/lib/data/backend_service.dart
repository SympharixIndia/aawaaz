import '../models/category.dart';
import '../models/query.dart';
import '../models/api/api_parse.dart';
import '../models/api/category_dto.dart';
import '../models/api/request_dto.dart';
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

  /// Files a request. Returns the created request (its `id` is the ticket number).
  Future<RequestDto> createRequest({
    required int workerId,
    required String originalText,
    required String originalLanguage,
    required String categoryKey,
    required Urgency urgency,
  }) async {
    final json = await _api.post('/api/requests', {
      'workerId': workerId,
      'originalText': originalText,
      'originalLanguage': originalLanguage,
      'categoryKey': categoryKey,
      'urgency': ApiParse.urgencyToApi(urgency),
    });
    return RequestDto.fromJson(json as Map<String, dynamic>);
  }

  /// Manager listing: optional day/status/category filters; backend returns it
  /// sorted by category priority then newest first.
  Future<List<RequestDto>> listRequests({
    DateTime? date,
    String? status,
    String? categoryKey,
  }) async {
    final query = <String, dynamic>{};
    if (date != null) query['date'] = _ymd(date);
    if (status != null) query['status'] = status;
    if (categoryKey != null) query['categoryKey'] = categoryKey;
    final json = await _api.get('/api/requests', query: query);
    return (json as List)
        .map((e) => RequestDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A worker's own requests, newest first.
  Future<List<RequestDto>> requestsForWorker(int workerId) async {
    final json = await _api.get('/api/requests', query: {'workerId': workerId});
    return (json as List)
        .map((e) => RequestDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// One request by ticket number (worker status lookup). 404 if absent.
  Future<RequestDto> requestByTicket(int id) async {
    final json = await _api.get('/api/requests/$id');
    return RequestDto.fromJson(json as Map<String, dynamic>);
  }

  /// Manager update: status and/or comment (comment language defaults server-side).
  Future<RequestDto> updateRequest(
    int id, {
    QueryStatus? status,
    String? managerComment,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = ApiParse.statusToApi(status);
    if (managerComment != null) body['managerComment'] = managerComment;
    final json = await _api.patch('/api/requests/$id', body);
    return RequestDto.fromJson(json as Map<String, dynamic>);
  }

  Future<List<CategoryDto>> listCategories() async {
    final json = await _api.get('/api/categories');
    return (json as List)
        .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryDto> setCategoryPriority(String key, int priority) async {
    final json = await _api.put('/api/categories/$key/priority', {'priority': priority});
    return CategoryDto.fromJson(json as Map<String, dynamic>);
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

