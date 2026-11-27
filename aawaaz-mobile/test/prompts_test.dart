import 'package:flutter_test/flutter_test.dart';

import 'package:aawaaz/l10n/prompts.dart';

void main() {
  group('Prompts', () {
    test('falls back to English for an unknown language', () {
      expect(Prompts.forLanguage('xx-XX').yes, Prompts.forLanguage('en-IN').yes);
    });

    test('statusSpeech reads the manager comment when present', () {
      final p = Prompts.forLanguage('en-IN');
      expect(p.statusSpeech('Approved for tomorrow'), 'Approved for tomorrow');
    });

    test('statusSpeech reads the pending message when there is no comment', () {
      final p = Prompts.forLanguage('en-IN');
      expect(p.statusSpeech(null), p.pending);
      expect(p.statusSpeech('   '), p.pending);
    });

    test('each supported language provides its own pending string', () {
      expect(Prompts.forLanguage('hi-IN').pending,
          isNot(Prompts.forLanguage('en-IN').pending));
      expect(Prompts.forLanguage('bn-IN').pending,
          isNot(Prompts.forLanguage('en-IN').pending));
    });
  });
}
