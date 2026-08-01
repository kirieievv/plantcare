import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care/utils/care_sections.dart';

void main() {
  test('parses the label-per-line blob the app writes', () {
    final s = parseCareSections('''
Cultivar: Rosmarinus officinalis 'Tuscan Blue'
General Description: An upright evergreen shrub with needle-like leaves.
Soil: Fast-draining sandy or gritty mix, pH 6.0-7.5.
Soil Moisture: Let the top 3-4 cm dry out between waterings.
Moisture Check: Insert your finger about 2-3 cm into the soil: water only if it feels dry.
Water: Use room-temperature water and irrigate thoroughly until it drains.
Light: Bright direct sun, 6+ hours daily.
Temperature: 15-24 C is ideal; protect below 5 C.
Fertilizer: Balanced liquid feed monthly in spring and summer.
Growth Rate: Moderate, 20-30 cm per season.
Toxicity: Non-toxic to cats and dogs.
Placement: A south-facing windowsill with good airflow.
Personality: Tolerant of neglect, resents wet feet.
''');

    expect(s[CareSection.cultivar], "Rosmarinus officinalis 'Tuscan Blue'");
    expect(s[CareSection.soil], 'Fast-draining sandy or gritty mix, pH 6.0-7.5.');
    expect(s[CareSection.soilMoisture],
        'Let the top 3-4 cm dry out between waterings.');
    // The label must not bleed into the neighbouring section.
    expect(s[CareSection.moistureCheck], startsWith('Insert your finger'));
    expect(s[CareSection.moistureCheck], contains('water only if it feels dry'));
    expect(s[CareSection.temperature], '15-24 C is ideal; protect below 5 C.');
    expect(s[CareSection.light], 'Bright direct sun, 6+ hours daily.');
    expect(s[CareSection.placement], 'A south-facing windowsill with good airflow.');
    expect(s.length, 13);
  });

  test('matches labels of any language, not just the current locale', () {
    final ru = parseCareSections(
        'Полив: Раз в неделю.\nОсвещение: Яркий рассеянный свет.');
    expect(ru[CareSection.water], 'Раз в неделю.');
    expect(ru[CareSection.light], 'Яркий рассеянный свет.');

    final de = parseCareSections('Wasser: Einmal pro Woche.\nErde: Kakteenerde.');
    expect(de[CareSection.water], 'Einmal pro Woche.');
    expect(de[CareSection.soil], 'Kakteenerde.');

    final fr = parseCareSections('Température: 15-24 C.\nEmplacement: Sud.');
    expect(fr[CareSection.temperature], '15-24 C.');
    expect(fr[CareSection.placement], 'Sud.');

    final es = parseCareSections('Temperatura: 15-24 C.\nLuz: Sol directo.');
    expect(es[CareSection.temperature], '15-24 C.');
    expect(es[CareSection.light], 'Sol directo.');
  });

  test('keeps multi-line bodies with the section that owns them', () {
    final s = parseCareSections('''
Water: Soak thoroughly.
Discard anything left in the saucer after 15 minutes.

Note that tap water is fine here.
Light: Bright, indirect.
''');
    expect(s[CareSection.water], contains('Discard anything left'));
    expect(s[CareSection.water], contains('tap water is fine'));
    expect(s[CareSection.light], 'Bright, indirect.');
  });

  test('reads markdown headings and the analyzer spellings', () {
    final s = parseCareSections('''
## Watering
Once a week.
**Moisture:** Keep evenly damp.
''');
    expect(s[CareSection.water], 'Once a week.');
    expect(s[CareSection.soilMoisture], 'Keep evenly damp.');
  });

  test('ignores colons inside prose', () {
    final s = parseCareSections(
        'Water: Once a week.\nRemember: never let it sit in water.');
    expect(s[CareSection.water],
        'Once a week.\nRemember: never let it sit in water.');
    expect(s.length, 1);
  });

  test('round-trips through the writer', () {
    const sections = {
      CareSection.water: 'Once a week.',
      CareSection.light: 'Bright, indirect.',
      CareSection.toxicity: null,
    };
    for (final lang in ['en', 'ru', 'uk', 'de', 'es', 'fr']) {
      final blob = composeCareTips(sections, lang);
      final back = parseCareSections(blob);
      expect(back[CareSection.water], 'Once a week.', reason: lang);
      expect(back[CareSection.light], 'Bright, indirect.', reason: lang);
      expect(back.containsKey(CareSection.toxicity), isFalse, reason: lang);
    }
  });

  test('every label of every language resolves back to its key', () {
    for (final lang in ['en', 'ru', 'uk', 'de', 'es', 'fr']) {
      careLabelsForLang(lang).forEach((key, label) {
        expect(careLabelToKey(label), key, reason: '$lang / $label');
      });
    }
  });

  test('returns empty for missing or blank input', () {
    expect(parseCareSections(null), isEmpty);
    expect(parseCareSections('   \n  '), isEmpty);
  });

  group('extractCareDetails', () {
    test('reads the labels the analyzer nests under care_recommendations', () {
      final d = extractCareDetails({
        'water': 'Water thoroughly until it drains.',
        'details': {
          'watering_season': 'spring-summer',
          'light_hours': '4-6',
          'light_type': 'bright indirect',
          'temperature_optimal': '18-26 °C',
          'temperature_minimum': '10-12 °C',
          'fertilizer_frequency': 'every 2 weeks',
          'fertilizer_dose': 'half strength',
          'soil_short': 'Loose, well-drained',
          'temperature_short': '18-26 °C',
          'fertilizer_short': 'Every 2 weeks',
          'placement_short': 'South-facing sill',
        },
      });

      expect(d, isNotNull);
      expect(d![CareDetail.wateringSeason], 'spring-summer');
      expect(d[CareDetail.lightHours], '4-6');
      expect(d[CareDetail.temperatureMinimum], '10-12 °C');
      expect(d[CareDetail.placementShort], 'South-facing sill');
      expect(d.length, CareDetail.all.length);
      // Prose siblings must not leak into the label map.
      expect(d.containsKey('water'), isFalse);
    });

    test('drops blanks, unknown keys and paragraphs', () {
      final d = extractCareDetails({
        'details': {
          'light_type': 'bright indirect',
          'watering_season': '   ',
          'made_up_key': 'value',
          // A label cell cannot hold a sentence; better to fall back.
          'soil_short': 'A loose, free-draining mix of universal soil with '
              'perlite and a little compost, in a pot with drainage holes.',
        },
      });

      expect(d, {CareDetail.lightType: 'bright indirect'});
    });

    test('returns null when the analyzer sent nothing usable', () {
      expect(extractCareDetails(null), isNull);
      expect(extractCareDetails('not a map'), isNull);
      expect(extractCareDetails({'water': 'text'}), isNull);
      expect(extractCareDetails({'details': {}}), isNull);
      expect(extractCareDetails({'details': 'oops'}), isNull);
    });
  });
}
