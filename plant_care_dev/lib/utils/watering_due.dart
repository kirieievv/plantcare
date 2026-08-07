/// When watering a plant becomes available.
///
/// The stored due date is a timestamp, and has to be: the watering reminder
/// hangs off it, and a notification needs an hour. The default is six in the
/// evening.
///
/// That hour is right for a reminder and wrong for a button. A person waters
/// when they are home holding the watering can, not at 18:00 — so the card
/// asked the same date two questions and got two answers. The countdown, which
/// works in whole days, had nothing left to count from midnight and the
/// headline read "Now"; the button compared instants and stayed dead until the
/// evening. The plant said it was thirsty and offered no way to say you had
/// done something about it, for a few hours of every cycle.
///
/// One question, one answer, in whole days — the granularity the countdown and
/// the home rows already used. The reminder keeps its hour; the button opens
/// when the day does.
library;

import 'package:plant_care/models/plant.dart';

/// Midnight of the day [at] falls on, in local time.
DateTime startOfDay(DateTime at) => DateTime(at.year, at.month, at.day);

/// Whether [plant] may be watered as of [now].
///
/// [now] is passed in rather than read from the clock, so the boundaries can be
/// asked about directly instead of only being reachable for the few hours a day
/// they actually occur.
bool wateringIsDue(Plant plant, DateTime now) {
  // Set when the analyser or the assistant concludes the plant needs water
  // whatever the cycle says. It wins outright: that is a judgement about this
  // plant, not arithmetic on a date.
  if (plant.shouldWaterNow) return true;

  final due = plant.nextDueAt ?? plant.nextWatering;
  return !startOfDay(due).isAfter(startOfDay(now));
}
