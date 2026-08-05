/// Live health score for a plant (SPEC 1.1).
///
/// The number shown anywhere in the app comes from here. It is deliberately not
/// stored: `scanScore` is the fact on record, everything else is how the plant
/// is doing against it right now, and a stored copy would drift the moment a
/// task went overdue.
library;

import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/task.dart';

/// Used when a plant predates scoring and has no analysis on record.
///
/// Not a neutral 100: SPEC 1.1 forbids "no data", and a plant nobody has looked
/// at has not earned a perfect score. The split follows the last check's verdict.
const int kLegacyScanScoreOk = 88;
const int kLegacyScanScoreIssue = 65;

/// How long a light task has to sit before it counts as a light deficit rather
/// than a chore. SPEC says "N days in a row" without fixing N; three days is the
/// point at which the analyzer's own re-check window has passed.
const int kLightDeficitDays = 3;

int scanScoreOf(Plant plant) =>
    plant.scanScore ??
    (plant.healthStatus == 'issue' ? kLegacyScanScoreIssue : kLegacyScanScoreOk);

/// Whole days the watering is late. Zero when it is due today or later.
int overdueWateringDaysOf(Plant plant, DateTime now) {
  final due = plant.nextDueAt ?? plant.nextWatering;
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(due.year, due.month, due.day))
      .inDays;
  return days < 0 ? 0 : days;
}

/// Score for one plant given its still-open tasks.
///
/// [openTasks] should be the plant's own undone tasks. Light is pulled out of
/// the recommendation count on purpose: SPEC lists "unfinished recommendation"
/// and "light deficit" as two separate penalties, and charging both for the same
/// row would punish it twice.
int livePlantScore(Plant plant, Iterable<CareTask> openTasks, {DateTime? now}) {
  final at = now ?? DateTime.now();
  final open = openTasks.where((t) => !t.done).toList();

  final lightTasks = open.where((t) => t.category == TaskCategory.light);
  final recommendations = open
      .where((t) => t.source == TaskSource.analysis)
      .where((t) => t.category != TaskCategory.light)
      .length;

  return plantScore(
    scanScore: scanScoreOf(plant),
    overdueWateringDays: overdueWateringDaysOf(plant, at),
    openRecommendations: recommendations,
    lightDeficit:
        lightTasks.any((t) => t.ageDaysAt(at) >= kLightDeficitDays),
  );
}

bool plantNeedsAttention(int score) => score < kHealthWarnThreshold;

/// Garden ring state across plants, each with its own open tasks.
GardenHealth gardenHealthOf(
  Iterable<Plant> plants,
  List<CareTask> allOpenTasks, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  return GardenHealth.from(plants.map((p) => (
        name: p.name,
        score: livePlantScore(
          p,
          allOpenTasks.where((t) => t.plantId == p.id),
          now: at,
        ),
      )));
}
