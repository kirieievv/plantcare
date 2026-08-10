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
  WEATHER_FORCED_TTL_MS,
  WEATHER_TTL_MS,
  cityKeyOf,
  clientIpOf,
  conditionFromCode,
  describeWeather,
  isFresh,
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

// ── How long a cached reading counts as current ──────────────────────────────
//
// The same record has two answers, and that is the entire mechanism behind the
// pull-to-refresh gesture: fresh enough for someone who just opened the app,
// stale for someone who pulled the screen down asking for a new number. Pinned
// here because the alternative is waiting an hour to find out.

const NOW = 1_760_000_000_000;
const minutesAgo = (n) => ({ fetchedAt: NOW - n * 60 * 1000 });

test('a reading from ten minutes ago is current on an ordinary open', () => {
  assert.equal(isFresh(minutesAgo(10), WEATHER_TTL_MS, NOW), true);
});

test('an hour later it is not', () => {
  assert.equal(isFresh(minutesAgo(61), WEATHER_TTL_MS, NOW), false);
});

test('the same reading is stale for someone who pulled the screen', () => {
  // Half an hour old: still good enough to draw on arrival, not good enough to
  // hand back to a gesture that exists to produce a new number.
  const halfHour = minutesAgo(30);
  assert.equal(isFresh(halfHour, WEATHER_TTL_MS, NOW), true);
  assert.equal(isFresh(halfHour, WEATHER_FORCED_TTL_MS, NOW), false);
});

test('pulling twice in a minute does not fetch twice', () => {
  // The floor under the gesture. Without it, nothing stops a person pulling
  // once a second and every pull leaving the building.
  assert.equal(isFresh(minutesAgo(1), WEATHER_FORCED_TTL_MS, NOW), true);
});

test('nothing cached is never current', () => {
  assert.equal(isFresh(null, WEATHER_TTL_MS, NOW), false);
  assert.equal(isFresh({}, WEATHER_TTL_MS, NOW), false);
});

test('a record without a usable timestamp is refetched, not trusted', () => {
  // A half-written cache entry must not pin the city to whatever it holds.
  assert.equal(isFresh({ fetchedAt: 'today' }, WEATHER_TTL_MS, NOW), false);
});

test('a Firestore Timestamp is read the same as a plain number', () => {
  const asTimestamp = { fetchedAt: { toMillis: () => NOW - 5 * 60 * 1000 } };
  assert.equal(isFresh(asTimestamp, WEATHER_TTL_MS, NOW), true);
  assert.equal(isFresh(asTimestamp, WEATHER_FORCED_TTL_MS, NOW), true);
});
