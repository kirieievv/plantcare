/// Growing conditions and what they do to a care plan (SPEC §1, §4).
///
/// Everything here is deliberately free of Flutter and of localisation: the
/// numbers are the same in every language, and the only thing the UI adds is
/// wording. That is also what makes the plan testable — the arithmetic behind
/// "water 400 ml every 5 days" is a pure function of six answers.
library;

import 'dart:math' as math;

/// Pot material, as stored in `Plant.potMaterial`.
///
/// 'unknown' is a real answer, not a refusal: the user is telling us to fall
/// back to the species average, and that is different from never having asked.
abstract final class PotMaterial {
  static const plastic = 'plastic';
  static const ceramic = 'ceramic';
  static const terracotta = 'terracotta';
  static const unknown = 'unknown';

  static const all = [plastic, ceramic, terracotta, unknown];
}

/// Where the plant stands, as stored in `Plant.placement`.
abstract final class Placement {
  static const south = 'south';
  static const east = 'east';
  static const north = 'north';
  static const room = 'room';
  static const balcony = 'balcony';
  static const bath = 'bath';

  static const all = [south, east, north, room, balcony, bath];
}

/// What a placement means in numbers.
///
/// One table, on purpose (SPEC 3.4). The alternative — a chain of `if`s spread
/// across the screen, the planner and the task builder — is how the light label
/// and the "needs more light" task end up disagreeing about the same window.
class PlacementFacts {
  /// Hours of usable light per day. Drives both the label and the light task.
  final double lightHours;

  /// Days added to the watering interval. Negative means "dries out faster".
  final int dryOffset;

  /// Humid air — a bathroom keeps the soil damp for longer than its light
  /// hours alone would suggest.
  final bool wetAir;

  const PlacementFacts({
    required this.lightHours,
    required this.dryOffset,
    required this.wetAir,
  });
}

const kPlacementFacts = <String, PlacementFacts>{
  Placement.south: PlacementFacts(
    lightHours: 7.0,
    dryOffset: -1,
    wetAir: false,
  ),
  Placement.east: PlacementFacts(lightHours: 5.0, dryOffset: 0, wetAir: false),
  Placement.north: PlacementFacts(lightHours: 2.5, dryOffset: 2, wetAir: false),
  Placement.room: PlacementFacts(lightHours: 1.5, dryOffset: 2, wetAir: false),
  Placement.balcony: PlacementFacts(
    lightHours: 7.5,
    dryOffset: -1,
    wetAir: false,
  ),
  Placement.bath: PlacementFacts(lightHours: 2.5, dryOffset: 1, wetAir: true),
};

/// Facts for [key], or null when the plant was added before the quiz existed.
PlacementFacts? placementFacts(String? key) => kPlacementFacts[key];

/// Pot diameter bounds — the slider's range and the clamp every reader applies.
const kPotMinCm = 8;
const kPotMaxCm = 40;
const kPotDefaultCm = 16;

/// Watering interval bounds. Two days is as often as any houseplant needs it;
/// past a fortnight the reminder stops being a habit.
const kIntervalMinDays = 2;
const kIntervalMaxDays = 14;

/// Below this many hours of light a day, the plant gets a "more light" task.
///
/// A threshold rather than a list of places (SPEC 3.4): the bathroom has the
/// same 2–3 hours as a north window and has to earn the same task.
const kLowLightHours = 4.0;

/// A plant starts at 88 and loses 4 points per problem the quiz uncovered.
const kBaseStartingScore = 88;
const kScorePenaltyPerProblem = 4;

/// One glass, in millilitres — the unit people actually pour with.
const kGlassMl = 200;

/// Above this, glasses stop helping: "13 glasses" is not a measurement.
const kLitreThresholdMl = 1000;

/// Water per watering for a pot [diameterCm] across, in millilitres.
///
/// Soil volume is a cylinder whose height is about 0.8 of its diameter; a
/// watering wets roughly 15% of it. Rounded to 50 ml because nobody pours 437.
int wateringMlForPot(int diameterCm) {
  final d = diameterCm.clamp(kPotMinCm, kPotMaxCm).toDouble();
  final soilMl = math.pi * math.pow(d / 2, 2) * (d * 0.8);
  return (soilMl * 0.15 / 50).round() * 50;
}

/// The watering interval for this plant in these conditions.
///
/// [baseDays] is the species figure from the analyzer — the conditions only
/// bend it. Any answer left null contributes nothing, so a plant added before
/// the quiz keeps exactly the interval the AI gave it.
int conditionedWateringInterval({
  required int baseDays,
  String? material,
  String? placement,
  bool? nearHeatSource,
  bool? hasDrainage,
}) {
  var days = baseDays;
  if (material == PotMaterial.terracotta) days -= 2;
  if (material == PotMaterial.plastic) days += 1;
  days += placementFacts(placement)?.dryOffset ?? 0;
  if (nearHeatSource == true) days -= 1;
  // No drainage: water sits at the roots, so it goes in less often.
  if (hasDrainage == false) days += 1;
  return days.clamp(kIntervalMinDays, kIntervalMaxDays);
}

/// "Don't know" for the last-watering question.
const kLastWateredUnknown = -1;

/// Days until the first watering is due.
///
/// The whole point of asking when the plant was last watered (SPEC 1.2): a
/// plant watered this morning must not get a task for this evening, and one
/// last watered a week ago must not wait another full cycle.
int firstWateringInDays({
  required int intervalDays,
  required int lastWateredDaysAgo,
}) {
  // Unknown — check the soil today rather than guess a date.
  if (lastWateredDaysAgo < 0) return 0;
  if (lastWateredDaysAgo >= intervalDays) return 0;
  return intervalDays - lastWateredDaysAgo;
}

/// The cycle anchor to store in `lastWatered` / `lastWateredAt`.
///
/// "Don't know" anchors to now: it is the only honest answer, and the first
/// task is a soil check anyway.
DateTime lastWateredAnchor(DateTime now, int lastWateredDaysAgo) =>
    lastWateredDaysAgo < 0
    ? now
    : now.subtract(Duration(days: lastWateredDaysAgo));

/// A starting task the conditions earned, on top of the three every plant gets.
enum ConditionTask { light, drainage, heat }

/// Which extra starting tasks these conditions call for (SPEC 4.3).
List<ConditionTask> conditionTasks({
  String? placement,
  bool? hasDrainage,
  bool? nearHeatSource,
}) {
  final facts = placementFacts(placement);
  return [
    if (facts != null && facts.lightHours < kLowLightHours) ConditionTask.light,
    if (hasDrainage == false) ConditionTask.drainage,
    if (nearHeatSource == true) ConditionTask.heat,
  ];
}

/// The starting health score for a plant with [problemCount] problem tasks.
int startingScore(int problemCount) =>
    (kBaseStartingScore - problemCount * kScorePenaltyPerProblem).clamp(0, 100);

/// How the soil should feel — words, not percentages (SPEC 4.5).
enum SoilFeel { wet, moderate, slight }

SoilFeel soilFeel({String? placement, String? material}) {
  if (placementFacts(placement)?.wetAir == true) return SoilFeel.wet;
  if (material == PotMaterial.terracotta) return SoilFeel.moderate;
  return SoilFeel.slight;
}
