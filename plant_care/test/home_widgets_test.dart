/// Render checks for the v3 home widgets.
///
/// They pump the real widgets at a phone size and assert what the spec promises
/// on screen. Layout errors (overflow, unbounded constraints) fail the test, so
/// these catch the class of bug that only shows up on a device.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/widgets/garden_pulse.dart';
import 'package:plant_care/widgets/task_deck.dart';
import 'package:plant_care/widgets/task_sheet.dart';
import 'package:plant_care/widgets/todo_block.dart';

// Relative to the clock the widgets themselves read. Pinning this to a date
// made the suite pass on the day it was written and fail the next morning:
// a task "2 days overdue" quietly became three.
final _now = DateTime.now();

Plant _plant({String id = 'p1', String name = 'Lily', int? scanScore = 90}) => Plant(
      id: id,
      name: name,
      species: 'Lilium',
      lastWatered: _now.subtract(const Duration(days: 3)),
      nextWatering: _now.add(const Duration(days: 2)),
      nextDueAt: _now.add(const Duration(days: 2)),
      wateringFrequency: 4,
      createdAt: _now.subtract(const Duration(days: 40)),
      scanScore: scanScore,
    );

CareTask _task({
  String id = 't1',
  String title = 'Подкормить',
  String detail = 'Половина дозы удобрения',
  TaskCategory category = TaskCategory.fertilizer,
  TaskSource source = TaskSource.schedule,
  int overdueDays = 0,
}) =>
    CareTask(
      id: id,
      plantId: 'p1',
      userId: 'u1',
      title: title,
      detail: detail,
      category: category,
      source: source,
      dueAt: _now.subtract(Duration(days: overdueDays)),
      kv: const [
        ['Объём', '250 мл'],
        ['Цикл', 'каждые 4 дня'],
      ],
      body: 'Первый абзац.|Второй абзац.',
    );

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 375, child: child),
        ),
      ),
    );

void main() {
  group('TaskDeck', () {
    testWidgets('shows the top card with its buttons', (tester) async {
      await tester.pumpWidget(_app(TaskDeck(
        tasks: [_task(), _task(id: 't2', title: 'Пересканировать')],
        onOpen: (_) {},
        onDone: (_) {},
        onLater: (_) {},
      )));
      await tester.pump();

      // Scoped to the live card: the backings hold the same content at zero
      // opacity, which is what keeps the deck a stack rather than a strip.
      final live = find.byKey(const ValueKey('deck-live-card'));
      expect(
        find.descendant(of: live, matching: find.text('Подкормить')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: live, matching: find.text('Готово')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: live, matching: find.text('Позже')),
        findsOneWidget,
      );
    });

    testWidgets('an overdue card carries exactly one mark', (tester) async {
      await tester.pumpWidget(_app(TaskDeck(
        tasks: [_task(overdueDays: 2)],
        onOpen: (_) {},
        onDone: (_) {},
        onLater: (_) {},
      )));
      await tester.pump();

      expect(find.text('2 дня'), findsOneWidget);
      expect(find.text('ПО РАСПИСАНИЮ'), findsNothing);
    });

    testWidgets('an empty deck is one line and one sentence', (tester) async {
      await tester.pumpWidget(_app(TaskDeck(
        tasks: const [],
        onOpen: (_) {},
        onDone: (_) {},
        onLater: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Сад в порядке'), findsOneWidget);
      // The caption used to promise the next task "tomorrow morning". Nothing
      // in the app can know that, so the empty state carries no second line at
      // all — this counts every Text inside the deck.
      expect(
        find.descendant(of: find.byType(TaskDeck), matching: find.byType(Text)),
        findsOneWidget,
      );
    });

    testWidgets('the line holds in all six locales', (tester) async {
      for (final code in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(MaterialApp(
          locale: code,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 343, // 375 minus the screen's own 16 px gutters
              child: TaskDeck(
                tasks: const [],
                onOpen: (_) {},
                onDone: (_) {},
                onLater: (_) {},
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final text = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byType(TaskDeck),
            matching: find.byType(Text),
          ),
        );
        // One line, never two — the block is 50 px tall and a second line
        // would spill out of it. Truncation is deliberately not asserted:
        // widget tests draw with a placeholder font whose every glyph is a
        // full em wide, so German "overflows" here and fits on a device.
        expect(
          text.maxLines,
          1,
          reason: 'the empty-state line may wrap in ${code.languageCode}',
        );
        expect(text.text.toPlainText(), isNotEmpty);
      }
    });

    testWidgets('the block collapses from a card to a line', (tester) async {
      Widget deck(List<CareTask> tasks) => _app(TaskDeck(
            tasks: tasks,
            onOpen: (_) {},
            onDone: (_) {},
            onLater: (_) {},
          ));

      await tester.pumpWidget(deck([_task()]));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(TaskDeck)).height, 154); // 150 + 4 gap

      await tester.pumpWidget(deck(const []));
      // Mid-flight: the container is on its way down, not already there. This
      // is the assertion that fails if the height is swapped instead of
      // animated.
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester.getSize(find.byType(TaskDeck)).height;
      expect(mid, lessThan(154));
      expect(mid, greaterThan(50));

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(TaskDeck)).height, 50);
    });

    testWidgets('done fires for the top card only', (tester) async {
      final done = <String>[];
      await tester.pumpWidget(_app(TaskDeck(
        tasks: [_task(), _task(id: 't2', title: 'Пересканировать')],
        onOpen: (_) {},
        onDone: (t) => done.add(t.id),
        onLater: (_) {},
      )));
      await tester.pump();

      await tester.tap(find.descendant(
        of: find.byKey(const ValueKey('deck-live-card')),
        matching: find.text('Готово'),
      ));
      await tester.pumpAndSettle();

      expect(done, ['t1']);
    });
  });

  group('TodoBlock', () {
    testWidgets('lists tasks and the badge', (tester) async {
      await tester.pumpWidget(_app(TodoBlock(
        tasks: [_task(source: TaskSource.analysis)],
        onOpen: (_) {},
        onToggle: (_, __) {},
      )));
      await tester.pump();

      expect(find.text('Подкормить'), findsOneWidget);
      expect(find.text('ПОСЛЕ АНАЛИЗА'), findsOneWidget);
    });

    testWidgets('the scheduled watering chore never appears — the hero widget '
        'above owns it', (tester) async {
      final visible = TodoBlock.visibleTasks(
        [_task(category: TaskCategory.water, title: 'Полить')],
        _now,
      );
      expect(visible, isEmpty);
    });

    testWidgets('the scheduled health check is shown — it is the pair partner',
        (tester) async {
      final visible = TodoBlock.visibleTasks(
        [
          _task(category: TaskCategory.water, title: 'Полить'),
          _task(
            id: 't2',
            category: TaskCategory.scan,
            title: 'Пересканировать',
          ),
        ],
        _now,
      );

      // The watering chore belongs to the hero widget; its health check twin
      // belongs here, and is what the user taps to run the analysis.
      expect(visible, hasLength(1));
      expect(visible.single.category, TaskCategory.scan);
    });

    testWidgets('but watering advice from an analysis stays', (tester) async {
      final visible = TodoBlock.visibleTasks(
        [
          _task(
            category: TaskCategory.water,
            source: TaskSource.analysis,
            title: 'Дать почве просохнуть',
          )
        ],
        _now,
      );
      expect(visible, hasLength(1));
    });

    testWidgets('all closed collapses to the done state', (tester) async {
      await tester.pumpWidget(_app(TodoBlock(
        tasks: [_task()],
        justCompleted: const {'t1'},
        onOpen: (_) {},
        onToggle: (_, __) {},
      )));
      await tester.pump();

      expect(find.text('Всё сделано — растение в порядке'), findsOneWidget);
    });
  });

  group('GardenPulse', () {
    testWidgets('names the plant dragging the garden down', (tester) async {
      await tester.pumpWidget(_app(SizedBox(
        height: 340,
        child: GardenPulse(
          garden: const GardenHealth(score: 74, weakPlantNames: ['Lily']),
          label: 'Здоровье сада',
          caption: 'Lily тянет сад вниз',
          plants: [
            (plant: _plant(), score: 74, needsWater: true),
            (plant: _plant(id: 'p2', name: 'Fern'), score: 92, needsWater: false),
          ],
          onOpenPlant: (_) {},
        ),
      )));
      await tester.pump(const Duration(milliseconds: 950));

      expect(find.text('74'), findsOneWidget);
      expect(find.text('Lily тянет сад вниз'), findsOneWidget);
      expect(find.text('Fern'), findsOneWidget);
    });

    testWidgets('tapping a plant opens it', (tester) async {
      Plant? opened;
      await tester.pumpWidget(_app(SizedBox(
        height: 340,
        child: GardenPulse(
          garden: const GardenHealth(score: 92, weakPlantNames: []),
          label: 'Здоровье сада',
          caption: 'Все растения в порядке',
          plants: [(plant: _plant(), score: 92, needsWater: false)],
          onOpenPlant: (p) => opened = p,
        ),
      )));
      await tester.pump(const Duration(milliseconds: 950));

      // The seat, not its label: the name hangs 17 px above the seat's own box
      // and a Stack does not hit-test what it paints outside its bounds, so the
      // circle is the only live target. See the note in `_SeatFrame`.
      await tester.tap(find.byKey(const ValueKey('orbit-seat-p1')));
      await tester.pump();

      expect(opened?.id, 'p1');
    });
  });

  group('TaskSheet', () {
    testWidgets('shows tiles, body, ask row and both buttons', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TaskSheet(task: _task(), now: _now),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Подкормить'), findsOneWidget);
      expect(find.text('250 мл'), findsOneWidget);
      expect(find.text('Первый абзац.'), findsOneWidget);
      expect(find.text('Спросить ассистента'), findsOneWidget);
      expect(find.text('Готово'), findsOneWidget);
      expect(find.text('Позже'), findsOneWidget);
    });
  });
}
