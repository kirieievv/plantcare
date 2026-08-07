/**
 * Reading the stored care plan back on the server.
 *
 * This exists so the assistant can quote the paragraph the owner is looking at
 * instead of reciting what is typical for the species — the failure it fixes is
 * a sheet that says "every 3 days, 220 ml" above prose that says "every 7-14
 * days", answered by an assistant that had seen neither.
 *
 * The label vocabulary is the fragile part: labels are frozen into the blob in
 * whatever language the plant was created in, so these pin that a plan written
 * in one language is still readable from a request made in another, and that a
 * label nobody recognises degrades into body text rather than eating the
 * section before it.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const {
  parseCareSections,
  careBriefForTopic,
  isKnownTopic,
  TOPICS,
} = require('../care-sections.js');

test('a plan written in Russian is readable regardless of request locale', () => {
  const sections = parseCareSections([
    'Полив: Поливайте обильно, пока лишняя вода не стечёт.',
    'Освещение: Яркий рассеянный свет.',
  ].join('\n'));

  assert.strictEqual(sections.water, 'Поливайте обильно, пока лишняя вода не стечёт.');
  assert.strictEqual(sections.light, 'Яркий рассеянный свет.');
});

test('every supported language resolves to the same canonical key', () => {
  // A user who switches the app to English still owns plants whose sections are
  // headed "Полив". Matching the request locale instead of all of them would
  // orphan every plant added before the switch.
  for (const line of ['Water: a', 'Полив: a', 'Wasser: a', 'Agua: a', 'Eau: a']) {
    assert.strictEqual(parseCareSections(line).water, 'a', `failed on: ${line}`);
  }
});

test('a multi-paragraph body survives, and sections do not bleed', () => {
  const sections = parseCareSections([
    'Water: first paragraph.',
    'still the watering section.',
    '',
    'Light: bright indirect.',
  ].join('\n'));

  assert.strictEqual(sections.water, 'first paragraph.\nstill the watering section.');
  assert.strictEqual(sections.light, 'bright indirect.');
});

test('an unrecognised heading becomes body text, it does not swallow a section', () => {
  // The quiet failure mode: a label added on the app side and not here would
  // otherwise glue its section onto whatever came before, and nobody would see
  // it happen.
  const sections = parseCareSections([
    'Water: pour until it drains.',
    'Mystery Heading: something new.',
  ].join('\n'));

  assert.match(sections.water, /pour until it drains/);
  assert.match(sections.water, /Mystery Heading/);
});

test('the watering topic carries the moisture check with it', () => {
  // Mirrors how the sheet composes its body: the user reading "Полив" sees both
  // paragraphs, so the assistant has to have seen both too.
  const brief = careBriefForTopic(
    'water',
    'Water: pour until it drains.\nMoisture Check: finger 3-4 cm in.',
    { watering_season: 'spring-summer' },
  );

  assert.match(brief, /pour until it drains/);
  assert.match(brief, /finger 3-4 cm in/);
  assert.match(brief, /spring-summer/);
});

test('topics with no standing plan produce no block at all', () => {
  // A diagnosis is grounded in health checks, and the general chat has no
  // section on screen. An empty heading would read as a subject with no data.
  const blob = 'Water: pour until it drains.';
  assert.strictEqual(careBriefForTopic('diagnostics', blob, {}), null);
  assert.strictEqual(careBriefForTopic('general', blob, {}), null);
});

test('a plant with no care plan yet produces no block rather than an empty one', () => {
  assert.strictEqual(careBriefForTopic('water', null, null), null);
  assert.strictEqual(careBriefForTopic('water', '', {}), null);
});

test('an unknown topic is refused instead of being echoed into the prompt', () => {
  assert.strictEqual(careBriefForTopic('astrology', 'Water: a', {}), null);
  assert.strictEqual(isKnownTopic('astrology'), false);
  assert.strictEqual(isKnownTopic(null), false);
});

test('the topic list is the seven agreed ones', () => {
  assert.deepStrictEqual(
    [...TOPICS].sort(),
    ['diagnostics', 'fertilizer', 'general', 'light', 'soil', 'temperature', 'water'],
  );
});

test('details alone are enough to build a block', () => {
  // A plant whose prose never mentioned temperature still has the compact
  // labels the sheet shows, and those are worth more than nothing.
  const brief = careBriefForTopic('temperature', 'Water: a', {
    temperature_optimal: '18-26 °C',
    temperature_minimum: '10 °C',
  });

  assert.strictEqual(brief, '18-26 °C · 10 °C');
});
