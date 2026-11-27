import '../models/category.dart';

/// Result of categorizing a spoken transcript.
class CategorizationResult {
  final String categoryKey;
  final Urgency urgency;
  const CategorizationResult(this.categoryKey, this.urgency);
}

/// Rule-based, on-device query categorization for V1 (no LLM / backend).
///
/// Deliberately crude keyword matching across hi/bn/en. This is the obvious
/// upgrade point for V2 — swap [categorize] for an LLM call without touching
/// the rest of the app.
class Categorizer {
  /// Checked in order; "leave early" must win over plain "leave", and
  /// safety/health are checked first so they take precedence.
  static const List<MapEntry<String, List<String>>> _rules = [
    MapEntry('safety', [
      'danger', 'accident', 'fire', 'spark', 'unsafe', 'injury', 'injured',
      'खतरा', 'आग', 'दुर्घटना', 'चोट', 'असुरक्षित',
      'বিপদ', 'আগুন', 'দুর্ঘটনা', 'আঘাত', 'অনিরাপদ',
    ]),
    MapEntry('health', [
      'sick', 'unwell', 'ill', 'not feeling well', 'pain', 'fever', 'doctor',
      'tabiyat', 'tabeeyat', 'bimar', 'bimaar', 'bukhar', 'dard', 'doctor',
      'asusth', 'jor', 'shorir',
      'तबियत', 'तबीयत', 'बीमार', 'बुखार', 'दर्द', 'डॉक्टर',
      'অসুস্থ', 'জ্বর', 'ব্যথা', 'শরীর', 'ডাক্তার',
    ]),
    MapEntry('early_exit', [
      'leave early', 'go early', 'early', 'jaldi jaana', 'jaldi',
      'जल्दी जाना', 'जल्दी', 'जल्द',
      'তাড়াতাড়ি', 'আগে চলে', 'তাড়াতাড়ি যাব',
    ]),
    MapEntry('leave', [
      'leave', 'holiday', 'day off', 'absent', 'chhutti', 'chutti',
      'छुट्टी', 'अवकाश',
      'ছুটি', 'অনুপস্থিত',
    ]),
    MapEntry('advance', [
      'advance', 'salary', 'loan', 'paisa', 'paise', 'money',
      'एडवांस', 'तनख्वाह', 'पैसा', 'पैसे', 'उधार',
      'অগ্রিম', 'বেতন', 'টাকা', 'ধার',
    ]),
  ];

  /// Categorizes [transcript]. Falls back to `other` with normal urgency.
  static CategorizationResult categorize(String transcript) {
    final text = transcript.toLowerCase();
    for (final rule in _rules) {
      for (final keyword in rule.value) {
        if (text.contains(keyword.toLowerCase())) {
          return CategorizationResult(rule.key, _urgencyFor(rule.key));
        }
      }
    }
    return const CategorizationResult('other', Urgency.normal);
  }

  static Urgency _urgencyFor(String key) =>
      (key == 'safety' || key == 'health') ? Urgency.high : Urgency.normal;
}
