/// The "First watering" line in the care plan the user accepts.
///
/// It used to say "today" unconditionally — copied straight from the mockup,
/// where it was demo text. The row then contradicted the watering tile two rows
/// above it, and contradicted the plant screen a second later. These pin the
/// line to the analyzer's own `should_water_now`.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/screens/add_plant_screen_v4.dart';

void main() {
  late AppLocalizations ru;
  late AppLocalizations en;

  setUpAll(() async {
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('firstWateringDetail', () {
    test('a thirsty plant is watered today, dose and all', () {
      expect(
        firstWateringDetail(ru, ml: 250, waterNow: true, intervalDays: 10),
        '250 МЛ · 1 ¼ стакана · сегодня',
      );
    });

    test('a plant on schedule names the day the analyzer picked', () {
      final line =
          firstWateringDetail(ru, ml: 250, waterNow: false, intervalDays: 10);

      expect(line, '250 МЛ · 1 ¼ стакана · через 10 дней');
      // The bug in one assertion: this used to end in "сегодня".
      expect(line.contains('сегодня'), isFalse);
    });

    test('without a dose the line is just the day', () {
      expect(
        firstWateringDetail(ru, ml: null, waterNow: true, intervalDays: 10),
        'сегодня',
      );
      expect(
        firstWateringDetail(ru, ml: null, waterNow: false, intervalDays: 10),
        'Через 10 дней',
      );
    });

    test('a zero dose is treated as no dose, not as "0 ml"', () {
      expect(
        firstWateringDetail(ru, ml: 0, waterNow: false, intervalDays: 4),
        'Через 4 дня',
      );
    });

    test('English keeps the same shape', () {
      expect(
        firstWateringDetail(en, ml: 250, waterNow: false, intervalDays: 10),
        '250 ML · 1 ¼ glasses · in 10 days',
      );
      expect(
        firstWateringDetail(en, ml: null, waterNow: false, intervalDays: 1),
        'In 1 day',
      );
    });
  });

  group('glassesLabel', () {
    test('a single glass is not "1 glasses"', () {
      expect(glassesLabel(ru, 200), '1 стакан');
      expect(glassesLabel(en, 200), '1 glass');
    });

    test('quarters are rounded to the nearest pourable amount', () {
      expect(glassesLabel(en, 250), '1 ¼ glasses');
      expect(glassesLabel(en, 400), '2 glasses');
      expect(glassesLabel(en, 50), '¼ glasses');
    });
  });
}
