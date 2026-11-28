/// Turns a spoken/typed ticket number into an integer.
///
/// Handles what Android STT tends to return across hi-IN / bn-IN / en-IN:
///  - ASCII digits ("247")
///  - Indic numerals (Devanagari "२४७", Bengali "২৪৭")
///  - digit-by-digit number words ("two four seven", "दो चार सात", "দুই চার সাত")
///
/// Returns null if nothing usable is found (caller falls back to manual entry).
int? parseSpokenTicket(String input) {
  if (input.trim().isEmpty) return null;

  // 1) Map any Indic numerals to ASCII, keep other chars as-is.
  final mapped = StringBuffer();
  for (final rune in input.runes) {
    mapped.write(_indicDigit(rune) ?? String.fromCharCode(rune));
  }
  final text = mapped.toString();

  // 2) If there are digits now, use them.
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isNotEmpty) return int.tryParse(digits);

  // 3) Otherwise try digit-by-digit number words.
  final tokens = text.toLowerCase().split(RegExp(r'[\s,.\-/]+'))
    ..removeWhere((t) => t.isEmpty);
  if (tokens.isEmpty) return null;
  final buf = StringBuffer();
  for (final t in tokens) {
    final d = _wordDigits[t];
    if (d == null) return null; // an unknown word → give up, use manual entry
    buf.write(d);
  }
  return buf.isEmpty ? null : int.tryParse(buf.toString());
}

/// Devanagari (०–९) and Bengali (০–৯) digit code points → '0'..'9'.
String? _indicDigit(int rune) {
  if (rune >= 0x0966 && rune <= 0x096F) return '${rune - 0x0966}'; // Devanagari
  if (rune >= 0x09E6 && rune <= 0x09EF) return '${rune - 0x09E6}'; // Bengali
  return null;
}

const Map<String, String> _wordDigits = {
  // English
  'zero': '0', 'oh': '0', 'o': '0',
  'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5',
  'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
  // Hindi (Devanagari)
  'शून्य': '0', 'एक': '1', 'दो': '2', 'तीन': '3', 'चार': '4',
  'पाँच': '5', 'पांच': '5', 'छह': '6', 'छे': '6', 'सात': '7', 'आठ': '8', 'नौ': '9',
  // Bengali
  'শূন্য': '0', 'এক': '1', 'দুই': '2', 'তিন': '3', 'চার': '4',
  'পাঁচ': '5', 'ছয়': '6', 'সাত': '7', 'আট': '8', 'নয়': '9',
};
