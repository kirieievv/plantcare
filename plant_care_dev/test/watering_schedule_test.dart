/// When a newly added plant is due its first watering.
///
/// The bug these pin down: the care plan promised "first watering in 4 days"
/// and the plant screen, opened a second later, said 7. The quiz answer
/// ("watered 2–3 days ago") reached the document and was then thrown away by
/// the service, which always counted from the moment of adding.
///
/// Only one of the four quiz answers diverged — the other three have the anchor
/// on today or hand the decision to `shouldWaterNow` — which is why it survived
/// this long. Hence a case per answer.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care/services/plant_service.dart';

void main() {
  // The day the bug was reported, so the arithmetic below reads like the
  // screenshots it came from.
  final now = DateTime(2026, 8, 10, 14, 30);

  DateTime due({
    required int? wateredDaysAgo,
    required int interval,
    bool shouldWaterNow = false,
    String preferredTime = '18:00',
  }) => PlantService.initialWateringDue(
    now: now,
    anchor: wateredDaysAgo == null
        ? null
        : now.subtract(Duration(days: wateredDaysAgo)),
    intervalDays: interval,
    shouldWaterNow: shouldWaterNow,
    preferredTime: preferredTime,
  );

  group('the four quiz answers', () {
    test('"2–3 days ago" waters four days from today, not seven', () {
      // 7 Aug + 7 days. Counting from today would give 17 Aug — ten days
      // between two waterings on a card that says "every 7 days".
      expect(due(wateredDaysAgo: 3, interval: 7), DateTime(2026, 8, 14, 18, 0));
    });

    test('"today" waters a full interval out', () {
      expect(due(wateredDaysAgo: 0, interval: 7), DateTime(2026, 8, 17, 18, 0));
    });

    test('"about a week ago" is already due, and says so today', () {
      // The add screen sets shouldWaterNow when the plant is past its interval.
      expect(due(wateredDaysAgo: 7, interval: 7, shouldWaterNow: true), now);
    });

    test('"don\'t know" is the same answer: check the soil today', () {
      expect(due(wateredDaysAgo: null, interval: 7, shouldWaterNow: true), now);
    });
  });

  test('no anchor at all still schedules from today', () {
    // The legacy add screens never asked the question.
    expect(
      due(wateredDaysAgo: null, interval: 7),
      DateTime(2026, 8, 17, 18, 0),
    );
  });

  test('the preferred hour survives the anchoring', () {
    expect(
      due(wateredDaysAgo: 3, interval: 7, preferredTime: '09:15'),
      DateTime(2026, 8, 14, 9, 15),
    );
  });

  test('a short interval lands the first watering tomorrow', () {
    // Terracotta on a windowsill: the quiz can pull the interval down to 2.
    expect(due(wateredDaysAgo: 1, interval: 2), DateTime(2026, 8, 11, 18, 0));
  });
}
