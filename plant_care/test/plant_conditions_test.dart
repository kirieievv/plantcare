/// The arithmetic behind the care plan the conditions quiz produces.
///
/// These are the numbers the user is promised on the last step and then lives
/// with for months, so they are pinned here rather than left to the screen.
import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care/utils/plant_conditions.dart';

void main() {
  group('wateringMlForPot', () {
    test('grows with the pot and lands on a pourable number', () {
      // π·8²·12.8·0.15 ≈ 386 → 400 ml, rounded to the nearest 50. This is the
      // number the mockup shows under the default 16 cm pot.
      expect(wateringMlForPot(16), 400);
      expect(wateringMlForPot(8), 50);
      expect(wateringMlForPot(40), 6050);
      expect(wateringMlForPot(24) % 50, 0);
    });

    test('a pot outside the slider is clamped, not extrapolated', () {
      expect(wateringMlForPot(2), wateringMlForPot(kPotMinCm));
      expect(wateringMlForPot(400), wateringMlForPot(kPotMaxCm));
    });
  });

  group('conditionedWateringInterval', () {
    test('with nothing answered the species baseline survives untouched', () {
      expect(conditionedWateringInterval(baseDays: 6), 6);
    });

    test('terracotta dries faster, plastic slower', () {
      expect(
        conditionedWateringInterval(
          baseDays: 6,
          material: PotMaterial.terracotta,
        ),
        4,
      );
      expect(
        conditionedWateringInterval(baseDays: 6, material: PotMaterial.plastic),
        7,
      );
      expect(
        conditionedWateringInterval(baseDays: 6, material: PotMaterial.unknown),
        6,
      );
    });

    test('the corrections stack', () {
      // 6 − 2 (terracotta) + 2 (north) − 1 (radiator) + 1 (no drainage) = 6.
      expect(
        conditionedWateringInterval(
          baseDays: 6,
          material: PotMaterial.terracotta,
          placement: Placement.north,
          nearHeatSource: true,
          hasDrainage: false,
        ),
        6,
      );
    });

    test('the result stays inside two weeks and two days', () {
      expect(
        conditionedWateringInterval(
          baseDays: 20,
          material: PotMaterial.plastic,
          placement: Placement.room,
        ),
        kIntervalMaxDays,
      );
      expect(
        conditionedWateringInterval(
          baseDays: 2,
          material: PotMaterial.terracotta,
          placement: Placement.south,
          nearHeatSource: true,
        ),
        kIntervalMinDays,
      );
    });

    test('an unanswered drainage question is not a "no"', () {
      // The difference matters: `null` must not silently add a day the way
      // `false` does, or every pre-quiz plant drifts a day late.
      expect(conditionedWateringInterval(baseDays: 6, hasDrainage: null), 6);
      expect(conditionedWateringInterval(baseDays: 6, hasDrainage: false), 7);
    });
  });

  group('firstWateringInDays', () {
    test('a plant watered today waits a full cycle', () {
      expect(firstWateringInDays(intervalDays: 6, lastWateredDaysAgo: 0), 6);
    });

    test('a plant part-way through its cycle waits out the rest', () {
      expect(firstWateringInDays(intervalDays: 6, lastWateredDaysAgo: 3), 3);
    });

    test('a plant already overdue is watered today', () {
      expect(firstWateringInDays(intervalDays: 6, lastWateredDaysAgo: 7), 0);
    });

    test('"don\'t know" means look at the soil today', () {
      expect(
        firstWateringInDays(
          intervalDays: 6,
          lastWateredDaysAgo: kLastWateredUnknown,
        ),
        0,
      );
    });
  });

  group('lastWateredAnchor', () {
    final now = DateTime(2026, 8, 4, 12);

    test('the anchor sits where the watering actually happened', () {
      expect(lastWateredAnchor(now, 3), DateTime(2026, 8, 1, 12));
    });

    test('"don\'t know" anchors to now rather than inventing a date', () {
      expect(lastWateredAnchor(now, kLastWateredUnknown), now);
    });
  });

  group('conditionTasks', () {
    test('low light is decided by hours, not by a list of places', () {
      // The whole point of the threshold: a bathroom has the same 2–3 hours as
      // a north window and has to earn the same task.
      expect(
        conditionTasks(placement: Placement.bath),
        contains(ConditionTask.light),
      );
      expect(
        conditionTasks(placement: Placement.north),
        contains(ConditionTask.light),
      );
      expect(
        conditionTasks(placement: Placement.south),
        isNot(contains(ConditionTask.light)),
      );
    });

    test('missing drainage and a nearby radiator each add a task', () {
      expect(
        conditionTasks(
          placement: Placement.south,
          hasDrainage: false,
          nearHeatSource: true,
        ),
        [ConditionTask.drainage, ConditionTask.heat],
      );
    });

    test('a plant added before the quiz gets no phantom problems', () {
      expect(conditionTasks(), isEmpty);
    });
  });

  group('startingScore', () {
    test('a clean answer sheet starts at the full score', () {
      expect(startingScore(0), kBaseStartingScore);
    });

    test('each problem costs four points', () {
      expect(startingScore(1), 84);
      expect(startingScore(3), 76);
    });
  });

  group('soilFeel', () {
    test('humid air wins over the pot material', () {
      expect(
        soilFeel(placement: Placement.bath, material: PotMaterial.terracotta),
        SoilFeel.wet,
      );
    });

    test('terracotta reads as moderately damp', () {
      expect(
        soilFeel(placement: Placement.east, material: PotMaterial.terracotta),
        SoilFeel.moderate,
      );
    });

    test('anything else is slightly damp', () {
      expect(
        soilFeel(placement: Placement.east, material: PotMaterial.plastic),
        SoilFeel.slight,
      );
      expect(soilFeel(), SoilFeel.slight);
    });
  });

  test('every placement in the picker has a row in the table', () {
    for (final key in Placement.all) {
      expect(placementFacts(key), isNotNull, reason: '$key is missing');
    }
    expect(kPlacementFacts.length, Placement.all.length);
  });
}
