import 'package:flutter_test/flutter_test.dart';

import 'package:aawaaz/data/app_repository.dart';

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
}
