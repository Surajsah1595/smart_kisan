import os

def rewrite_localization():
    file_path = 'lib/localization_service.dart'
    
    # We will replace the entire file content.
    new_content = """import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class LocalizationService {
  static const String EN = 'en';
  static const String HI = 'hi';
  static const String NE = 'ne';
  static const String _languageKey = 'app_language';

  // Global language state (singleton pattern)
  static String _currentLanguage = EN;

  static String get currentLanguage => _currentLanguage;

  static void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    _saveLanguagePreference(languageCode);
  }

  // Load language from SharedPreferences
  static Future<String> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? EN;
      _currentLanguage = savedLanguage;
      return savedLanguage;
    } catch (e) {
      print('Error loading language: $e');
      _currentLanguage = EN;
      return EN;
    }
  }

  // Save language to SharedPreferences
  static Future<void> _saveLanguagePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  // Fallback map just in case any UI still depends on map logic (we empty it)
  static final Map<String, Map<String, String>> _translations = {};

  static String translate(String key, {String? language}) {
    return key.tr();
  }
}

// LocalizationProvider - A notifier that manages language changes
class LocalizationProvider extends ChangeNotifier {
  String _currentLanguage = LocalizationService.EN;

  String get currentLanguage => _currentLanguage;

  void setLanguage(String languageCode) {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      LocalizationService.setLanguage(languageCode);
      notifyListeners();
    }
  }

  String translate(String key) {
    return key.tr();
  }
}
"""

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
        
    print("Rewrote localization_service.dart")

if __name__ == '__main__':
    rewrite_localization()
