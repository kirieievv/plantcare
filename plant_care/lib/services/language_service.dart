import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'language';
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(const Locale('en'));

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_languageKey) ?? 'en';
    localeNotifier.value = _localeFromCode(stored);
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
    localeNotifier.value = _localeFromCode(code);
  }

  static Locale _localeFromCode(String code) {
    switch (code) {
      case 'de':
        return const Locale('de');
      case 'es':
        return const Locale('es');
      case 'fr':
        return const Locale('fr');
      case 'en':
      default:
        return const Locale('en');
    }
  }
}
