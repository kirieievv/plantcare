/**
 * Rules for the care-task scheduler.
 *
 * These exist because the pairing of watering with a health check is easy to get
 * subtly wrong in a way that costs money: an idempotency slip re-issues the scan
 * task every six hours, and every issued scan is an invitation to spend on the
 * analyser. Each case below pins one of those slips.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const { plannedTasksFor } = require('../index.js');

const NOW = new Date('2026-08-10T12:00:00Z');
const day = (n) => new Date(NOW.getTime() + n * 86400000).toISOString();

/** A plant watered three days ago whose next watering fell due yesterday. */
function thirstyPlant(overrides = {}) {
  return {
    userId: 'u1',
    lastWateredAt: day(-3),
    nextDueAt: day(-1),
    lastHealthCheck: day(-40),
    lastFertilisedAt: day(-2),
    ...overrides,
  };
}

const categories = (tasks) => tasks.map((t) => t.category).sort();

test('the watering day issues watering and a health check together', () => {
  const out = plannedTasksFor(thirstyPlant(), new Set(), NOW);

  assert.deepStrictEqual(categories(out), ['scan', 'water']);

  const water = out.find((t) => t.category === 'water');
  const scan = out.find((t) => t.category === 'scan');
  // Same due date: the pair is one cycle, and it ages as one.
  assert.strictEqual(scan.dueAt, water.dueAt);
});

test('a second tick in the same cycle issues nothing', () => {
  // The first tick wrote the watermark and left both tasks open.
  const plant = thirstyPlant({ lastScanTaskAt: day(-0.2) });
  const open = new Set(['water', 'scan']);

  assert.deepStrictEqual(plannedTasksFor(plant, open, NOW), []);
});

test('closing the health check does not bring it back in the same cycle', () => {
  // The user ran the check, or simply ticked the task off: either way the task
  // is gone and the watermark stays. Without it this returned a fresh scan
  // every six hours for as long as the plant went unwatered.
  const plant = thirstyPlant({ lastScanTaskAt: day(-0.2) });

  const out = plannedTasksFor(plant, new Set(['water']), NOW);
  assert.strictEqual(
    out.find((t) => t.category === 'scan'),
    undefined,
  );
});

test('a scan done this cycle blocks the task even without a watermark', () => {
  const plant = thirstyPlant({ lastHealthCheck: day(-0.5) });

  const out = plannedTasksFor(plant, new Set(), NOW);
  assert.strictEqual(
    out.find((t) => t.category === 'scan'),
    undefined,
  );
});

test('after watering, nothing is issued until the next due date', () => {
  const plant = thirstyPlant({
    lastWateredAt: day(-0.1),
    nextDueAt: day(4),
    lastHealthCheck: day(-0.05),
    lastFertilisedAt: day(-1),
  });

  assert.deepStrictEqual(plannedTasksFor(plant, new Set(), NOW), []);
});

test('an open analysis task does not silence the scheduled rhythm', () => {
  // `openCategories` is built from scheduled tasks only, so a recommendation
  // the app filed under "water" cannot stop the watering reminder.
  const out = plannedTasksFor(thirstyPlant(), new Set(), NOW);
  assert.ok(out.some((t) => t.category === 'water'));
});

test('an open task blocks only its own category', () => {
  const out = plannedTasksFor(thirstyPlant(), new Set(['water']), NOW);

  assert.strictEqual(out.find((t) => t.category === 'water'), undefined);
  assert.ok(out.some((t) => t.category === 'scan'));
});

test('a sticky shouldWaterNow counts as due, as it does on the plant screen', () => {
  const plant = thirstyPlant({ nextDueAt: day(5), shouldWaterNow: true });

  assert.deepStrictEqual(categories(plannedTasksFor(plant, new Set(), NOW)), [
    'scan',
    'water',
  ]);
});

test('a slow-cycle plant still gets a check through the monthly ceiling', () => {
  // Watered yesterday, nothing due for six weeks — the cycle rule alone would
  // never fire, so the 30-day ceiling has to.
  const plant = thirstyPlant({
    lastWateredAt: day(-1),
    nextDueAt: day(44),
    lastHealthCheck: day(-40),
    lastScanTaskAt: day(-40),
  });

  const out = plannedTasksFor(plant, new Set(), NOW);
  assert.ok(out.some((t) => t.category === 'scan'));
  assert.strictEqual(out.find((t) => t.category === 'water'), undefined);
});

test('watering carries its real due date, so a late cycle reads as late', () => {
  const out = plannedTasksFor(thirstyPlant(), new Set(), NOW);
  const water = out.find((t) => t.category === 'water');

  assert.strictEqual(water.dueAt, new Date(day(-1)).toISOString());
});
