import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/query.dart';
import '../models/worker.dart';

/// Single in-memory source of truth for V1 (no backend, no persistence).
///
/// All UI reads from and writes through this repository. When V2 adds a backend
/// or local storage, only this class changes — the screens stay the same.
class AppRepository extends ChangeNotifier {
  final _uuid = const Uuid();

  final List<Worker> _workers = [];
  final List<Query> _queries = [];
  final List<Category> _categories = defaultCategories();

  int _nextTicket = 101;

  AppRepository();

  // --- Read ---

  List<Worker> get workers => List.unmodifiable(_workers);
  List<Category> get categories => List.unmodifiable(_categories);

  Category categoryByKey(String key) =>
      _categories.firstWhere((c) => c.key == key, orElse: () => _categories.last);

  /// All queries, highest category priority first, then newest first.
  List<Query> get queriesByPriority {
    final list = [..._queries];
    list.sort((a, b) {
      final pa = categoryByKey(a.categoryKey).priority;
      final pb = categoryByKey(b.categoryKey).priority;
      if (pa != pb) return pb.compareTo(pa);
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  /// A single worker's queries, newest first.
  List<Query> queriesForWorker(String workerId) {
    final list = _queries.where((q) => q.workerId == workerId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // --- Workers ---

  bool usernameExists(String username) =>
      _workers.any((w) => w.username.toLowerCase() == username.toLowerCase());

  /// Registers a worker. Returns the new worker, or null if the username is taken.
  Worker? registerWorker({
    required String username,
    required String name,
    required String password,
    required String languageCode,
  }) {
    if (usernameExists(username)) return null;
    final worker = Worker(
      id: _uuid.v4(),
      username: username.trim(),
      name: name.trim(),
      password: password.trim(),
      languageCode: languageCode,
      registeredAt: DateTime.now(),
    );
    _workers.add(worker);
    notifyListeners();
    return worker;
  }

  /// Returns the matching worker, or null if credentials don't match.
  Worker? authenticateWorker(String username, String password) {
    for (final w in _workers) {
      if (w.username.toLowerCase() == username.trim().toLowerCase() &&
          w.password == password.trim()) {
        return w;
      }
    }
    return null;
  }

  // --- Queries ---

  Query addQuery({
    required String workerId,
    required String transcript,
    required String languageCode,
    required String categoryKey,
    Urgency urgency = Urgency.normal,
  }) {
    final query = Query(
      id: _uuid.v4(),
      ticketNo: _nextTicket++,
      workerId: workerId,
      createdAt: DateTime.now(),
      transcript: transcript,
      languageCode: languageCode,
      categoryKey: categoryKey,
      urgency: urgency,
    );
    _queries.add(query);
    notifyListeners();
    return query;
  }

  void addManagerComment(String queryId, String comment, {QueryStatus? status}) {
    final q = _queries.firstWhere((q) => q.id == queryId);
    q.managerComment = comment.trim();
    q.commentedAt = DateTime.now();
    if (status != null) q.status = status;
    notifyListeners();
  }

  // --- Categories ---

  void setCategoryPriority(String key, int priority) {
    categoryByKey(key).priority = priority;
    notifyListeners();
  }
}
