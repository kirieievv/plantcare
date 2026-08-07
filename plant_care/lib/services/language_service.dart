import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'language';
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(
    const Locale('en'),
  );

  /// Called once at app startup. Priority: SharedPreferences → device locale.
  /// After login, call [syncFromFirestore] to pull the user's saved language.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_languageKey);

    if (stored != null) {
      localeNotifier.value = _localeFromCode(stored);
    } else {
      final deviceCode =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final locale = _localeFromCode(deviceCode);
      localeNotifier.value = locale;
      // Persist the resolved code so Settings and future Firestore sync see it.
      await prefs.setString(_languageKey, locale.languageCode);
    }
  }

  /// Sync language after login.
  ///
  /// - Fresh install (SharedPreferences empty): pull from Firestore so the
  ///   user's preference survives reinstalls and device changes.
  /// - Returning user (SharedPreferences has a value): keep the local language
  ///   (no flash) and push it back to Firestore to keep the cloud copy fresh.
  static Future<void> syncFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final prefs = await SharedPreferences.getInstance();
      final localCode = prefs.getString(_languageKey);

      if (localCode != null) {
        // Already have a local preference — trust it, sync it to Firestore.
        _saveToFirestore(localCode);
        return;
      }

      // Fresh install — pull from Firestore.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final firestoreCode = doc.data()?['language'] as String?;
      if (firestoreCode != null && firestoreCode.isNotEmpty) {
        await prefs.setString(_languageKey, firestoreCode);
        localeNotifier.value = _localeFromCode(firestoreCode);
      }
    } catch (_) {
      // Firestore unavailable — keep the locally cached value
    }
  }

  /// Change language, persist to SharedPreferences and Firestore.
  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
    localeNotifier.value = _localeFromCode(code);
    _saveToFirestore(code);
  }

  static void _saveToFirestore(String code) {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'language': code,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Locale _localeFromCode(String code) {
    switch (code) {
      case 'de':
        return const Locale('de');
      case 'es':
        return const Locale('es');
      case 'fr':
        return const Locale('fr');
      case 'ru':
        return const Locale('ru');
      case 'uk':
        return const Locale('uk');
      case 'en':
      default:
        return const Locale('en');
    }
  }
}
