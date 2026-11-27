import 'package:flutter_test/flutter_test.dart';

import 'package:aawaaz/models/category.dart';
import 'package:aawaaz/models/query.dart';
import 'package:aawaaz/models/api/category_dto.dart';
import 'package:aawaaz/models/api/request_dto.dart';
import 'package:aawaaz/models/api/user_dto.dart';

void main() {
  test('UserDto parses and detects manager', () {
    final u = UserDto.fromJson({
      'id': 1,
      'username': 'admin',
      'name': 'Manager',
      'userType': 'MANAGER',
      'profession': null,
      'languageCode': 'en-IN',
    });
    expect(u.id, 1);
    expect(u.isManager, isTrue);
    expect(u.profession, isNull);
  });

  test('RequestDto parses enums, nullable translation and ISO timestamps', () {
    final r = RequestDto.fromJson({
      'id': 42,
      'workerId': 7,
      'originalText': 'chhutti chahiye',
      'originalLanguage': 'hi-IN',
      'translatedText': 'need leave',
      'translatedLanguage': 'en-IN',
      'categoryKey': 'leave',
      'urgency': 'HIGH',
      'status': 'IN_PROGRESS',
      'managerComment': null,
      'managerCommentLanguage': null,
      'commentedAt': null,
      'createdAt': '2026-11-28T09:30:00Z',
      'updatedAt': null,
    });
    expect(r.id, 42);
    expect(r.urgency, Urgency.high);
    expect(r.status, QueryStatus.inProgress);
    expect(r.managerComment, isNull);
    expect(r.createdAt?.toUtc().hour, 9);
  });

  test('RequestDto defaults unknown enum values sensibly', () {
    final r = RequestDto.fromJson({
      'id': 1,
      'workerId': 1,
      'originalText': 'x',
      'originalLanguage': 'en-IN',
      'categoryKey': 'other',
      'urgency': 'WHATEVER',
      'status': 'WHATEVER',
    });
    expect(r.urgency, Urgency.normal);
    expect(r.status, QueryStatus.open);
  });

  test('CategoryDto parses', () {
    final c = CategoryDto.fromJson({
      'categoryKey': 'safety',
      'label': 'Safety',
      'priority': 100,
      'safetyCritical': true,
    });
    expect(c.categoryKey, 'safety');
    expect(c.priority, 100);
    expect(c.safetyCritical, isTrue);
  });
}
