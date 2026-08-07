import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/plant_health.dart';
import 'package:plant_care/models/task.dart';

Plant _plant({
  String id = 'p1',
  String name = 'Lily',
  int? scanScore,
  String? healthStatus,
  DateTime? nextDueAt,
}) {
  final now = DateTime(2026, 8, 1, 12);
  return Plant(
    id: id,
    name: name,
    species: 'Lilium',
    lastWatered: now.subtract(const Duration(days: 4)),
    nextWatering: nextDueAt ?? now.add(const Duration(days: 2)),
    nextDueAt: nextDueAt ?? now.add(const Duration(days: 2)),
    wateringFrequency: 4,
    createdAt: now.subtract(const Duration(days: 30)),
    scanScore: scanScore,
    healthStatus: healthStatus,
  );
}

CareTask _task({
  String plantId = 'p1',
  TaskSource source = TaskSource.analysis,
  TaskCategory category = TaskCategory.other,
  required DateTime dueAt,
  bool done = false,
}) =>
    CareTask(
      id: 't',
      plantId: plantId,
      userId: 'u',
      title: 'Task',
      source: source,
      category: category,
      dueAt: dueAt,
      done: done,
    );

void main() {
  final now = DateTime(2026, 8, 1, 12);

  group('livePlantScore', () {
    test('with nothing wrong the score is the last scan', () {
      expect(livePlantScore(_plant(scanScore: 74), const [], now: now), 74);
    });

    test('closing every task still cannot beat the last scan', () {
      final plant = _plant(scanScore: 74);
      final closed = [
        _task(dueAt: now.subtract(const Duration(days: 5)), done: true),
      ];
      expect(livePlantScore(plant, closed, now: now), 74);
    });

    test('overdue watering costs 10 a day and stops at 30', () {
      final twoDays = _plant(
        scanScore: 90,
        nextDueAt: now.subtract(const Duration(days: 2)),
      );
      expect(livePlantScore(twoDays, const [], now: now), 70);

      final tenDays = _plant(
        scanScore: 90,
        nextDueAt: now.subtract(const Duration(days: 10)),
      );
      expect(livePlantScore(tenDays, const [], now: now), 60);
    });

    test('each open recommendation costs 8', () {
      final plant = _plant(scanScore: 90);
      final tasks = [
        _task(dueAt: now),
        _task(dueAt: now.subtract(const Duration(days: 1))),
      ];
      expect(livePlantScore(plant, tasks, now: now), 74);
    });

    test('scheduled chores are not recommendations', () {
      final plant = _plant(scanScore: 90);
      final tasks = [
        _task(source: TaskSource.schedule, dueAt: now),
      ];
      expect(livePlantScore(plant, tasks, now: now), 90);
    });

    test('a light task is a light deficit once, not a double penalty', () {
      final plant = _plant(scanScore: 90);
      final fresh = [
        _task(category: TaskCategory.light, dueAt: now),
      ];
      // Still young: neither penalty applies to a light row on its first days.
      expect(livePlantScore(plant, fresh, now: now), 90);

      final stale = [
        _task(
          category: TaskCategory.light,
          dueAt: now.subtract(const Duration(days: kLightDeficitDays)),
        ),
      ];
      expect(livePlantScore(plant, stale, now: now), 82);
    });

    test('an open scheduled health check does not move the score', () {
      final plant = _plant(scanScore: 90);
      final scan = [
        _task(
          source: TaskSource.schedule,
          category: TaskCategory.scan,
          dueAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      // Only advice the user has not acted on costs points. A chore the app
      // itself scheduled is not a finding about the plant.
      expect(livePlantScore(plant, scan, now: now), 90);
    });

    test('never leaves 0-100', () {
      final plant = _plant(
        scanScore: 20,
        nextDueAt: now.subtract(const Duration(days: 9)),
      );
      final tasks = List.generate(
        5,
        (_) => _task(dueAt: now.subtract(const Duration(days: 1))),
      );
      expect(livePlantScore(plant, tasks, now: now), 0);
    });

    test('a plant with no scan on record still has a score', () {
      expect(livePlantScore(_plant(), const [], now: now), kLegacyScanScoreOk);
      expect(
        livePlantScore(_plant(healthStatus: 'issue'), const [], now: now),
        kLegacyScanScoreIssue,
      );
    });
  });

  group('gardenHealthOf', () {
    test('averages the plants and names the weak one', () {
      final plants = [
        _plant(id: 'a', name: 'Lily', scanScore: 60),
        _plant(id: 'b', name: 'Fern', scanScore: 100),
      ];
      final garden = gardenHealthOf(plants, const [], now: now);

      expect(garden.score, 80);
      expect(garden.hasWeak, isTrue);
      expect(garden.isSinglePlantToBlame, isTrue);
      expect(garden.weakPlantNames, ['Lily']);
    });

    test('a good average does not hide a weak plant', () {
      final plants = [
        _plant(id: 'a', name: 'Lily', scanScore: 79),
        _plant(id: 'b', name: 'Fern', scanScore: 100),
        _plant(id: 'c', name: 'Ivy', scanScore: 100),
      ];
      expect(gardenHealthOf(plants, const [], now: now).hasWeak, isTrue);
    });

    test('tasks are charged to their own plant', () {
      final plants = [
        _plant(id: 'a', name: 'Lily', scanScore: 90),
        _plant(id: 'b', name: 'Fern', scanScore: 90),
      ];
      final tasks = [_task(plantId: 'a', dueAt: now)];
      final garden = gardenHealthOf(plants, tasks, now: now);

      // Only Lily pays the -8, so the average is (82 + 90) / 2.
      expect(garden.score, 86);
    });
  });
}
