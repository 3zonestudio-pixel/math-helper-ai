import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class AppProvider extends ChangeNotifier {
  String _language = 'en';
  String _difficulty = AppConstants.intermediate;
  String _explanationMode = AppConstants.detailedMode;
  bool _isDarkMode = true;
  bool _isReady = false;

  String get language => _language;
  String get difficulty => _difficulty;
  String get explanationMode => _explanationMode;
  bool get isDarkMode => _isDarkMode;
  bool get isReady => _isReady;

  bool get isRtl => AppConstants.rtlLanguages.contains(_language);

  AppProvider._();

  static Future<AppProvider> create() async {
    final provider = AppProvider._();
    await provider._loadPreferences();
    provider._isReady = true;
    return provider;
  }

  /// Detect language from device locale, matching supported languages.
  static String detectDeviceLanguage() {
    try {
      final locales = WidgetsBinding.instance.platformDispatcher.locales;
      if (locales.isNotEmpty) {
        for (final locale in locales) {
          final code = locale.languageCode;
          if (AppConstants.supportedLanguages.containsKey(code)) {
            return code;
          }
        }
      }
    } catch (_) {}
    return 'en';
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLang = prefs.getString('language');
    _language = storedLang ?? detectDeviceLanguage();
    if (storedLang == null) {
      // Persist auto-detected language
      await prefs.setString('language', _language);
    }
    _difficulty = prefs.getString('difficulty') ?? AppConstants.intermediate;
    _explanationMode = prefs.getString('explanationMode') ?? AppConstants.detailedMode;
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  Future<void> setDifficulty(String difficulty) async {
    _difficulty = difficulty;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('difficulty', difficulty);
    notifyListeners();
  }

  Future<void> setExplanationMode(String mode) async {
    _explanationMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('explanationMode', mode);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
