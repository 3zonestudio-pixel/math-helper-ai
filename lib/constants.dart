class AppConstants {
  static const String appName = 'Math Helper AI';
  static const String appVersion = '1.0.0';

  // Difficulty levels
  static const String beginner = 'beginner';
  static const String intermediate = 'intermediate';
  static const String advanced = 'advanced';

  // Explanation modes
  static const String simpleMode = 'simple';
  static const String detailedMode = 'detailed';

  // Math categories
  static const String algebra = 'algebra';
  static const String calculus = 'calculus';
  static const String geometry = 'geometry';
  static const String statistics = 'statistics';
  static const String general = 'general';

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ar': 'العربية',
    'fr': 'Français',
    'es': 'Español',
    'zh': '中文',
    'de': 'Deutsch',
    'hi': 'हिन्दी',
    'ja': '日本語',
    'ko': '한국어',
    'ru': 'Русский',
    'pt': 'Português',
    'tr': 'Türkçe',
    'it': 'Italiano',
  };

  // RTL languages
  static const List<String> rtlLanguages = ['ar'];
}
