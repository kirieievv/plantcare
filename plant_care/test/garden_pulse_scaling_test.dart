/// The garden dial under Dynamic Type.
///
/// A circle cannot grow with the system font, so everything inside it is bound
/// by the inscribed square — 148 / √2 ≈ 105 — and the block caps how far the
/// type follows the OS setting. These tests hold both ends of that: nothing
/// overflows and nothing shrinks past the point of being read, in every locale
/// we ship and at every step up to AX5.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/widgets/garden_pulse.dart';

/// The safe square inside the 164 px ring with its 8 px band.
const _coreBox = (164.0 - 16.0) / 1.4142135623730951;

/// Below this the score stops reading as the headline of the block.
const _minScore = 22.0;

/// The cap, times the drawn size.
const _maxScore = 36.0 * 1.15;

final _now = DateTime.now();

Plant _plant(String id, String name) => Plant(
  id: id,
  name: name,
  species: 'Lilium',
  lastWatered: _now.subtract(const Duration(days: 3)),
  nextWatering: _now.add(const Duration(days: 2)),
  nextDueAt: _now.add(const Duration(days: 2)),
  wateringFrequency: 4,
  createdAt: _now.subtract(const Duration(days: 40)),
  scanScore: 90,
);

void main() {
  // iOS steps, as a scale on the default size: Default, xxxLarge, AX3, AX5.
  const scalers = <double>[1.0, 1.35, 1.9, 2.35];

  for (final locale in AppLocalizations.supportedLocales) {
    for (final scale in scalers) {
      testWidgets(
        'dial holds at ${(scale * 100).round()}% in ${locale.languageCode}',
        (tester) async {
          final l10n = await AppLocalizations.delegate.load(locale);

          // The longest verdict there is: the plural branch, in a locale that
          // spells it out. German is the widest of the six.
          final caption = l10n.gardenManyWeak(3);

          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SizedBox(
                    width: 375,
                    child: GardenPulse(
                      garden: const GardenHealth(
                        score: 84,
                        weakPlantNames: ['Marigold', 'Lily', 'Pansy'],
                      ),
                      label: l10n.gardenHealthLabel,
                      caption: caption,
                      plants: [
                        (
                          plant: _plant('a', 'Marigold'),
                          score: 76,
                          needsWater: true,
                        ),
                        (
                          plant: _plant('b', 'Lily'),
                          score: 71,
                          needsWater: false,
                        ),
                      ],
                      onOpenPlant: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          // Past the 900 ms score tween, so the ring has settled.
          await tester.pump(const Duration(milliseconds: 950));

          expect(tester.takeException(), isNull);

          // ── the column stays inside the circle ──────────────────────────
          final column = find
              .ancestor(of: find.text('84'), matching: find.byType(Column))
              .first;
          final columnSize = tester.getSize(column);
          expect(columnSize.width, lessThanOrEqualTo(_coreBox + 0.5));
          expect(columnSize.height, lessThanOrEqualTo(_coreBox + 0.5));

          // ── the score: one line, shrunk but still the headline ──────────
          final score = tester.renderObject<RenderParagraph>(find.text('84'));
          expect(score.maxLines, 1);

          // The score is sized by the layout, not by the OS multiplier, so its
          // style carries the size that is actually drawn.
          final scoreSize = score.text.style!.fontSize!;
          expect(scoreSize, greaterThanOrEqualTo(_minScore));
          expect(scoreSize, lessThanOrEqualTo(_maxScore + 0.01));

          // ── label and verdict: two lines each, no more ──────────────────
          final label = tester.renderObject<RenderParagraph>(
            find.text(l10n.gardenHealthLabel.toUpperCase()),
          );
          expect(label.maxLines, 2);

          final verdict = tester.renderObject<RenderParagraph>(
            find.text(caption),
          );
          expect(verdict.maxLines, 2);
        },
      );
    }
  }

  testWidgets('the OS setting still moves the type below the cap', (
    tester,
  ) async {
    final sizes = <double>[];

    for (final scale in [1.0, 1.1]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SizedBox(
                width: 375,
                child: GardenPulse(
                  garden: const GardenHealth(score: 84, weakPlantNames: []),
                  label: 'Garden health',
                  caption: 'Every plant is fine',
                  plants: [
                    (plant: _plant('a', 'Lily'), score: 90, needsWater: false),
                  ],
                  onOpenPlant: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 950));
      sizes.add(
        tester
            .renderObject<RenderParagraph>(find.text('Every plant is fine'))
            .size
            .height,
      );
    }

    // Capping is not freezing: under 115% the block follows the system size
    // like everything else.
    expect(sizes[1], greaterThan(sizes[0]));
  });
}
