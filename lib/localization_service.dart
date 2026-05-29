import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

/// Purpose: Manages global localization state and persists user language preferences locally using SharedPreferences.
/// Inputs: String languageCodes (e.g. 'en', 'hi', 'ne').
/// Outputs: Persists state and provides getter/setters for the active language.
class LocalizationService {
  static const String EN = 'en';
  static const String HI = 'hi';
  static const String NE = 'ne';
  static const String _languageKey = 'app_language';

  // Global language state (singleton pattern)
  static String _currentLanguage = EN;

  static String get currentLanguage => _currentLanguage;

  /// Purpose: Updates the active language code in memory and persists it to local storage.
  /// Inputs: [languageCode] - A valid locale string (e.g. 'en', 'hi', 'ne').
  /// Outputs: None directly.
  static void setLanguage(String languageCode) {
    // 1. Update the singleton's in-memory variable for immediate access.
    _currentLanguage = languageCode;
    // 2. Persist the choice to disk so it survives app restarts.
    _saveLanguagePreference(languageCode);
  }

  /// Purpose: Bootstraps the global language state by reading from SharedPreferences.
  /// Inputs: None.
  /// Outputs: Returns the loaded language code string.
  static Future<String> loadLanguage() async {
    try {
      // 1. Initialize the SharedPreferences disk wrapper.
      final prefs = await SharedPreferences.getInstance();
      // 2. Fetch the stored key, defaulting to English ('en') if not found.
      final savedLanguage = prefs.getString(_languageKey) ?? EN;
      // 3. Sync the disk value to the memory singleton.
      _currentLanguage = savedLanguage;
      return savedLanguage;
    } catch (e) {
      // 4. Fallback to English safely if disk access fails.
      print('Error loading language: $e');
      _currentLanguage = EN;
      return EN;
    }
  }

  /// Purpose: Private helper to commit the language selection to disk.
  /// Inputs: [languageCode] - The locale string to save.
  /// Outputs: Completes asynchronously when the disk write finishes.
  static Future<void> _saveLanguagePreference(String languageCode) async {
    try {
      // 1. Initialize the SharedPreferences disk wrapper.
      final prefs = await SharedPreferences.getInstance();
      // 2. Asynchronously commit the key-value pair to persistent storage.
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      // 3. Gracefully swallow disk errors to prevent crashes.
      print('Error saving language: $e');
    }
  }

  // Fallback map just in case any UI still depends on map logic (we empty it)
  static final Map<String, Map<String, String>> _translations = {};

  /// Purpose: Global static helper that delegates translation resolution to the easy_localization package.
  /// Inputs: [key] - The string identifier to translate. [language] - Optional override.
  /// Outputs: Returns the localized string matching the active locale.
  static String translate(String key, {String? language}) {
    // 1. Invoke the .tr() extension method provided by easy_localization on the string key.
    return key.tr();
  }
}

/// Purpose: A ChangeNotifier wrapper around [LocalizationService] to allow Provider-based UI rebuilds when the language changes.
class LocalizationProvider extends ChangeNotifier {
  String _currentLanguage = LocalizationService.EN;

  String get currentLanguage => _currentLanguage;

  /// Purpose: Updates the language and alerts listening widgets to rebuild themselves.
  /// Inputs: [languageCode] - The new locale string.
  /// Outputs: None directly, but triggers a global UI refresh.
  void setLanguage(String languageCode) {
    // 1. Avoid redundant rebuilds by checking if the language actually changed.
    if (_currentLanguage != languageCode) {
      // 2. Update the local provider state.
      _currentLanguage = languageCode;
      // 3. Sync the state with the global static service for persistence.
      LocalizationService.setLanguage(languageCode);
      // 4. Broadcast the state change to all descendant widgets wrapped in Consumer/watch.
      notifyListeners();
    }
  }

  /// Purpose: Instance-level helper for translations, mapping back to easy_localization.
  /// Inputs: [key] - The string identifier.
  /// Outputs: The translated string.
  String translate(String key) {
    // 1. Invoke the .tr() extension on the raw string.
    return key.tr();
  }
}
