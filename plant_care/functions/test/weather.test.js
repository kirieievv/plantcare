/**
 * Weather, the parts that are pure arithmetic and wording (SPEC 12).
 *
 * Two of these exist to stop a whole class of change rather than a bug: the
 * spec forbids thresholds in code ("above 32 °C water earlier") because the
 * agent can weigh temperature against the species, the pot and the placement
 * far better than a constant can. So the description must stay descriptive —
 * numbers in, no verdict out.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const {
  cityKeyOf,
  clientIpOf,
  conditionFromCode,
  describeWeather,
  weatherSnapshot,
} = require('../weather.js');

test('one cache key per city, not per user', () => {
  // Two people a few streets apart share the record — that is the whole point
  // of rounding, and it is also why the rounding is not finer: at two decimals
  // the key identifies a city rather than a person.
  assert.strictEqual(cityKeyOf(50.4501, 30.5234), cityKeyOf(50.4522, 30.5188));
  assert.strictEqual(cityKeyOf(50.45, 30.52), '50.45_30.52');
  assert.notStrictEqual(cityKeyOf(50.45, 30.52), cityKeyOf(52.52, 13.4));
});

test('WMO codes collapse to the four states the design draws', () => {
  assert.strictEqual(conditionFromCode(0), 'sun');
  assert.strictEqual(conditionFromCode(3), 'cloud');
  assert.strictEqual(conditionFromCode(61), 'rain');
  assert.strictEqual(conditionFromCode(95), 'rain');
  assert.strictEqual(conditionFromCode(73), 'cold');
});

test('the client IP is the first hop of the forwarded chain', () => {
  const req = {
    headers: { 'x-forwarded-for': '203.0.113.7, 70.41.3.18, 150.172.238.178' },
  };
  assert.strictEqual(clientIpOf(req), '203.0.113.7');
});

test('the agent gets numbers and no verdict', () => {
  const line = describeWeather(
    {
      tempC: 36.4,
      condition: 'sun',
      humidity: 28,
      forecast: [
        { maxC: 36, minC: 22 },
        { maxC: 34, minC: 21 },
        { maxC: 33, minC: 20 },
      ],
    },
    { city: 'Kyiv' }
  );

  assert.match(line, /36 °C/);
  assert.match(line, /clear/);
  assert.match(line, /humidity 28%/);
  assert.match(line, /Kyiv/);
  assert.match(line, /20–36 °C/);
  // No advice, no thresholds: deciding what 36 °C means is the agent's job.
  assert.ok(!/water|полив|earlier|more often/i.test(line));
});

test('no weather produces no line rather than an empty one', () => {
  assert.strictEqual(describeWeather(null, { city: 'Kyiv' }), null);
  assert.strictEqual(describeWeather({ tempC: null }, null), null);
});

test('a short forecast is omitted instead of half-printed', () => {
  const line = describeWeather(
    { tempC: 12, condition: 'cloud', forecast: [{ maxC: 13, minC: 8 }] },
    null
  );
  assert.match(line, /12 °C/);
  assert.ok(!/Next/.test(line));
});

test('the snapshot keeps what a later argument would need', () => {
  const snap = weatherSnapshot({
    tempC: 36.4,
    condition: 'sun',
    humidity: 28,
    fetchedAt: 'stamp',
    forecast: [{ maxC: 36 }],
  });
  assert.deepStrictEqual(snap, {
    tempC: 36.4,
    condition: 'sun',
    humidity: 28,
    fetchedAt: 'stamp',
  });
  assert.strictEqual(weatherSnapshot(null), null);
});
