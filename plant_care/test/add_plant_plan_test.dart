/// The care plan the user accepts on the last step of the add-plant flow.
///
/// The "First watering" line used to say "today" unconditionally — copied
/// straight from the mockup, where it was demo text. Since the conditions quiz
/// it is computed from the answers, so these pin the line to the same
/// arithmetic the plant is saved with.
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
    test('a plant already due is watered today, dose and all', () {
      expect(
        firstWateringDetail(
          ru,
          ml: 250,
          firstInDays: 0,
          unknownLastWatering: false,
        ),
        '250 мл · 1 ¼ стакана · сегодня',
      );
    });

    test('a plant on schedule names the day the plan picked', () {
      final line = firstWateringDetail(
        ru,
        ml: 250,
        firstInDays: 10,
        unknownLastWatering: false,
      );

      expect(line, '250 мл · 1 ¼ стакана · через 10 дней');
      // The bug in one assertion: this used to end in "сегодня".
      expect(line.contains('сегодня'), isFalse);
    });

    test('"don\'t know" promises a check, not a date', () {
      expect(
        firstWateringDetail(
          ru,
          ml: 250,
          firstInDays: 0,
          unknownLastWatering: true,
        ),
        '250 мл · 1 ¼ стакана · проверим сегодня',
      );
    });

    test('a zero dose leaves just the day', () {
      expect(
        firstWateringDetail(
          ru,
          ml: 0,
          firstInDays: 4,
          unknownLastWatering: false,
        ),
        'через 4 дня',
      );
    });

    test('above a litre the glasses are dropped', () {
      final line = firstWateringDetail(
        ru,
        ml: 2600,
        firstInDays: 3,
        unknownLastWatering: false,
      );
      expect(line, '2,6 л · через 3 дня');
      expect(line.contains('стакан'), isFalse);
    });

    test('English keeps the same shape', () {
      expect(
        firstWateringDetail(
          en,
          ml: 250,
          firstInDays: 10,
          unknownLastWatering: false,
        ),
        '250 ml · 1 ¼ glasses · in 10 days',
      );
    });
  });

  group('volumeLabel', () {
    test('millilitres below a litre', () {
      expect(volumeLabel(ru, 400), '400 мл');
      expect(volumeLabel(en, 950), '950 ml');
    });

    test('litres above it, in the locale\'s own decimal mark', () {
      expect(volumeLabel(ru, 2600), '2,6 л');
      expect(volumeLabel(en, 2600), '2.6 l');
    });

    test('a round litre does not print a trailing zero', () {
      expect(volumeLabel(en, 2000), '2 l');
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

  group('accentSpans', () {
    test('the highlighted word lands where the translation put it', () {
      // Russian keeps it mid-sentence, German puts it first — the same helper
      // has to serve both without either locale hard-coding a position.
      final spans = accentSpans(ru.quizPotQuestion, ru.quizPotQuestionAccent);
      expect(spans.map((s) => (s as TextSpan).text).join(), 'Какого диаметра горшок?');
      expect((spans[1] as TextSpan).text, 'диаметра');
    });

    test('an accent at the end of the string leaves no empty tail', () {
      final spans = accentSpans(
        en.addPlantHeaderPhoto,
        en.addPlantHeaderPhotoAccent,
      );
      expect(spans.map((s) => (s as TextSpan).text).join(), 'Add a plant');
    });
  });
}
