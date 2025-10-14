import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  static const String _keyDefaultLanguage = 'default_language';
  static const String _defaultLanguageValue = 'English';

  // Get default language
  static Future<String> getDefaultLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDefaultLanguage) ?? _defaultLanguageValue;
    } catch (error) {
      debugPrint('Error getting default language: $error');
      return _defaultLanguageValue;
    }
  }

  // Set default language
  static Future<bool> setDefaultLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyDefaultLanguage, language);
    } catch (error) {
      debugPrint('Error setting default language: $error');
      return false;
    }
  }

  // Available languages
  static const List<String> availableLanguages = [
    'Chinese',
    'English',
    'Japanese',
    'Korean',
  ];
}
