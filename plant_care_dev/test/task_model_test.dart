import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/models/task.dart';

/// Covers the logic half of the SPEC v3 acceptance checklist.
void main() {
  final now = DateTime(2026, 8, 1, 12);

  CareTask task({
    required String id,
    int dueDaysAgo = 0,
    DateTime? postponedAt,
    TaskSource source = TaskSource.schedule,
    bool done = false,
  }) =>
      CareTask(
        id: id,
        plantId: 'p1',
        userId: 'u1',
        title: id,
        source: source,
        dueAt: now.subtract(Duration(days: dueDaysAgo)),
        postponedAt: postponedAt,
        done: done,
      );

  group('score', () {
    test('closed tasks remove penalties but never lift above the last scan', () {
      // Nothing outstanding, yet the plant stays at what the scan said.
      expect(plantScore(scanScore: 74), 74);
    });

    test('overdue watering costs 10 a day, capped at 30', () {
      expect(plantScore(scanScore: 100, overdueWateringDays: 1), 90);
      expect(plantScore(scanScore: 100, overdueWateringDays: 3), 70);
      expect(plantScore(scanScore: 100, overdueWateringDays: 9), 70);
    });

    test('each open recommendation costs 8 and light deficit costs 8', () {
      expect(plantScore(scanScore: 100, openRecommendations: 2), 84);
      expect(plantScore(scanScore: 100, lightDeficit: true), 92);
    });

    test('never leaves 0..100', () {
      expect(plantScore(scanScore: 10, overdueWateringDays: 30), 0);
      expect(plantScore(scanScore: 100), 100);
    });
  });

  group('garden', () {
    test('one weak plant is named and forces the warning state', () {
      final g = GardenHealth.from([
        (name: 'Lily', score: 60),
        (name: 'Basil', score: 96),
        (name: 'Ivy', score: 95),
      ]);
      expect(g.hasWeak, isTrue);
      expect(g.isSinglePlantToBlame, isTrue);
      expect(g.weakPlantNames.single, 'Lily');
      // The average alone would have read as healthy.
      expect(g.score, greaterThan(kHealthWarnThreshold));
    });

    test('all healthy reads clean', () {
      final g = GardenHealth.from([(name: 'Basil', score: 96), (name: 'Ivy', score: 88)]);
      expect(g.hasWeak, isFalse);
      expect(g.score, 92);
    });

    test('no plants does not divide by zero', () {
      expect(GardenHealth.from(const []).score, 100);
    });
  });

  group('ordering', () {
    test('overdue tasks sit above fresh ones', () {
      final sorted = sortTasks([task(id: 'fresh'), task(id: 'old', dueDaysAgo: 3)], now);
      expect(sorted.first.id, 'old');
    });

    test('postponing an overdue task keeps it above fresh ones', () {
      final sorted = sortTasks([
        task(id: 'fresh'),
        task(id: 'old', dueDaysAgo: 3, postponedAt: now),
      ], now);
      expect(sorted.first.id, 'old');
    });

    test('a postponed task goes last within its own group', () {
      final sorted = sortTasks([
        task(id: 'parked', dueDaysAgo: 5, postponedAt: now),
        task(id: 'waiting', dueDaysAgo: 2),
      ], now);
      expect(sorted.map((t) => t.id), ['waiting', 'parked']);
    });

    test('older tasks come first inside a group', () {
      final sorted = sortTasks([
        task(id: 'newer', dueDaysAgo: 1),
        task(id: 'older', dueDaysAgo: 4),
      ], now);
      expect(sorted.map((t) => t.id), ['older', 'newer']);
    });
  });

  group('ordering of a cycle pair', () {
    CareTask pair(String id, TaskCategory category) => CareTask(
          id: id,
          plantId: 'p',
          userId: 'u',
          title: category.name,
          category: category,
          // Watering and its health check are issued together and share a date.
          dueAt: DateTime(2026, 8, 10),
        );

    test('watering sorts above the health check it comes with', () {
      final now = DateTime(2026, 8, 10, 12);
      final sorted = sortTasks(
        [pair('zzz', TaskCategory.scan), pair('aaa', TaskCategory.water)],
        now,
      );

      expect(sorted.first.category, TaskCategory.water);
      expect(sorted.last.category, TaskCategory.scan);
    });

    test('same category and date still has one order, not a coin toss', () {
      final now = DateTime(2026, 8, 10, 12);
      final a = pair('aaa', TaskCategory.fertilizer);
      final b = pair('bbb', TaskCategory.fertilizer);

      // Dart's sort is not stable, so an undefined tie let cards swap places
      // between snapshots for no reason the user could see.
      expect(sortTasks([b, a], now).map((t) => t.id).toList(), ['aaa', 'bbb']);
      expect(sortTasks([a, b], now).map((t) => t.id).toList(), ['aaa', 'bbb']);
    });
  });

  group('age', () {
    test('a recommendation created today is not overdue', () {
      final fresh = task(id: 'rec', source: TaskSource.analysis);
      expect(fresh.ageDaysAt(now), 0);
      expect(fresh.isOverdueAt(now), isFalse);
    });

    test('a task due in the future never reports negative age', () {
      final future = CareTask(
        id: 'later',
        plantId: 'p1',
        userId: 'u1',
        title: 'later',
        dueAt: now.add(const Duration(days: 3)),
      );
      expect(future.ageDaysAt(now), 0);
      expect(future.isActiveAt(now), isFalse);
    });
  });

  group('serialisation', () {
    test('round-trips through a map', () {
      final original = CareTask(
        id: 't1',
        plantId: 'p1',
        userId: 'u1',
        title: 'Подкормить',
        detail: 'половина дозы',
        source: TaskSource.analysis,
        category: TaskCategory.fertilizer,
        dueAt: now,
        postponedAt: now,
        kv: const [
          ['Объём', '250 мл'],
          ['Цикл', 'каждые 4 дня'],
        ],
        body: 'первый абзац|второй абзац',
      );
      final restored = CareTask.fromMap(original.toMap());
      expect(restored.title, original.title);
      expect(restored.source, TaskSource.analysis);
      expect(restored.category, TaskCategory.fertilizer);
      expect(restored.kv.length, 2);
      expect(restored.body, original.body);
      expect(restored.postponedAt, isNotNull);
    });

    test('unknown category and source fall back instead of throwing', () {
      final restored = CareTask.fromMap({
        'id': 't2',
        'dueAt': now.toIso8601String(),
        'category': 'nonsense',
        'source': 'nonsense',
      });
      expect(restored.category, TaskCategory.other);
      expect(restored.source, TaskSource.schedule);
    });

    test('at most three tiles survive', () {
      final restored = CareTask.fromMap({
        'id': 't3',
        'dueAt': now.toIso8601String(),
        'kv': [
          ['a', '1'],
          ['b', '2'],
          ['c', '3'],
          ['d', '4'],
        ],
      });
      expect(restored.kv.length, 3);
    });
  });
}
