/// Care tasks and the health score they feed into.
///
/// Both screens read from here: the plant screen's "what to do" block and the
/// home screen's task deck are two views of the same objects. The rules encoded
/// below come from SPEC v3 part 1 — they are the point of the iteration, so they
/// live in one place rather than being re-derived per screen.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Where a task came from. Drives the single badge a row is allowed to show.
/// Where a task came from, and it decides what may be done to it.
///
/// `schedule` is derived: recomputed from the plant's own numbers whenever they
/// change, so it can be thrown away and rebuilt freely.
///
/// `analysis` is advice a health check gave. It is not derived and must never be
/// swept by a recompute — it carries a health-score penalty while it is open,
/// and clearing it silently hands that penalty back.
///
/// `chat` is a one-off the owner agreed to in conversation: repotting in a
/// fortnight, checking on something after a trip. Rules would never produce it.
enum TaskSource { schedule, analysis, chat }

/// Icon and tint bucket. Kept as a closed set so an unknown value from the
/// analyzer can never reach the UI without a glyph.
enum TaskCategory { water, light, soil, fertilizer, scan, other }

TaskSource _sourceFrom(String? raw) => switch (raw) {
      'analysis' => TaskSource.analysis,
      'chat' => TaskSource.chat,
      _ => TaskSource.schedule,
    };

TaskCategory _categoryFrom(String? raw) => switch (raw) {
      'water' => TaskCategory.water,
      'light' => TaskCategory.light,
      'soil' => TaskCategory.soil,
      'fertilizer' => TaskCategory.fertilizer,
      'scan' => TaskCategory.scan,
      _ => TaskCategory.other,
    };

class CareTask {
  final String id;
  final String plantId;
  final String userId;

  final String title;
  final String detail;
  final TaskSource source;
  final TaskCategory category;

  /// When the task became actionable. Age is measured from here, so a task
  /// created by an analysis today is never overdue (SPEC 1.3.6).
  final DateTime dueAt;

  /// Last time the user pressed "later". Does not remove the task and does not
  /// change the counter — it only reorders within the priority group.
  final DateTime? postponedAt;

  final bool done;
  final DateTime? completedAt;

  /// Up to three [label, value] pairs shown as tiles in the task sheet.
  final List<List<String>> kv;

  /// Explanation body; paragraphs separated by `|`, as the handoff encodes them.
  final String body;

  const CareTask({
    required this.id,
    required this.plantId,
    required this.userId,
    required this.title,
    this.detail = '',
    this.source = TaskSource.schedule,
    this.category = TaskCategory.other,
    required this.dueAt,
    this.postponedAt,
    this.done = false,
    this.completedAt,
    this.kv = const [],
    this.body = '',
  });

  /// Whole days the task has been waiting. 0 means "today"; anything above is
  /// overdue. Never negative — a task scheduled for the future is not yet due
  /// and is filtered out before this matters.
  int ageDaysAt(DateTime now) {
    final due = DateTime(dueAt.year, dueAt.month, dueAt.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(due).inDays;
    return days < 0 ? 0 : days;
  }

  bool isOverdueAt(DateTime now) => ageDaysAt(now) > 0;

  /// Due today or earlier — what the "Today" group and the deck show.
  bool isActiveAt(DateTime now) =>
      !done && !dueAt.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));

  Map<String, dynamic> toMap() => {
        'id': id,
        'plantId': plantId,
        'userId': userId,
        'title': title,
        'detail': detail,
        'source': source.name,
        'category': category.name,
        'dueAt': dueAt.toIso8601String(),
        'postponedAt': postponedAt?.toIso8601String(),
        'done': done,
        'completedAt': completedAt?.toIso8601String(),
        // Never write the raw pairs: Firestore rejects nested arrays and the
        // whole batch fails, which is how the scheduler silently wrote nothing.
        'kv': [
          for (final pair in kv)
            if (pair.length >= 2) {'k': pair[0], 'v': pair[1]},
        ],
        'body': body,
      };

  factory CareTask.fromMap(Map<String, dynamic> map) {
    final due = _parseDate(map['dueAt']);
    if (map['id'] == null || map['id'].toString().isEmpty) {
      throw Exception('CareTask: id is required');
    }
    if (due == null) {
      throw Exception('CareTask: dueAt is required');
    }
    return CareTask(
      id: map['id'].toString(),
      plantId: map['plantId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      detail: map['detail']?.toString() ?? '',
      source: _sourceFrom(map['source']?.toString()),
      category: _categoryFrom(map['category']?.toString()),
      dueAt: due,
      postponedAt: _parseDate(map['postponedAt']),
      done: map['done'] == true,
      completedAt: _parseDate(map['completedAt']),
      kv: _parseKv(map['kv']),
      body: map['body']?.toString() ?? '',
    );
  }

  CareTask copyWith({
    DateTime? dueAt,
    DateTime? postponedAt,
    bool? done,
    DateTime? completedAt,
    bool clearPostponed = false,
  }) =>
      CareTask(
        id: id,
        plantId: plantId,
        userId: userId,
        title: title,
        detail: detail,
        source: source,
        category: category,
        dueAt: dueAt ?? this.dueAt,
        postponedAt: clearPostponed ? null : (postponedAt ?? this.postponedAt),
        done: done ?? this.done,
        completedAt: completedAt ?? this.completedAt,
        kv: kv,
        body: body,
      );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static List<List<String>> _parseKv(dynamic raw) {
    if (raw is! List) return const [];
    final out = <List<String>>[];
    for (final pair in raw) {
      // Firestore rejects nested arrays, so pairs travel as `{k, v}` maps. The
      // list form is still read because it is what older clients wrote.
      if (pair is Map) {
        final k = pair['k'], v = pair['v'];
        if (k != null && v != null) out.add([k.toString(), v.toString()]);
      } else if (pair is List && pair.length >= 2) {
        out.add([pair[0].toString(), pair[1].toString()]);
      }
    }
    // The sheet lays out exactly three tiles; more would overflow the row.
    return out.take(3).toList();
  }
}

/// Ordering used everywhere a task list is shown — the deck, the plant's
/// "what to do" block and the all-tasks screen must agree (SPEC 1.3.2/1.3.4).
///
/// Overdue tasks always sit above fresh ones, so pressing "later" on an overdue
/// task moves it within the overdue group and never below a task from today.
/// Inside a group, a postponed task goes last, then older tasks come first.
int compareTasks(CareTask a, CareTask b, DateTime now) {
  final aOverdue = a.isOverdueAt(now);
  final bOverdue = b.isOverdueAt(now);
  if (aOverdue != bOverdue) return aOverdue ? -1 : 1;

  final aPostponed = a.postponedAt != null;
  final bPostponed = b.postponedAt != null;
  if (aPostponed != bPostponed) return aPostponed ? 1 : -1;
  if (aPostponed && bPostponed) {
    // Both parked: the one parked longest ago comes back first.
    return a.postponedAt!.compareTo(b.postponedAt!);
  }

  final byAge = b.ageDaysAt(now).compareTo(a.ageDaysAt(now));
  if (byAge != 0) return byAge;

  final byDue = a.dueAt.compareTo(b.dueAt);
  if (byDue != 0) return byDue;

  // Watering and its health check are issued together with the same due date,
  // and the user is meant to water first — so the tie is broken by what the
  // sequence demands, not by chance.
  final byCategory = categoryRank(a.category).compareTo(categoryRank(b.category));
  if (byCategory != 0) return byCategory;

  // Last resort, and it has to exist: Dart's sort is not stable, so returning 0
  // here let cards swap places between snapshots for no visible reason.
  return a.id.compareTo(b.id);
}

/// A scheduled health check: run, never ticked.
///
/// Closing it by checkmark would record a check that never happened — the plant
/// keeps its stale score and the scheduler hands the task straight back. It is
/// closed only by the analysis itself, through `completeCategory(scan)`.
bool isScheduledScan(CareTask task) =>
    task.source == TaskSource.schedule && task.category == TaskCategory.scan;

/// Order within one due date: water first, the health check that follows it last.
int categoryRank(TaskCategory category) => switch (category) {
      TaskCategory.water => 0,
      TaskCategory.fertilizer => 1,
      TaskCategory.light => 2,
      TaskCategory.soil => 3,
      TaskCategory.other => 4,
      TaskCategory.scan => 5,
    };

List<CareTask> sortTasks(List<CareTask> tasks, DateTime now) {
  final sorted = [...tasks]..sort((a, b) => compareTasks(a, b, now));
  return sorted;
}

// ─── Health scoring (SPEC 1.1 / 1.2) ─────────────────────────────────────────

/// Below this a plant "needs attention" and the garden ring cannot read green.
const int kHealthWarnThreshold = 80;

/// Penalty caps and rates, straight from SPEC 1.1.
const int _kOverduePerDay = 10;
const int _kOverdueMax = 30;
const int _kOpenRecommendation = 8;
const int _kLightDeficit = 8;

/// Live score for a plant.
///
/// The rule that matters: completing tasks removes penalties but never lifts the
/// score above the last scan. A plant whose last analysis said 74 does not reach
/// 100 by being watered — that needs a new analysis. The previous ring counted
/// closed tasks and therefore lied.
int plantScore({
  required int scanScore,
  int overdueWateringDays = 0,
  int openRecommendations = 0,
  bool lightDeficit = false,
}) {
  final penalties = plantPenalties(
    overdueWateringDays: overdueWateringDays,
    openRecommendations: openRecommendations,
    lightDeficit: lightDeficit,
  );
  final raw = scanScore - penalties;
  return raw.clamp(0, 100);
}

int plantPenalties({
  int overdueWateringDays = 0,
  int openRecommendations = 0,
  bool lightDeficit = false,
}) {
  final overdue =
      (overdueWateringDays.clamp(0, 1 << 30) * _kOverduePerDay).clamp(0, _kOverdueMax);
  final recs = openRecommendations.clamp(0, 1 << 30) * _kOpenRecommendation;
  final light = lightDeficit ? _kLightDeficit : 0;
  return overdue + recs + light;
}

/// Garden ring state: the average, plus who is dragging it down.
///
/// A single weak plant forces the amber state even when the average is high —
/// an average that hides a dying plant is worse than no number at all.
class GardenHealth {
  final int score;
  final List<String> weakPlantNames;

  const GardenHealth({required this.score, required this.weakPlantNames});

  bool get hasWeak => weakPlantNames.isNotEmpty;
  bool get isSinglePlantToBlame => weakPlantNames.length == 1;

  static GardenHealth from(Iterable<({String name, int score})> plants) {
    final list = plants.toList();
    if (list.isEmpty) {
      return const GardenHealth(score: 100, weakPlantNames: []);
    }
    final total = list.fold<int>(0, (sum, p) => sum + p.score);
    final weak = list
        .where((p) => p.score < kHealthWarnThreshold)
        .map((p) => p.name)
        .toList();
    return GardenHealth(
      score: (total / list.length).round(),
      weakPlantNames: weak,
    );
  }
}
