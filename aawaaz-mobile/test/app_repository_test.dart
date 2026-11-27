import 'package:flutter_test/flutter_test.dart';

import 'package:aawaaz/data/app_repository.dart';
import 'package:aawaaz/models/query.dart';

void main() {
  group('AppRepository worker registration & auth', () {
    late AppRepository repo;

    setUp(() => repo = AppRepository());

    test('registers a worker and authenticates with correct credentials', () {
      final worker = repo.registerWorker(
        username: 'ramesh',
        name: 'Ramesh',
        password: '1234',
        languageCode: 'hi-IN',
      );
      expect(worker, isNotNull);
      expect(repo.workers, hasLength(1));

      final auth = repo.authenticateWorker('ramesh', '1234');
      expect(auth?.id, worker!.id);
    });

    test('rejects duplicate usernames (case-insensitive)', () {
      repo.registerWorker(
        username: 'ramesh',
        name: 'Ramesh',
        password: '1234',
        languageCode: 'hi-IN',
      );
      final dup = repo.registerWorker(
        username: 'RAMESH',
        name: 'Other',
        password: '5678',
        languageCode: 'en-IN',
      );
      expect(dup, isNull);
      expect(repo.workers, hasLength(1));
    });

    test('fails authentication with wrong PIN', () {
      repo.registerWorker(
        username: 'ramesh',
        name: 'Ramesh',
        password: '1234',
        languageCode: 'hi-IN',
      );
      expect(repo.authenticateWorker('ramesh', '0000'), isNull);
    });

    test('seeds categories with safety highest priority', () {
      expect(repo.categories, isNotEmpty);
      final top = repo.queriesByPriority; // no queries yet
      expect(top, isEmpty);
      expect(repo.categoryByKey('safety').priority,
          greaterThan(repo.categoryByKey('other').priority));
    });
  });

  group('AppRepository dashboard behaviors', () {
    late AppRepository repo;
    setUp(() => repo = AppRepository());

    test('seedDemoData populates workers and queries, once', () {
      repo.seedDemoData();
      final workerCount = repo.workers.length;
      final queryCount = repo.queriesByPriority.length;
      expect(workerCount, greaterThan(0));
      expect(queryCount, greaterThan(0));

      repo.seedDemoData(); // second call is a no-op
      expect(repo.workers, hasLength(workerCount));
      expect(repo.queriesByPriority, hasLength(queryCount));
    });

    test('queriesByPriority puts safety above a lower category', () {
      repo.seedDemoData();
      final ordered = repo.queriesByPriority;
      final safetyIndex =
          ordered.indexWhere((q) => q.categoryKey == 'safety');
      final leaveIndex = ordered.indexWhere((q) => q.categoryKey == 'leave');
      expect(safetyIndex, lessThan(leaveIndex));
    });

    test('addManagerComment stores comment and advances status', () {
      final w = repo.registerWorker(
          username: 'a', name: 'A', password: '1234', languageCode: 'en-IN')!;
      final q = repo.addQuery(
        workerId: w.id,
        transcript: 'need leave',
        languageCode: 'en-IN',
        categoryKey: 'leave',
      );
      repo.addManagerComment(q.id, 'Approved for tomorrow',
          status: QueryStatus.resolved);
      final updated = repo.queriesForWorker(w.id).first;
      expect(updated.managerComment, 'Approved for tomorrow');
      expect(updated.status, QueryStatus.resolved);
    });

    test('setCategoryPriority re-sorts the dashboard', () {
      final w = repo.registerWorker(
          username: 'a', name: 'A', password: '1234', languageCode: 'en-IN')!;
      repo.addQuery(
          workerId: w.id,
          transcript: 'x',
          languageCode: 'en-IN',
          categoryKey: 'other');
      repo.addQuery(
          workerId: w.id,
          transcript: 'y',
          languageCode: 'en-IN',
          categoryKey: 'leave');
      // Boost "other" above "leave".
      repo.setCategoryPriority('other', 99);
      expect(repo.queriesByPriority.first.categoryKey, 'other');
    });
  });
}
