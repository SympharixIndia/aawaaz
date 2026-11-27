import 'package:flutter_test/flutter_test.dart';

import 'package:aawaaz/models/category.dart';
import 'package:aawaaz/services/categorizer.dart';

void main() {
  group('Categorizer', () {
    test('detects safety as high urgency (English)', () {
      final r = Categorizer.categorize('There is a fire near the machine');
      expect(r.categoryKey, 'safety');
      expect(r.urgency, Urgency.high);
    });

    test('detects health (Hindi)', () {
      final r = Categorizer.categorize('Tabiyat theek nahi hai');
      expect(r.categoryKey, 'health');
      expect(r.urgency, Urgency.high);
    });

    test('prefers early_exit over leave when both could match', () {
      final r = Categorizer.categorize('I need to leave early today');
      expect(r.categoryKey, 'early_exit');
    });

    test('detects plain leave', () {
      final r = Categorizer.categorize('I want a holiday tomorrow');
      expect(r.categoryKey, 'leave');
    });

    test('detects advance (Bengali)', () {
      final r = Categorizer.categorize('Ei soptahe ekta advance lagbe');
      expect(r.categoryKey, 'advance');
    });

    test('falls back to other with normal urgency', () {
      final r = Categorizer.categorize('Just saying hello');
      expect(r.categoryKey, 'other');
      expect(r.urgency, Urgency.normal);
    });
  });
}
