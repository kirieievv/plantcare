/**
 * The care plan, as the server reads it.
 *
 * A plant's care guidance is stored as one flat `aiCareTips` string: a
 * `Label: body` line per section, written in whatever language was active when
 * the plant was added. The app owns the same format in lib/utils/care_sections.dart
 * — this is the reader half of it, ported so the assistant can quote the exact
 * paragraph the user is looking at instead of paraphrasing from memory.
 *
 * The two must stay in step. If a label is added on the app side and not here,
 * the section it introduces silently stops reaching the model: the parser will
 * treat the heading as body text and glue it onto whatever came before.
 */

// ── Canonical, language-independent section keys ────────────────────
const CARE_SECTION = {
  cultivar: 'cultivar',
  generalDescription: 'generalDescription',
  soil: 'soil',
  soilMoisture: 'soilMoisture',
  moistureCheck: 'moistureCheck',
  water: 'water',
  light: 'light',
  temperature: 'temperature',
  fertilizer: 'fertilizer',
  growthRate: 'growthRate',
  toxicity: 'toxicity',
  placement: 'placement',
  personality: 'personality',
};

/**
 * Every label either writer has ever emitted, in any supported language.
 *
 * Matching covers all six languages rather than the request locale on purpose:
 * the label was frozen into the blob when the plant was created, so a user who
 * has since switched the app to English still has a plant whose sections are
 * headed "Полив". Narrowing this to the current locale orphans them.
 */
const LABEL_TO_KEY = {
  // English (app + analyzer — the analyzer says "Moisture", the app "Soil Moisture")
  'cultivar': CARE_SECTION.cultivar,
  'name': CARE_SECTION.cultivar,
  'general description': CARE_SECTION.generalDescription,
  'soil': CARE_SECTION.soil,
  'soil moisture': CARE_SECTION.soilMoisture,
  'moisture': CARE_SECTION.soilMoisture,
  'moisture check': CARE_SECTION.moistureCheck,
  'water': CARE_SECTION.water,
  'watering': CARE_SECTION.water,
  'light': CARE_SECTION.light,
  'temperature': CARE_SECTION.temperature,
  'fertilizer': CARE_SECTION.fertilizer,
  'growth rate': CARE_SECTION.growthRate,
  'growth': CARE_SECTION.growthRate,
  'toxicity': CARE_SECTION.toxicity,
  'placement': CARE_SECTION.placement,
  'personality': CARE_SECTION.personality,
  // Russian
  'культивар': CARE_SECTION.cultivar,
  'общее описание': CARE_SECTION.generalDescription,
  'почва': CARE_SECTION.soil,
  'влажность почвы': CARE_SECTION.soilMoisture,
  'проверка влажности': CARE_SECTION.moistureCheck,
  'полив': CARE_SECTION.water,
  'освещение': CARE_SECTION.light,
  'температура': CARE_SECTION.temperature,
  'удобрения': CARE_SECTION.fertilizer,
  'скорость роста': CARE_SECTION.growthRate,
  'токсичность': CARE_SECTION.toxicity,
  'размещение': CARE_SECTION.placement,
  'характер': CARE_SECTION.personality,
  // Ukrainian
  'загальний опис': CARE_SECTION.generalDescription,
  'ґрунт': CARE_SECTION.soil,
  'вологість ґрунту': CARE_SECTION.soilMoisture,
  'перевірка вологості': CARE_SECTION.moistureCheck,
  'освітлення': CARE_SECTION.light,
  'добрива': CARE_SECTION.fertilizer,
  'швидкість росту': CARE_SECTION.growthRate,
  'токсичність': CARE_SECTION.toxicity,
  'розміщення': CARE_SECTION.placement,
  // German
  'kultivar': CARE_SECTION.cultivar,
  'allgemeine beschreibung': CARE_SECTION.generalDescription,
  'erde': CARE_SECTION.soil,
  'bodenfeuchtigkeit': CARE_SECTION.soilMoisture,
  'feuchtigkeitsprüfung': CARE_SECTION.moistureCheck,
  'wasser': CARE_SECTION.water,
  'licht': CARE_SECTION.light,
  'temperatur': CARE_SECTION.temperature,
  'dünger': CARE_SECTION.fertilizer,
  'wachstumsrate': CARE_SECTION.growthRate,
  'toxizität': CARE_SECTION.toxicity,
  'standort': CARE_SECTION.placement,
  'charakter': CARE_SECTION.personality,
  // Spanish
  'descripción general': CARE_SECTION.generalDescription,
  'suelo': CARE_SECTION.soil,
  'humedad del suelo': CARE_SECTION.soilMoisture,
  'verificación de humedad': CARE_SECTION.moistureCheck,
  'agua': CARE_SECTION.water,
  'luz': CARE_SECTION.light,
  'temperatura': CARE_SECTION.temperature,
  'fertilizante': CARE_SECTION.fertilizer,
  'tasa de crecimiento': CARE_SECTION.growthRate,
  'toxicidad': CARE_SECTION.toxicity,
  'ubicación': CARE_SECTION.placement,
  'personalidad': CARE_SECTION.personality,
  // French
  'description générale': CARE_SECTION.generalDescription,
  'sol': CARE_SECTION.soil,
  'humidité du sol': CARE_SECTION.soilMoisture,
  "vérification de l'humidité": CARE_SECTION.moistureCheck,
  'eau': CARE_SECTION.water,
  'lumière': CARE_SECTION.light,
  'température': CARE_SECTION.temperature,
  'engrais': CARE_SECTION.fertilizer,
  'taux de croissance': CARE_SECTION.growthRate,
  'toxicité': CARE_SECTION.toxicity,
  'emplacement': CARE_SECTION.placement,
  'personnalité': CARE_SECTION.personality,
};

// Longest real label is ~26 chars; past that it is prose, not a heading.
const MAX_LABEL_LENGTH = 40;

const LABEL_NOISE = /^[\s>#*_\-•–—]+|[\s*_:]+$/g;
// A bold label closes its `**` after the colon, so the body inherits it.
const LEADING_EMPHASIS = /^[\s*_]+/;

function normalizeLabel(raw) {
  return String(raw).replace(LABEL_NOISE, '').toLowerCase().trim();
}

/** Resolves one written label to its canonical key, or null if unrecognised. */
function careLabelToKey(raw) {
  return LABEL_TO_KEY[normalizeLabel(raw)] || null;
}

/**
 * Splits the stored blob into canonical sections.
 *
 * Recognises both shapes the writers produce: `Label: body` on one line, and a
 * bare `Label` heading with the body beneath. Unlabelled lines continue the
 * section above them, so multi-paragraph bodies survive. A section ends where
 * the next recognised label begins — nothing bleeds across.
 */
function parseCareSections(blob) {
  if (!blob || !String(blob).trim()) return {};

  const buffers = {};
  let current = null;

  const append = (text) => {
    if (!current) return;
    (buffers[current] = buffers[current] || []).push(text);
  };

  for (const rawLine of String(blob).split('\n')) {
    const line = rawLine.trim();
    if (!line) {
      append('');
      continue;
    }

    const colon = line.indexOf(':');
    let key = null;
    let remainder = '';

    if (colon > 0 && colon <= MAX_LABEL_LENGTH) {
      key = careLabelToKey(line.slice(0, colon));
      if (key) remainder = line.slice(colon + 1).replace(LEADING_EMPHASIS, '').trim();
    }
    // Markdown-style heading on its own line, body follows.
    if (!key && line.length <= MAX_LABEL_LENGTH) key = careLabelToKey(line);

    if (key) {
      current = key;
      buffers[key] = buffers[key] || [];
      if (remainder) append(remainder);
    } else {
      append(line);
    }
  }

  const out = {};
  for (const [key, lines] of Object.entries(buffers)) {
    const body = lines.join('\n').trim();
    if (body) out[key] = body;
  }
  return out;
}

// ── Topics ──────────────────────────────────────────────────────────

/**
 * The seven chat topics, and what each one is about in care-plan terms.
 *
 * A topic is a decision the owner makes about the plant, not the screen they
 * arrived from — which is why the "Soil Moisture" and "Placement" cards do not
 * get topics of their own. Grouping follows how the care sheets already compose
 * their bodies: the watering sheet shows `water` plus `moistureCheck`, so the
 * watering topic carries both.
 *
 * `diagnostics` and `general` deliberately map to nothing. A diagnosis is
 * grounded in health checks rather than in the standing plan, and the general
 * chat has no section to be reading.
 */
const TOPIC_SECTIONS = {
  water: [CARE_SECTION.water, CARE_SECTION.moistureCheck],
  soil: [CARE_SECTION.soil, CARE_SECTION.soilMoisture],
  light: [CARE_SECTION.light, CARE_SECTION.placement],
  temperature: [CARE_SECTION.temperature],
  fertilizer: [CARE_SECTION.fertilizer],
  diagnostics: [],
  general: [],
};

/** The compact `careDetails` labels worth showing alongside each topic. */
const TOPIC_DETAILS = {
  water: ['watering_season'],
  soil: ['soil_short'],
  light: ['light_hours', 'light_type', 'placement_short'],
  temperature: ['temperature_optimal', 'temperature_minimum', 'temperature_short'],
  fertilizer: ['fertilizer_frequency', 'fertilizer_dose', 'fertilizer_short'],
  diagnostics: [],
  general: [],
};

const TOPICS = Object.keys(TOPIC_SECTIONS);

function isKnownTopic(topic) {
  return typeof topic === 'string' && Object.hasOwn(TOPIC_SECTIONS, topic);
}

/**
 * The plan text behind one topic, exactly as the owner sees it in the sheet.
 *
 * Returned verbatim rather than summarised: the whole point is that the
 * assistant continues the paragraph on screen instead of restating a generic
 * version of it, and a paraphrase here would reintroduce the contradiction it
 * is meant to remove. Returns null when there is nothing to show, so the caller
 * can omit the block rather than print an empty heading.
 */
function careBriefForTopic(topic, careTips, careDetails) {
  if (!isKnownTopic(topic)) return null;

  const sections = parseCareSections(careTips);
  const bodies = TOPIC_SECTIONS[topic]
    .map((key) => sections[key])
    .filter((body) => body && body.trim());

  const details = TOPIC_DETAILS[topic]
    .map((key) => (careDetails || {})[key])
    .filter((value) => value && String(value).trim());

  if (!bodies.length && !details.length) return null;

  const parts = [];
  if (bodies.length) parts.push(bodies.join('\n'));
  if (details.length) parts.push(details.join(' · '));
  return parts.join('\n');
}

/**
 * The whole standing plan as prose, or null when the plant has none.
 *
 * The chat gets one section because the owner is reading one section. A health
 * check gets all of them: it is judging the plant as a whole, and it is the
 * thing allowed to rewrite the plan, so it has to see what it would be
 * replacing.
 *
 * Identity and personality are left out — they say nothing about how the plant
 * is doing, and every line here is paid for on every scan.
 */
const PLAN_OMITTED = [
  CARE_SECTION.cultivar,
  CARE_SECTION.generalDescription,
  CARE_SECTION.personality,
  CARE_SECTION.toxicity,
];

function wholeCarePlan(carePlan) {
  if (!carePlan) return null;
  const sections = parseCareSections(carePlan.tips);
  const lines = Object.entries(sections)
    .filter(([key, body]) => !PLAN_OMITTED.includes(key) && body && body.trim())
    .map(([key, body]) => `${key}: ${body.trim()}`);

  const details = carePlan.details || {};
  const detailLine = Object.entries(details)
    .filter(([, value]) => value && String(value).trim())
    .map(([key, value]) => `${key}=${value}`)
    .join(', ');
  if (detailLine) lines.push(`details: ${detailLine}`);

  return lines.length ? lines.join('\n') : null;
}

module.exports = {
  CARE_SECTION,
  wholeCarePlan,
  TOPICS,
  TOPIC_SECTIONS,
  TOPIC_DETAILS,
  isKnownTopic,
  careLabelToKey,
  parseCareSections,
  careBriefForTopic,
};
