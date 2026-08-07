/// The one question that decides whether the paid app opens (SPEC 9, §2.3).
///
/// Every paid entry point — adding a plant, the health check, the AI chat —
/// asks `hasAccess`, and the locked screen picks its wording from
/// `lockedReason`. Getting either wrong is expensive in both directions: too
/// strict and paying users are locked out, too loose and the paid tier is free.
/// These pin both edges.
import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care/services/subscription_service.dart';

const _config = SubscriptionConfig(
  trialDays: 14,
  trialPlantLimit: 3,
  freePlantLimit: 3,
  subscriptionPlantLimit: 10,
);

SubscriptionInfo _info({
  required SubscriptionStatus status,
  SubscriptionStatus? rawStatus,
  DateTime? expiresAt,
  DateTime? trialStartedAt,
  bool billingIssue = false,
  String? stripeId,
}) => SubscriptionInfo(
  status: status,
  rawStatus: rawStatus,
  expiresAt: expiresAt,
  trialStartedAt: trialStartedAt,
  config: _config,
  billingIssue: billingIssue,
  stripeSubscriptionId: stripeId,
);

void main() {
  final past = DateTime.now().subtract(const Duration(days: 3));
  final future = DateTime.now().add(const Duration(days: 30));

  group('hasAccess', () {
    test('an active subscription with time left is open', () {
      expect(
        _info(status: SubscriptionStatus.active, expiresAt: future).hasAccess,
        isTrue,
      );
    });

    test('an active row with a date in the past is not access', () {
      // The lost-webhook case. Honouring the stored status here is how an
      // account keeps the paid tier for free, forever.
      expect(
        _info(status: SubscriptionStatus.active, expiresAt: past).hasAccess,
        isFalse,
      );
    });

    test('an active subscription with no date is open', () {
      // Nothing to check it against; refusing here would lock out anyone whose
      // store never sent an expiry.
      expect(_info(status: SubscriptionStatus.active).hasAccess, isTrue);
    });

    test('a live trial is open', () {
      expect(_info(status: SubscriptionStatus.trial).hasAccess, isTrue);
    });

    test('grandfathered accounts never meet the paywall', () {
      expect(
        _info(status: SubscriptionStatus.grandfathered).hasAccess,
        isTrue,
      );
    });

    test('expired is closed', () {
      expect(_info(status: SubscriptionStatus.expired).hasAccess, isFalse);
    });

    test('a failing payment does not close access on its own', () {
      // The grace period is the store's to run; the app only warns.
      expect(
        _info(
          status: SubscriptionStatus.active,
          expiresAt: future,
          billingIssue: true,
        ).hasAccess,
        isTrue,
      );
    });
  });

  group('lockedReason', () {
    test('a lapsed trial says so, whatever the plant count', () {
      // The bug this replaces: with the trial over and one plant in the
      // garden, the screen announced "plant limit reached".
      final info = _info(
        status: SubscriptionStatus.expired,
        rawStatus: SubscriptionStatus.trial,
      );
      expect(info.lockedReason(1), LockedReason.trialEnded);
      expect(info.lockedReason(0), LockedReason.trialEnded);
    });

    test('a lapsed subscription is told apart from a lapsed trial', () {
      final info = _info(
        status: SubscriptionStatus.expired,
        rawStatus: SubscriptionStatus.expired,
      );
      expect(info.lockedReason(3), LockedReason.subscriptionExpired);
    });

    test('a full garden on a live plan is the only "limit" case', () {
      final info = _info(status: SubscriptionStatus.trial);
      expect(info.lockedReason(_config.trialPlantLimit), LockedReason.freeLimit);
    });

    test('room to spare means nothing is locked', () {
      expect(_info(status: SubscriptionStatus.trial).lockedReason(0), isNull);
      expect(
        _info(
          status: SubscriptionStatus.active,
          expiresAt: future,
        ).lockedReason(3),
        isNull,
      );
    });
  });

  group('accessEndedAt', () {
    test('a lapsed trial quotes the trial end, not a subscription date', () {
      final started = DateTime(2026, 7, 1);
      final info = _info(
        status: SubscriptionStatus.expired,
        rawStatus: SubscriptionStatus.trial,
        trialStartedAt: started,
      );
      expect(info.accessEndedAt, started.add(const Duration(days: 14)));
    });

    test('a lapsed subscription quotes its own expiry', () {
      final info = _info(
        status: SubscriptionStatus.expired,
        rawStatus: SubscriptionStatus.expired,
        expiresAt: past,
      );
      expect(info.accessEndedAt, past);
    });
  });

  group('plantLimit', () {
    test('the paid tier gets the paid allowance', () {
      expect(
        _info(status: SubscriptionStatus.active, expiresAt: future).plantLimit,
        _config.subscriptionPlantLimit,
      );
    });

    test('a trial gets the trial allowance', () {
      expect(
        _info(status: SubscriptionStatus.trial).plantLimit,
        _config.trialPlantLimit,
      );
    });
  });

  _slotTests();

  test('two store ids at once is reported as a double subscription', () {
    // Neither webhook can see the other, so this is the only place the user
    // is ever told they are paying twice.
    const both = SubscriptionInfo(
      status: SubscriptionStatus.active,
      config: _config,
      hasDuplicateSubscriptions: true,
    );
    expect(both.hasDuplicateSubscriptions, isTrue);
  });
}

/// Plant slots (SPEC 11).
///
/// The bug these replace: deleting the third plant did not give the slot back,
/// so someone who deliberately made room still hit the wall. The fix is that
/// there is no stored counter at all — the number of live plants is the only
/// source of truth, and these pin the arithmetic around it.
void _slotTests() {
  final future = DateTime.now().add(const Duration(days: 30));

  group('plant slots', () {
    test('a trial gets three', () {
      expect(_info(status: SubscriptionStatus.trial).plantLimit, 3);
    });

    test('a lapsed plan keeps three rather than dropping to zero', () {
      // Ending a subscription must not read as "your garden is now invalid".
      expect(_info(status: SubscriptionStatus.expired).plantLimit, 3);
    });

    test('premium gets ten', () {
      expect(
        _info(status: SubscriptionStatus.active, expiresAt: future).plantLimit,
        10,
      );
    });

    test('a freed slot is immediately usable', () {
      final info = _info(status: SubscriptionStatus.trial);
      expect(info.slotsExhausted(3), isTrue);
      // The count passed in is live plants, so a deletion lands here as 2.
      expect(info.slotsExhausted(2), isFalse);
    });

    test('seven plants on a lapsed plan block adding but keep the plants', () {
      // SPEC 11 §1.4: existing plants are never taken away.
      final info = _info(status: SubscriptionStatus.expired);
      expect(info.slotsExhausted(7), isTrue);
      expect(info.plantLimit, 3);
    });

    test('running out of room is not the same as losing access', () {
      final full = _info(status: SubscriptionStatus.trial);
      expect(full.hasAccess, isTrue);
      expect(full.slotsExhausted(3), isTrue);
      // Access is live, so the paywall reason is the slot one, not a lapse.
      expect(full.lockedReason(3), LockedReason.freeLimit);
    });
  });
}
