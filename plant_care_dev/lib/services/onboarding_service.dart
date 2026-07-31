import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the one-time onboarding flag.
///
/// Storage strategy:
/// - SharedPreferences: fast synchronous cache, survives app restarts.
/// - Firestore `users/{uid}.onboardingComplete`: survives reinstalls and
///   new devices; only updated when user is signed in.
///
/// Rule for **existing** users who have no field yet: we treat absence of
/// the field as "not completed" so they see the onboarding once, then it
/// writes `true` and they never see it again.
class OnboardingService {
  static const _prefKey = 'onboarding_complete';

  // ── Cached value loaded at startup ──────────────────────────────────────
  static bool _cachedComplete = false;

  static bool get isComplete => _cachedComplete;

  /// Call this at app startup (after Firebase is ready).
  /// Reads from SharedPreferences first; if authed also reconciles Firestore.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedComplete = prefs.getBool(_prefKey) ?? false;

    // If prefs say complete, we trust it and skip the Firestore round-trip.
    if (_cachedComplete) return;

    // If authed, check Firestore so reinstalls work correctly.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _syncFromFirestore(prefs, uid);
    }
  }

  /// Call once after a user signs in (login or new auth state).
  /// Syncs the Firestore value into the local cache.
  static Future<void> onLogin(String uid) async {
    if (_cachedComplete) return; // already done, no need to hit Firestore
    final prefs = await SharedPreferences.getInstance();
    await _syncFromFirestore(prefs, uid);
  }

  /// Mark onboarding as complete and persist everywhere.
  static Future<void> markComplete() async {
    _cachedComplete = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _writeFirestore(uid, true);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Future<void> _syncFromFirestore(SharedPreferences prefs, String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      // Absent field → treat as false (show onboarding once)
      final firestoreValue = data?['onboardingComplete'] as bool? ?? false;
      _cachedComplete = firestoreValue;
      await prefs.setBool(_prefKey, firestoreValue);
    } catch (_) {
      // Network error — keep local cache as-is
    }
  }

  static Future<void> _writeFirestore(String uid, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'onboardingComplete': value}, SetOptions(merge: true));
    } catch (_) {
      // Best-effort; will be retried on next login via _syncFromFirestore
    }
  }
}
