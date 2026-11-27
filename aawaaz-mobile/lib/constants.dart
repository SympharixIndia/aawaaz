/// App-wide constants and configuration for Aawaaz V1.
///
/// V1 is intentionally simple: no backend, all data in memory, and the manager
/// dashboard is gated by a single hardcoded credential defined here.
library;

class AppConstants {
  static const String appName = 'Aawaaz';

  // Hardcoded manager login (V1 only — not real security).
  static const String managerUsername = 'admin';
  static const String managerPassword = 'admin123';
}

/// A language the app can prompt and listen in.
class AppLanguage {
  final String code; // BCP-47 locale used by STT/TTS, e.g. "hi-IN"
  final String label;
  const AppLanguage(this.code, this.label);
}

/// Languages supported in V1.
const List<AppLanguage> supportedLanguages = [
  AppLanguage('hi-IN', 'हिन्दी (Hindi)'),
  AppLanguage('bn-IN', 'বাংলা (Bengali)'),
  AppLanguage('en-IN', 'English'),
];
