import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'auth_service.dart';

enum SubscriptionStatus { trial, active, expired, grandfathered }

class SubscriptionConfig {
  final int trialDays;
  final int trialPlantLimit;
  final int subscriptionPlantLimit;

  const SubscriptionConfig({
    this.trialDays = 14,
    this.trialPlantLimit = 2,
    this.subscriptionPlantLimit = 10,
  });

  factory SubscriptionConfig.fromMap(Map<String, dynamic> map) {
    return SubscriptionConfig(
      trialDays: (map['trial_days'] as num?)?.toInt() ?? 14,
      trialPlantLimit: (map['trial_plant_limit'] as num?)?.toInt() ?? 2,
      subscriptionPlantLimit:
          (map['subscription_plant_limit'] as num?)?.toInt() ?? 10,
    );
  }
}

class SubscriptionInfo {
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final DateTime? trialStartedAt;
  final SubscriptionConfig config;
  final bool autoRenewEnabled;
  final String? stripeSubscriptionId;

  const SubscriptionInfo({
    required this.status,
    this.expiresAt,
    this.trialStartedAt,
    required this.config,
    this.autoRenewEnabled = true,
    this.stripeSubscriptionId,
  });

  bool get isActive =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.grandfathered;

  bool get isTrial => status == SubscriptionStatus.trial;

  bool get isExpired => status == SubscriptionStatus.expired;

  int get plantLimit {
    switch (status) {
      case SubscriptionStatus.active:
      case SubscriptionStatus.grandfathered:
        return config.subscriptionPlantLimit;
      case SubscriptionStatus.trial:
        return config.trialPlantLimit;
      case SubscriptionStatus.expired:
        return 0;
    }
  }

  /// Days remaining in trial (null if not in trial)
  int? get trialDaysRemaining {
    if (status != SubscriptionStatus.trial) return null;
    if (trialStartedAt == null) return null;
    final elapsed = DateTime.now().difference(trialStartedAt!).inDays;
    final remaining = config.trialDays - elapsed;
    return remaining.clamp(0, config.trialDays);
  }

  /// Trial expiry date (null if not in trial)
  DateTime? get trialExpiresAt {
    if (status != SubscriptionStatus.trial) return null;
    if (trialStartedAt == null) return null;
    return trialStartedAt!.add(Duration(days: config.trialDays));
  }
}

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static const String _revenueCatApiKey =
      'test_PmSXLdLZsTNwVdwXrspziEIrGGU';

  static const String _monthlyProductId = 'com.botanly.app.monthly';
  static const String _annualProductId = 'com.botanly.app.annual';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SubscriptionInfo? _cachedInfo;
  SubscriptionConfig _config = const SubscriptionConfig();

  StreamController<SubscriptionInfo>? _controller;
  StreamSubscription<DocumentSnapshot>? _userSub;

  /// Initialize RevenueCat SDK. Call once in main() after Firebase init.
  /// No-op on web (purchases_flutter is iOS/Android only).
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await Purchases.setLogLevel(LogLevel.info);
    final config = PurchasesConfiguration(_revenueCatApiKey);
    await Purchases.configure(config);

    // Identify user to RevenueCat after login
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      await _identifyUser(uid);
    }
  }

  static Future<void> _identifyUser(String uid) async {
    if (kIsWeb) return;
    try {
      await Purchases.logIn(uid);
      // Persist RC app user ID to Firestore for webhook matching
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'revenueCatAppUserId': uid}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ RevenueCat logIn failed: $e');
    }
  }

  /// Call when user logs in.
  static Future<void> onLogin(String uid) => _identifyUser(uid);

  /// Call when user logs out.
  static Future<void> onLogout() async {
    if (kIsWeb) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('⚠️ RevenueCat logOut failed: $e');
    }
  }

  /// Stream of subscription info — updates in real time from Firestore.
  Stream<SubscriptionInfo> get stream {
    _controller ??= StreamController<SubscriptionInfo>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _controller!.stream;
  }

  void _startListening() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    // Load config FIRST, then subscribe to user doc so every event
    // uses the correct Firestore limits rather than in-code defaults.
    _firestore.collection('app_config').doc('subscription').get().then((snap) {
      if (snap.exists) {
        _config = SubscriptionConfig.fromMap(snap.data()!);
      }
      // Only start the user stream after config is ready.
      _userSub = _firestore
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((userSnap) {
        if (!userSnap.exists) return;
        final info = _buildInfo(userSnap.data()!);
        _cachedInfo = info;
        _controller?.add(info);
      });
    });
  }

  void _stopListening() {
    _userSub?.cancel();
    _userSub = null;
  }

  SubscriptionInfo _buildInfo(Map<String, dynamic> data) {
    final statusStr = data['subscriptionStatus'] as String? ?? 'trial';
    final status = _parseStatus(statusStr);

    DateTime? expiresAt;
    final raw = data['subscriptionExpiresAt'];
    if (raw is Timestamp) expiresAt = raw.toDate();

    DateTime? trialStartedAt;
    final createdRaw = data['createdAt'];
    if (createdRaw is Timestamp) {
      trialStartedAt = createdRaw.toDate();
    } else if (createdRaw is String) {
      trialStartedAt = DateTime.tryParse(createdRaw);
    }

    // Auto-expire trial if time has passed
    SubscriptionStatus resolved = status;
    if (status == SubscriptionStatus.trial && trialStartedAt != null) {
      final elapsed = DateTime.now().difference(trialStartedAt).inDays;
      if (elapsed >= _config.trialDays) {
        resolved = SubscriptionStatus.expired;
      }
    }

    final autoRenewEnabled = data['autoRenewEnabled'] as bool? ?? true;

    final stripeSubscriptionId = data['stripeSubscriptionId'] as String?;

    return SubscriptionInfo(
      status: resolved,
      expiresAt: expiresAt,
      trialStartedAt: trialStartedAt,
      config: _config,
      autoRenewEnabled: autoRenewEnabled,
      stripeSubscriptionId: stripeSubscriptionId,
    );
  }

  static SubscriptionStatus _parseStatus(String s) {
    switch (s) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'grandfathered':
        return SubscriptionStatus.grandfathered;
      default:
        return SubscriptionStatus.trial;
    }
  }

  /// Quick sync fetch — use for one-off checks.
  Future<SubscriptionInfo> fetchInfo() async {
    if (_cachedInfo != null) return _cachedInfo!;

    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      return SubscriptionInfo(
        status: SubscriptionStatus.trial,
        config: _config,
      );
    }

    final configSnap =
        await _firestore.collection('app_config').doc('subscription').get();
    if (configSnap.exists) {
      _config = SubscriptionConfig.fromMap(configSnap.data()!);
    }

    final userSnap =
        await _firestore.collection('users').doc(uid).get();
    if (!userSnap.exists) {
      return SubscriptionInfo(status: SubscriptionStatus.trial, config: _config);
    }

    final info = _buildInfo(userSnap.data()!);
    _cachedInfo = info;
    return info;
  }

  /// Returns true if the user can add another plant.
  Future<bool> canAddPlant(int currentPlantCount) async {
    final info = await fetchInfo();
    if (info.isExpired) return false;
    return currentPlantCount < info.plantLimit;
  }

  // ── Purchases ──────────────────────────────────────────────────────────────

  /// Fetch available offerings from RevenueCat.
  /// Returns empty list on web (not supported).
  Future<List<Package>> fetchPackages() async {
    if (kIsWeb) return [];
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];
      return current.availablePackages;
    } catch (e) {
      debugPrint('⚠️ fetchPackages error: $e');
      return [];
    }
  }

  /// Purchase a specific package.
  Future<bool> purchase(Package package) async {
    if (kIsWeb) return false;
    try {
      final info = await Purchases.purchasePackage(package);
      final hasPremium =
          info.entitlements.active.containsKey('premium');
      _invalidateCache();
      if (hasPremium) {
        await _writeActiveToFirestore(info);
      }
      // Return true even if entitlement isn't reflected yet — the purchase
      // succeeded (Apple confirmed it). RevenueCat webhook will sync Firestore.
      return true;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  /// Immediately write active subscription status to Firestore so the
  /// StreamBuilder updates before the RevenueCat webhook fires.
  Future<void> _writeActiveToFirestore(CustomerInfo rcInfo) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      final entitlement = rcInfo.entitlements.active['premium'];
      final expiresRaw = entitlement?.expirationDate;
      DateTime? expiresDate;
      if (expiresRaw != null) {
        try { expiresDate = DateTime.parse(expiresRaw); } catch (_) {}
      }
      final data = <String, dynamic>{
        'subscriptionStatus': 'active',
        if (expiresDate != null)
          'subscriptionExpiresAt': Timestamp.fromDate(expiresDate),
      };
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('⚠️ _writeActiveToFirestore error: $e');
    }
  }

  /// Restore previous purchases.
  Future<bool> restorePurchases() async {
    if (kIsWeb) return false;
    try {
      final info = await Purchases.restorePurchases();
      final hasPremium =
          info.entitlements.active.containsKey('premium');
      if (hasPremium) _invalidateCache();
      return hasPremium;
    } catch (e) {
      debugPrint('⚠️ restorePurchases error: $e');
      return false;
    }
  }

  /// Last known subscription info — use as StreamBuilder initialData
  /// so new subscribers don't wait for the next Firestore event.
  SubscriptionInfo? get currentInfo => _cachedInfo;

  void _invalidateCache() {
    _cachedInfo = null;
  }

  /// Product IDs (for reference)
  static String get monthlyProductId => _monthlyProductId;
  static String get annualProductId => _annualProductId;
}

class SubscriptionLimitException implements Exception {
  final String message;
  const SubscriptionLimitException(this.message);

  @override
  String toString() => message;
}
