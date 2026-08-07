/// Care guidance travels from the analyzer as a structured object, gets
/// flattened into a `Label: value` line per section (see
/// `_composeCareTipsFromCareMap`), and is stored on the plant as a single
/// `aiCareTips` string. This module owns that format: the label vocabulary used
/// to write it and the parser used to read it back.
///
/// Labels are baked in using the language that was active when the plant was
/// created, so the reader matches against *every* supported language rather
/// than the current locale — otherwise switching languages orphans the sections
/// of plants that already exist.
library;

/// Canonical, language-independent section keys.
class CareSection {
  const CareSection._();

  static const cultivar = 'cultivar';
  static const generalDescription = 'generalDescription';
  static const soil = 'soil';
  static const soilMoisture = 'soilMoisture';
  static const moistureCheck = 'moistureCheck';
  static const water = 'water';
  static const light = 'light';
  static const temperature = 'temperature';
  static const fertilizer = 'fertilizer';
  static const growthRate = 'growthRate';
  static const toxicity = 'toxicity';
  static const placement = 'placement';
  static const personality = 'personality';

  /// Write order for [composeCareTips].
  static const all = <String>[
    cultivar,
    generalDescription,
    soil,
    soilMoisture,
    moistureCheck,
    water,
    light,
    temperature,
    fertilizer,
    growthRate,
    toxicity,
    placement,
    personality,
  ];
}

/// Compact labels the analyzer returns alongside the prose sections, under
/// `care_recommendations.details`. These fill the key-value strips in the care
/// sheets and the one-line value on each care row — values the UI used to guess
/// with regexes over prose written in the user's language, which only ever
/// worked in English.
class CareDetail {
  const CareDetail._();

  static const wateringSeason = 'watering_season';
  static const lightHours = 'light_hours';
  static const lightType = 'light_type';
  static const temperatureOptimal = 'temperature_optimal';
  static const temperatureMinimum = 'temperature_minimum';
  static const fertilizerFrequency = 'fertilizer_frequency';
  static const fertilizerDose = 'fertilizer_dose';
  static const soilShort = 'soil_short';
  static const temperatureShort = 'temperature_short';
  static const fertilizerShort = 'fertilizer_short';
  static const placementShort = 'placement_short';

  static const all = <String>[
    wateringSeason,
    lightHours,
    lightType,
    temperatureOptimal,
    temperatureMinimum,
    fertilizerFrequency,
    fertilizerDose,
    soilShort,
    temperatureShort,
    fertilizerShort,
    placementShort,
  ];
}

/// These are labels for narrow cells; the prompt asks for 30 characters. Give
/// the model room to overshoot, but treat a paragraph as a failed instruction
/// and drop it so the UI falls back rather than blowing up its layout.
const _maxDetailLength = 64;

/// Reads `care_recommendations.details` into a clean string map, keeping only
/// keys the UI knows and values that are plausibly labels.
Map<String, String>? extractCareDetails(dynamic careRecommendations) {
  if (careRecommendations is! Map) return null;
  final raw = careRecommendations['details'];
  if (raw is! Map) return null;

  final out = <String, String>{};
  for (final key in CareDetail.all) {
    final value = raw[key];
    if (value == null || value is Map || value is List) continue;
    final s = value.toString().trim();
    if (s.isEmpty || s.length > _maxDetailLength) continue;
    out[key] = s;
  }
  return out.isEmpty ? null : out;
}

/// Section labels used when writing the blob, in [lang].
Map<String, String> careLabelsForLang(String lang) {
  switch (lang) {
    case 'ru':
      return const {
        'cultivar': 'Культивар', 'generalDescription': 'Общее описание',
        'soil': 'Почва', 'soilMoisture': 'Влажность почвы',
        'moistureCheck': 'Проверка влажности', 'water': 'Полив',
        'light': 'Освещение', 'temperature': 'Температура',
        'fertilizer': 'Удобрения', 'growthRate': 'Скорость роста',
        'toxicity': 'Токсичность', 'placement': 'Размещение',
        'personality': 'Характер',
      };
    case 'uk':
      return const {
        'cultivar': 'Культивар', 'generalDescription': 'Загальний опис',
        'soil': 'Ґрунт', 'soilMoisture': 'Вологість ґрунту',
        'moistureCheck': 'Перевірка вологості', 'water': 'Полив',
        'light': 'Освітлення', 'temperature': 'Температура',
        'fertilizer': 'Добрива', 'growthRate': 'Швидкість росту',
        'toxicity': 'Токсичність', 'placement': 'Розміщення',
        'personality': 'Характер',
      };
    case 'de':
      return const {
        'cultivar': 'Kultivar', 'generalDescription': 'Allgemeine Beschreibung',
        'soil': 'Erde', 'soilMoisture': 'Bodenfeuchtigkeit',
        'moistureCheck': 'Feuchtigkeitsprüfung', 'water': 'Wasser',
        'light': 'Licht', 'temperature': 'Temperatur',
        'fertilizer': 'Dünger', 'growthRate': 'Wachstumsrate',
        'toxicity': 'Toxizität', 'placement': 'Standort',
        'personality': 'Charakter',
      };
    case 'es':
      return const {
        'cultivar': 'Cultivar', 'generalDescription': 'Descripción general',
        'soil': 'Suelo', 'soilMoisture': 'Humedad del suelo',
        'moistureCheck': 'Verificación de humedad', 'water': 'Agua',
        'light': 'Luz', 'temperature': 'Temperatura',
        'fertilizer': 'Fertilizante', 'growthRate': 'Tasa de crecimiento',
        'toxicity': 'Toxicidad', 'placement': 'Ubicación',
        'personality': 'Personalidad',
      };
    case 'fr':
      return const {
        'cultivar': 'Cultivar', 'generalDescription': 'Description générale',
        'soil': 'Sol', 'soilMoisture': 'Humidité du sol',
        'moistureCheck': "Vérification de l'humidité", 'water': 'Eau',
        'light': 'Lumière', 'temperature': 'Température',
        'fertilizer': 'Engrais', 'growthRate': 'Taux de croissance',
        'toxicity': 'Toxicité', 'placement': 'Emplacement',
        'personality': 'Personnalité',
      };
    default:
      return const {
        'cultivar': 'Cultivar', 'generalDescription': 'General Description',
        'soil': 'Soil', 'soilMoisture': 'Soil Moisture',
        'moistureCheck': 'Moisture Check', 'water': 'Water',
        'light': 'Light', 'temperature': 'Temperature',
        'fertilizer': 'Fertilizer', 'growthRate': 'Growth Rate',
        'toxicity': 'Toxicity', 'placement': 'Placement',
        'personality': 'Personality',
      };
  }
}

/// Every label the writer has ever emitted, in any supported language, mapped
/// to its canonical key. Includes the analyzer's own English spellings, which
/// differ slightly from the app's (`Moisture` vs `Soil Moisture`).
const _labelToKey = <String, String>{
  // English (app + analyzer)
  'cultivar': CareSection.cultivar,
  'name': CareSection.cultivar,
  'general description': CareSection.generalDescription,
  'soil': CareSection.soil,
  'soil moisture': CareSection.soilMoisture,
  'moisture': CareSection.soilMoisture,
  'moisture check': CareSection.moistureCheck,
  'water': CareSection.water,
  'watering': CareSection.water,
  'light': CareSection.light,
  'temperature': CareSection.temperature,
  'fertilizer': CareSection.fertilizer,
  'growth rate': CareSection.growthRate,
  'growth': CareSection.growthRate,
  'toxicity': CareSection.toxicity,
  'placement': CareSection.placement,
  'personality': CareSection.personality,
  // Russian
  'культивар': CareSection.cultivar,
  'общее описание': CareSection.generalDescription,
  'почва': CareSection.soil,
  'влажность почвы': CareSection.soilMoisture,
  'проверка влажности': CareSection.moistureCheck,
  'полив': CareSection.water,
  'освещение': CareSection.light,
  'температура': CareSection.temperature,
  'удобрения': CareSection.fertilizer,
  'скорость роста': CareSection.growthRate,
  'токсичность': CareSection.toxicity,
  'размещение': CareSection.placement,
  'характер': CareSection.personality,
  // Ukrainian
  'загальний опис': CareSection.generalDescription,
  'ґрунт': CareSection.soil,
  'вологість ґрунту': CareSection.soilMoisture,
  'перевірка вологості': CareSection.moistureCheck,
  'освітлення': CareSection.light,
  'добрива': CareSection.fertilizer,
  'швидкість росту': CareSection.growthRate,
  'токсичність': CareSection.toxicity,
  'розміщення': CareSection.placement,
  // German
  'kultivar': CareSection.cultivar,
  'allgemeine beschreibung': CareSection.generalDescription,
  'erde': CareSection.soil,
  'bodenfeuchtigkeit': CareSection.soilMoisture,
  'feuchtigkeitsprüfung': CareSection.moistureCheck,
  'wasser': CareSection.water,
  'licht': CareSection.light,
  'temperatur': CareSection.temperature,
  'dünger': CareSection.fertilizer,
  'wachstumsrate': CareSection.growthRate,
  'toxizität': CareSection.toxicity,
  'standort': CareSection.placement,
  'charakter': CareSection.personality,
  // Spanish
  'descripción general': CareSection.generalDescription,
  'suelo': CareSection.soil,
  'humedad del suelo': CareSection.soilMoisture,
  'verificación de humedad': CareSection.moistureCheck,
  'agua': CareSection.water,
  'luz': CareSection.light,
  'temperatura': CareSection.temperature,
  'fertilizante': CareSection.fertilizer,
  'tasa de crecimiento': CareSection.growthRate,
  'toxicidad': CareSection.toxicity,
  'ubicación': CareSection.placement,
  'personalidad': CareSection.personality,
  // French
  'description générale': CareSection.generalDescription,
  'sol': CareSection.soil,
  'humidité du sol': CareSection.soilMoisture,
  "vérification de l'humidité": CareSection.moistureCheck,
  'eau': CareSection.water,
  'lumière': CareSection.light,
  'température': CareSection.temperature,
  'engrais': CareSection.fertilizer,
  'taux de croissance': CareSection.growthRate,
  'toxicité': CareSection.toxicity,
  'emplacement': CareSection.placement,
  'personnalité': CareSection.personality,
};

/// Resolves one written label to its canonical key, or null if unrecognised.
String? careLabelToKey(String raw) =>
    _labelToKey[_normalizeLabel(raw)];

/// Longest real label is ~26 chars; anything longer is prose, not a heading.
const _maxLabelLength = 40;

final _labelNoise = RegExp(r'^[\s>#*_\-•–—]+|[\s*_:]+$');

/// A bold label writes its closing `**` after the colon, so the body inherits it.
final _leadingEmphasis = RegExp(r'^[\s*_]+');

String _normalizeLabel(String raw) =>
    raw.replaceAll(_labelNoise, '').toLowerCase().trim();

/// Splits [blob] into canonical sections.
///
/// Recognises both shapes the writers produce: `Label: body` on a single line,
/// and a bare `Label` heading followed by its body. Unlabelled lines continue
/// the section above them, so multi-paragraph bodies survive intact. A section
/// ends where the next recognised label begins — nothing bleeds across.
Map<String, String> parseCareSections(String? blob) {
  if (blob == null || blob.trim().isEmpty) return const {};

  final buffers = <String, List<String>>{};
  String? current;

  void append(String text) {
    final section = current;
    if (section == null) return;
    buffers.putIfAbsent(section, () => <String>[]).add(text);
  }

  for (final rawLine in blob.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      append('');
      continue;
    }

    final colon = line.indexOf(':');
    String? key;
    String remainder = '';

    if (colon > 0 && colon <= _maxLabelLength) {
      key = careLabelToKey(line.substring(0, colon));
      if (key != null) {
        remainder =
            line.substring(colon + 1).replaceFirst(_leadingEmphasis, '').trim();
      }
    }
    // Markdown-style heading on its own line, body follows.
    if (key == null && line.length <= _maxLabelLength) {
      key = careLabelToKey(line);
    }

    if (key != null) {
      current = key;
      buffers.putIfAbsent(key, () => <String>[]);
      if (remainder.isNotEmpty) append(remainder);
    } else {
      append(line);
    }
  }

  final out = <String, String>{};
  buffers.forEach((key, lines) {
    final body = lines.join('\n').trim();
    if (body.isNotEmpty) out[key] = body;
  });
  return out;
}

/// Writes [sections] back out in [lang], mirroring the format [parseCareSections]
/// reads. Keys absent from [sections] are skipped.
String? composeCareTips(Map<String, String?> sections, String lang) {
  final labels = careLabelsForLang(lang);
  final lines = <String>[];
  for (final key in CareSection.all) {
    final value = sections[key]?.trim();
    if (value == null || value.isEmpty) continue;
    lines.add('${labels[key]}: $value');
  }
  return lines.isEmpty ? null : lines.join('\n');
}
