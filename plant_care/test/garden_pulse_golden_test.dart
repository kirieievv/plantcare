/// Renders the garden pulse to a PNG so its geometry can be eyeballed.
///
/// Run with `flutter test --update-goldens` to refresh the image. Text renders
/// as blocks under the test font — this is here for layout (does the orbit
/// clear the ring, is the core white), not for typography.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/widgets/garden_pulse.dart';
import 'package:plant_care/widgets/task_deck.dart';

Plant _plant(String id, String name) => Plant(
  id: id,
  name: name,
  species: 'Species',
  lastWatered: DateTime(2026, 7, 29),
  nextWatering: DateTime(2026, 8, 3),
  wateringFrequency: 4,
  createdAt: DateTime(2026, 7, 1),
);

void main() {
  testWidgets('garden pulse', (tester) async {
    tester.view.physicalSize = const Size(375, 340);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFEDF0EC),
          body: SizedBox(
            width: 375,
            child: GardenPulse(
              garden: const GardenHealth(
                score: 78,
                weakPlantNames: ['Marigold', 'Lily'],
              ),
              label: 'Garden health',
              caption: '2 plants need your care',
              plants: [
                (plant: _plant('a', 'Marigold'), score: 76, needsWater: true),
                (plant: _plant('b', 'Lily'), score: 71, needsWater: false),
                (plant: _plant('c', 'Pansy'), score: 92, needsWater: false),
              ],
              onOpenPlant: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 950));

    await expectLater(
      find.byType(GardenPulse),
      matchesGoldenFile('goldens/garden_pulse.png'),
    );
  });

  testWidgets('task deck', (tester) async {
    tester.view.physicalSize = const Size(375, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    CareTask task(String id, String title, String detail, TaskCategory c,
            {int overdue = 0}) =>
        CareTask(
          id: id,
          plantId: 'a',
          userId: 'u',
          title: title,
          detail: detail,
          category: c,
          dueAt: DateTime(2026, 8, 1).subtract(Duration(days: overdue)),
        );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: const Color(0xFFEDF0EC),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TaskDeck(
              // Pinned: the card ages against the wall clock otherwise, and the
              // golden would drift by one word every midnight.
              now: DateTime(2026, 8, 4),
              tasks: [
                task('1', 'Полить Marigold', '250 мл · 1 ¼ стакана',
                    TaskCategory.water, overdue: 2),
                task('2', 'Подкормить Lily', 'Половина дозы',
                    TaskCategory.fertilizer),
                task('3', 'Пересканировать Pansy', 'Свежее фото',
                    TaskCategory.scan),
              ],
              onOpen: (_) {},
              onDone: (_) {},
              onLater: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(TaskDeck),
      matchesGoldenFile('goldens/task_deck.png'),
    );
  });

  testWidgets('task deck — nothing left for today', (tester) async {
    tester.view.physicalSize = const Size(375, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: const Color(0xFFEDF0EC),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TaskDeck(
              tasks: const [],
              onOpen: (_) {},
              onDone: (_) {},
              onLater: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TaskDeck),
      matchesGoldenFile('goldens/task_deck_empty.png'),
    );
  });
}
