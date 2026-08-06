/**
 * The weather offset on the watering schedule.
 *
 * The plan is stable on purpose — rewriting it as conditions wobble is how the
 * sheet ends up disagreeing with the paragraph underneath it. But a stable plan
 * is wrong on the days that matter, so weather moves the *date* and never the
 * plan. These pin the two ways that goes wrong: an offset large enough to
 * become a second plan, and an offset with the sign backwards.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const {
  wateringAdjustment,
  adjustedInterval,
  MAX_SHIFT_DAYS,
} = require('../watering-adjust.js');

const PLANT = { wateringIntervalDays: 9, placement: 'south' };

test('heat brings the watering forward, cold pushes it back', () => {
  const hot = wateringAdjustment(PLANT, { tempC: 34, humidity: 40 });
  const cold = wateringAdjustment(PLANT, { tempC: 5, humidity: 80 });

  assert.ok(hot.days < 0, 'a heatwave must shorten the interval');
  assert.ok(cold.days > 0, 'a cold snap must lengthen it');
  assert.strictEqual(hot.reasonKey, 'heat');
  assert.strictEqual(cold.reasonKey, 'cool');
});

test('an ordinary day moves nothing', () => {
  // Anything else and the schedule jitters daily for no reason the owner can
  // see, which costs more trust than the accuracy is worth.
  assert.strictEqual(wateringAdjustment(PLANT, { tempC: 21, humidity: 55 }), null);
  assert.strictEqual(adjustedInterval(PLANT, { tempC: 21, humidity: 55 }), 9);
});

test('a radiator in freezing weather dries the soil, it does not slow it', () => {
  // The bug this pins: read literally, "-5 outside" says the room is cold and
  // the plant needs water less often. For a plant standing on the radiator the
  // opposite is true — cold outside means the heating is on.
  const onRadiator = wateringAdjustment(
    { ...PLANT, nearHeatSource: true },
    { tempC: -5, humidity: 80 },
  );
  const beside = wateringAdjustment(PLANT, { tempC: -5, humidity: 80 });

  assert.ok(onRadiator.days < 0, 'heating must bring watering forward');
  assert.strictEqual(onRadiator.reasonKey, 'heating');
  assert.ok(beside.days > 0, 'the same cold without a radiator slows drying');
});

test('a plant on a balcony feels the weather fully', () => {
  const outdoor = wateringAdjustment({ ...PLANT, placement: 'balcony' }, { tempC: 34, humidity: 40 });
  const indoor = wateringAdjustment(PLANT, { tempC: 34, humidity: 40 });

  assert.ok(Math.abs(outdoor.days) > Math.abs(indoor.days));
});

test('no forecast can rewrite the plan', () => {
  // The offset is an adjustment, not a second plan. Without a ceiling an
  // extreme reading would replace the owner's schedule outright.
  for (const tempC of [50, -40]) {
    const a = wateringAdjustment({ ...PLANT, placement: 'balcony' }, { tempC, humidity: 10 });
    assert.ok(Math.abs(a.days) <= MAX_SHIFT_DAYS, `${tempC}° shifted by ${a.days}`);
  }
});

test('a short interval is never adjusted below a day', () => {
  const interval = adjustedInterval(
    { ...PLANT, wateringIntervalDays: 2, placement: 'balcony' },
    { tempC: 45, humidity: 5 },
  );
  assert.ok(interval >= 1, `got ${interval}`);
});

test('missing weather or interval leaves the schedule alone', () => {
  assert.strictEqual(wateringAdjustment(PLANT, null), null);
  assert.strictEqual(wateringAdjustment(PLANT, { humidity: 50 }), null);
  assert.strictEqual(wateringAdjustment({ placement: 'south' }, { tempC: 34 }), null);
  assert.strictEqual(adjustedInterval(PLANT, null), 9);
});
