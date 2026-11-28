import 'package:flutter_test/flutter_test.dart';

import 'package:aawaaz/services/spoken_number.dart';

void main() {
  group('parseSpokenTicket', () {
    test('ASCII digits', () {
      expect(parseSpokenTicket('247'), 247);
      expect(parseSpokenTicket('  12 '), 12);
    });

    test('strips surrounding words/punctuation around digits', () {
      expect(parseSpokenTicket('ticket 247.'), 247);
      expect(parseSpokenTicket('#5'), 5);
    });

    test('Devanagari numerals', () {
      expect(parseSpokenTicket('२४७'), 247);
    });

    test('Bengali numerals', () {
      expect(parseSpokenTicket('২৪৭'), 247);
    });

    test('English digit words', () {
      expect(parseSpokenTicket('two four seven'), 247);
      expect(parseSpokenTicket('one two'), 12);
    });

    test('Hindi digit words', () {
      expect(parseSpokenTicket('दो चार सात'), 247);
    });

    test('Bengali digit words', () {
      expect(parseSpokenTicket('দুই চার সাত'), 247);
    });

    test('returns null for empty or unparseable', () {
      expect(parseSpokenTicket(''), isNull);
      expect(parseSpokenTicket('hello there'), isNull);
    });
  });
}
