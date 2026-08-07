import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'auth_service.dart';

enum SubscriptionStatus { trial, active, expired, grandfathered }

/// Why the paid part of the app is closed right now.
///
/// The locked screen has to name the reason precisely — "plant limit reached"
/// shown to someone whose trial ran out reads as a lie, and that is exactly
/// what it used to say. Kept separate from [SubscriptionStatus] because two
/// different states ("trial ran out", "subscription lapsed") both resolve to
/// `expired`, and the screen needs to tell them apart.
enum LockedReason {
  /// The free trial ran its course and nothing was bought after it.
  trialEnded,

  /// Access is live, but the plan's plant allowance is used up.
  freeLimit,

  /// A subscription existed and is no longer active.
  subscriptionExpired,
}

/// Which store the current subscription was bought through.
///
/// Decides where "Manage subscription" sends the user. Inferring it from the
/// presence of `stripeSubscriptionId` breaks for anyone who has paid both ways.
enum SubscriptionProvider { apple, google, stripe, unknown }

SubscriptionProvider _parseProvider(String? raw) => switch (raw) {
  'apple' => SubscriptionProvider.apple,
  'google' => SubscriptionProvider.google,
  'stripe' => SubscriptionProvider.stripe,
  _ => SubscriptionProvider.unknown,
};

class SubscriptionConfig {
  final int trialDays;
  final int trialPlantLimit;
  final int freePlantLimit;
  final int subscriptionPlantLimit;

  const SubscriptionConfig({
    this.trialDays = 14,
    this.trialPlantLimit = 3,
    this.freePlantLimit = 3,
    this.subscriptionPlantLimit = 10,
  });

  factory SubscriptionConfig.fromMap(Map<String, dynamic> map) {
    return SubscriptionConfig(
      trialDays: (map['trial_days'] as num?)?.toInt() ?? 14,
      trialPlantLimit: (map['trial_plant_limit'] as num?)?.toInt() ?? 3,
      freePlantLimit: (map['free_plant_limit'] as num?)?.toInt() ?? 3,
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

  /// The status as written in Firestore, before this class applied its own
  /// expiry arithmetic. Kept because `expired` alone cannot say *what* ended:
  /// a lapsed trial and a cancelled subscription need different wording, and
  /// only the raw value distinguishes them.
  final SubscriptionStatus rawStatus;

  /// Which store took the money. Written by both webhooks.
  final SubscriptionProvider provider;

  /// A payment is failing and the store is retrying. Access continues during
  /// the grace period — the point is to warn before it stops, rather than let
  /// the app go dark without explanation.
  final bool billingIssue;

  /// Set when the user holds subscriptions from two different stores at once.
  /// They are being charged twice; the app cannot cancel either one, but it
  /// must not stay quiet about it.
  final bool hasDuplicateSubscriptions;

  const SubscriptionInfo({
    required this.status,
    this.expiresAt,
    this.trialStartedAt,
    required this.config,
    this.autoRenewEnabled = true,
    this.stripeSubscriptionId,
    SubscriptionStatus? rawStatus,
    this.provider = SubscriptionProvider.unknown,
    this.billingIssue = false,
    this.hasDuplicateSubscriptions = false,
  }) : rawStatus = rawStatus ?? status;

  bool get isActive =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.grandfathered;

  bool get isTrial => status == SubscriptionStatus.trial;

  bool get isExpired => status == SubscriptionStatus.expired;

  /// The single question the whole app asks before opening anything paid.
  ///
  /// One function, one source of truth (SPEC 2.3). Every paid entry point —
  /// adding a plant, the health check, the AI chat — gates on this rather than
  /// re-deriving the rule, which is how the add-plant screen ended up claiming
  /// a plant limit was reached when the real reason was an expired trial.
  bool get hasAccess {
    if (status == SubscriptionStatus.grandfathered) return true;
    if (status == SubscriptionStatus.trial) return true;
    if (status != SubscriptionStatus.active) return false;
    // Belt and braces against a webhook that never arrived: an `active` row
    // with a date in the past is not access, it is a store event we missed.
    if (expiresAt == null) return true;
    return expiresAt!.isAfter(DateTime.now());
  }

  /// Why the paid part is closed, given how many plants the user has.
  ///
  /// Returns null while access is live and the allowance still has room.
  LockedReason? lockedReason(int plantCount) {
    if (!hasAccess) {
      // A trial that simply ran out never had a subscription behind it.
      return rawStatus == SubscriptionStatus.trial
          ? LockedReason.trialEnded
          : LockedReason.subscriptionExpired;
    }
    return slotsExhausted(plantCount) ? LockedReason.freeLimit : null;
  }

  /// Access is live but every slot is taken (SPEC 11).
  ///
  /// A different situation from [hasAccess] being false, and deliberately a
  /// different screen: there the user cannot generate anything, here they can
  /// — they have simply run out of room, and removing a plant fixes it without
  /// paying anyone.
  ///
  /// [plantCount] must be *live* plants. Soft-deleted ones hold no slot: the
  /// whole point is that deleting the third plant frees the third slot.
  bool slotsExhausted(int plantCount) => plantCount >= plantLimit;

  /// The date the locked screen quotes back to the user, or null when there
  /// is none to quote.
  DateTime? get accessEndedAt =>
      rawStatus == SubscriptionStatus.trial ? trialExpiresAt : expiresAt;

  /// How many plants this plan holds (SPEC 11, §1.1).
  ///
  /// A lapsed plan keeps its slots rather than dropping to zero. Someone who
  /// stopped paying still has their garden, and the count of what they may
  /// keep is not the same question as what they may still generate — the
  /// second one is [hasAccess].
  int get plantLimit {
    switch (status) {
      case SubscriptionStatus.active:
      case SubscriptionStatus.grandfathered:
        return config.subscriptionPlantLimit;
      case SubscriptionStatus.trial:
        return config.trialPlantLimit;
      case SubscriptionStatus.expired:
        return config.freePlantLimit;
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

  /// When the trial ends, or ended.
  ///
  /// Keyed off [rawStatus], not [status]: the whole point of this date is to
  /// be shown *after* the trial lapsed, by which time `status` has already
  /// moved on to `expired`.
  DateTime? get trialExpiresAt {
    if (rawStatus != SubscriptionStatus.trial) return null;
    if (trialStartedAt == null) return null;
    return trialStartedAt!.add(Duration(days: config.trialDays));
  }
}

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// The App Store key. A shipped build always uses this one.
  static const String _appStoreKey = 'appl_EvGqyyNvoDLXHRIFaGEMDwlaBuH';

  /// RevenueCat's simulated store, for working without touching the App Store.
  static const String _testStoreKey = 'test_PmSXLdLZsTNwVdwXrspziEIrGGU';

  /// Passed with --dart-define=REVENUECAT_KEY=... and honoured only in debug.
  static const String _keyOverride = String.fromEnvironment('REVENUECAT_KEY');

  /// Which store this build talks to.
  ///
  /// This used to be one constant that got edited by hand whenever someone
  /// wanted to test without the App Store. It was switched to the test key at
  /// least twice, and the second time it was not switched back: the build that
  /// went to the App Store in July carries it, which is why the paywall there
  /// shows no plans at all. Real purchases had been going through until then —
  /// the June builds all carry the App Store key.
  ///
  /// So the switch no longer lives in the source. A release build cannot be
  /// anything but the App Store, and the override is confined to debug, where
  /// forgetting to undo it costs nothing.
  static String get _revenueCatApiKey {
    if (kDebugMode && _keyOverride.isNotEmpty) return _keyOverride;
    return _appStoreKey;
  }

  /// Kept referenced so the test key stays discoverable from the code that
  /// documents it, rather than living only in a shell history somewhere.
  static String get testStoreKey => _testStoreKey;

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
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'revenueCatAppUserId': uid,
      }, SetOptions(merge: true));
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
      _userSub = _firestore.collection('users').doc(uid).snapshots().listen((
        userSnap,
      ) {
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

    // The same safety net the client applies to trials, applied to paid
    // subscriptions: a status of `active` with a date in the past means the
    // expiry webhook never landed, and honouring it would hand out the paid
    // tier for free, forever.
    if (resolved == SubscriptionStatus.active &&
        expiresAt != null &&
        expiresAt.isBefore(DateTime.now())) {
      resolved = SubscriptionStatus.expired;
    }

    final autoRenewEnabled = data['autoRenewEnabled'] as bool? ?? true;

    final stripeSubscriptionId = data['stripeSubscriptionId'] as String?;
    final originalTransactionId = data['originalTransactionId'] as String?;

    return SubscriptionInfo(
      status: resolved,
      rawStatus: status,
      expiresAt: expiresAt,
      trialStartedAt: trialStartedAt,
      config: _config,
      autoRenewEnabled: autoRenewEnabled,
      stripeSubscriptionId: stripeSubscriptionId,
      provider: _parseProvider(data['subscriptionProvider'] as String?),
      billingIssue: data['billingIssue'] as bool? ?? false,
      // Both ids present means two live subscriptions bought in two stores.
      // Neither webhook can see the other, so this is the only place it shows.
      hasDuplicateSubscriptions:
          (stripeSubscriptionId != null && stripeSubscriptionId.isNotEmpty) &&
          (originalTransactionId != null && originalTransactionId.isNotEmpty),
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

    final configSnap = await _firestore
        .collection('app_config')
        .doc('subscription')
        .get();
    if (configSnap.exists) {
      _config = SubscriptionConfig.fromMap(configSnap.data()!);
    }

    final userSnap = await _firestore.collection('users').doc(uid).get();
    if (!userSnap.exists) {
      return SubscriptionInfo(
        status: SubscriptionStatus.trial,
        config: _config,
      );
    }

    final info = _buildInfo(userSnap.data()!);
    _cachedInfo = info;
    return info;
  }

  /// Returns true if the user can add another plant.
  Future<bool> canAddPlant(int currentPlantCount) async {
    final info = await fetchInfo();
    if (!info.hasAccess) return false;
    return currentPlantCount < info.plantLimit;
  }

  // ── Purchases ──────────────────────────────────────────────────────────────

  /// Fetch available offerings from RevenueCat.
  /// Returns empty list on web (not supported).
  /// The plans on offer, or an explanation of why there are none.
  ///
  /// This used to swallow the error and return an empty list, so every
  /// possible cause — wrong key, no offering configured, products not ready in
  /// App Store Connect, Paid Apps agreement unsigned — arrived at the screen
  /// as the same blank shrug. That turned a five-minute fix into weeks of
  /// guessing, because the one thing that would have named it was thrown away
  /// one line after RevenueCat handed it over.
  Future<List<Package>> fetchPackages() async {
    if (kIsWeb) return [];
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    // No offering is not an error as far as the SDK is concerned, but it is
    // still a misconfiguration, and the owner deserves to be told which.
    if (current == null) {
      throw StateError(
        'RevenueCat returned no current offering '
        '(${offerings.all.length} offering(s) configured).',
      );
    }
    return current.availablePackages;
  }

  /// Purchase a specific package.
  Future<bool> purchase(Package package) async {
    if (kIsWeb) return false;
    try {
      final info = await Purchases.purchasePackage(package);
      final hasPremium = info.entitlements.active.containsKey('premium');
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
        try {
          expiresDate = DateTime.parse(expiresRaw);
        } catch (_) {}
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
      final hasPremium = info.entitlements.active.containsKey('premium');
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
