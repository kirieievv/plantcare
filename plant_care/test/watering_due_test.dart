/// The boundaries of "you may water this plant now".
///
/// The card used to answer that question twice: the countdown in whole days,
/// the button in exact instants. Because the stored due date carries a reminder
/// hour of 18:00, the two disagreed from midnight until the evening — the
/// headline read "Now" above a button that would not respond. A few hours of
/// every cycle, which is why it survived months of use and was found by
/// accident.
///
/// These pin the edges directly, since the edges are otherwise only reachable
/// by waiting for the right hour of the right day.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/utils/watering_due.dart';

/// The shape the question is actually asked about: a due date with an hour on
/// it, which is where the whole disagreement came from.
Plant plantDue(DateTime due, {bool shouldWaterNow = false}) {
  return Plant(
    id: 'p',
    name: 'Olive',
    species: 'Salvia rosmarinus',
    lastWatered: due.subtract(const Duration(days: 2)),
    nextWatering: due,
    wateringFrequency: 2,
    createdAt: due.subtract(const Duration(days: 30)),
    nextDueAt: due,
    shouldWaterNow: shouldWaterNow,
  );
}

void main() {
  // Six in the evening: the default reminder hour, and the one the button used
  // to wait for.
  final due = DateTime(2026, 8, 7, 18, 0);

  test('not yet on the evening before', () {
    expect(wateringIsDue(plantDue(due), DateTime(2026, 8, 6, 23, 59)), isFalse);
  });

  test('open from the first minute of the day it is due', () {
    expect(wateringIsDue(plantDue(due), DateTime(2026, 8, 7, 0, 0)), isTrue);
  });

  test('open in the afternoon, before the reminder hour', () {
    // The exact case that was reported: 17:06 against a due time of 18:00.
    expect(wateringIsDue(plantDue(due), DateTime(2026, 8, 7, 17, 6)), isTrue);
  });

  test('still open after the reminder hour', () {
    expect(wateringIsDue(plantDue(due), DateTime(2026, 8, 7, 18, 1)), isTrue);
  });

  test('an overdue plant stays open', () {
    expect(wateringIsDue(plantDue(due), DateTime(2026, 8, 12, 9, 0)), isTrue);
  });

  test('a plant due next week is not', () {
    expect(wateringIsDue(plantDue(due), DateTime(2026, 8, 1, 9, 0)), isFalse);
  });

  test('the analyser flag overrides the date entirely', () {
    // A health check can conclude the soil is dry days before the cycle says
    // so. That is a judgement about the plant and it wins.
    final early = DateTime(2026, 8, 1, 9, 0);
    expect(wateringIsDue(plantDue(due, shouldWaterNow: true), early), isTrue);
  });

  test('falls back to nextWatering when no due date was ever stored', () {
    // Plants added before nextDueAt existed carry only nextWatering, and they
    // are exactly the long-lived ones this was found on.
    final legacy = Plant(
      id: 'p',
      name: 'Olive',
      species: 'Salvia rosmarinus',
      lastWatered: DateTime(2026, 8, 5, 18, 0),
      nextWatering: due,
      wateringFrequency: 2,
      createdAt: DateTime(2026, 3, 1),
    );

    expect(wateringIsDue(legacy, DateTime(2026, 8, 7, 0, 30)), isTrue);
    expect(wateringIsDue(legacy, DateTime(2026, 8, 6, 23, 30)), isFalse);
  });

  test('a due date at midnight does not open the day before', () {
    // Watering moved to "today" by the assistant stores midnight. Comparing
    // whole days must not let that leak backwards into the previous evening.
    final midnight = plantDue(DateTime(2026, 8, 7));
    expect(wateringIsDue(midnight, DateTime(2026, 8, 6, 23, 59)), isFalse);
    expect(wateringIsDue(midnight, DateTime(2026, 8, 7, 0, 0)), isTrue);
  });
}
