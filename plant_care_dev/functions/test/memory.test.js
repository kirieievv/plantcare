/**
 * What the assistant remembers, and what it is allowed to propose.
 *
 * The transcript is twelve messages, so everything that matters for longer than
 * an afternoon lives in facts. Two things go quietly wrong here and neither is
 * visible from the outside: a fact evicting one it should have sat beside, and
 * a symptom ageing out of the count that was supposed to notice it recurring.
 *
 * The proposal tests are the other half — the model asks, the whitelist decides.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const { buildMemoryBlock, isCurrent, FACT_KINDS } = require('../memory.js');
const { sanitizeProposal, invalidatesPlan, invalidatesSchedule } = require('../proposals.js');

const NOW = Date.parse('2026-08-05T00:00:00Z');
const daysAgo = (n) => new Date(NOW - n * 86400000).toISOString();

// ── Facts ───────────────────────────────────────────────────────────

test('configuration holds until contradicted, a symptom does not', () => {
  // A pot does not change on its own; drooping leaves three weeks ago say
  // nothing about today. Giving both the same lifetime is how a plant ends up
  // being treated for a problem it got over last month.
  assert.strictEqual(isCurrent({ kind: 'placement', statedAt: daysAgo(300) }, NOW), true);
  assert.strictEqual(isCurrent({ kind: 'symptom', statedAt: daysAgo(30) }, NOW), false);
  assert.strictEqual(isCurrent({ kind: 'symptom', statedAt: daysAgo(5) }, NOW), true);
});

test('a superseded fact is never current, however fresh', () => {
  assert.strictEqual(
    isCurrent({ kind: 'placement', statedAt: daysAgo(1), supersededAt: daysAgo(0) }, NOW),
    false,
  );
});

test('only the single-valued kinds evict their predecessor', () => {
  // "Away in August" and "there is a cat" are both constraints. Treating every
  // kind as single-valued would silently drop one of them.
  assert.strictEqual(FACT_KINDS.placement.single, true);
  assert.strictEqual(FACT_KINDS.container.single, true);
  assert.strictEqual(FACT_KINDS.constraint.single, false);
  assert.strictEqual(FACT_KINDS.intervention.single, false);
  assert.strictEqual(FACT_KINDS.symptom.single, false);
});

test('the topic orders the facts and never filters them', () => {
  // The whole argument for one assistant is that a watering question can be
  // answered with a lighting fact. Ordering is a hint; dropping is a lie.
  const memory = {
    current: [
      { kind: 'placement', text: 'east window', statedAt: daysAgo(20) },
      { kind: 'watering_habit', text: 'waters two days early', statedAt: daysAgo(3) },
      { kind: 'constraint', text: 'away in August', statedAt: daysAgo(8) },
    ],
    recurring: [],
    changed: [],
  };

  const water = buildMemoryBlock(memory, 'water');
  const light = buildMemoryBlock(memory, 'light');

  assert.match(water.split('\n')[0], /waters two days early/);
  assert.match(light.split('\n')[0], /east window/);
  for (const block of [water, light]) {
    assert.match(block, /away in August/);
    assert.strictEqual(block.split('\n').length, 3);
  }
});

test('a recurring symptom is stated as a count, not as three separate facts', () => {
  // "Third time this season" is the diagnosis, and it exists in none of the
  // individual facts — which is why ageing one out must not delete it.
  const block = buildMemoryBlock({
    current: [],
    recurring: [{ text: 'tips drying', count: 3, lastAt: daysAgo(2) }],
    changed: [],
  }, 'diagnostics');

  assert.match(block, /reported 3 times/);
});

test('a plant that has been moved around says so', () => {
  const block = buildMemoryBlock({
    current: [{ kind: 'placement', text: 'north window', statedAt: daysAgo(1) }],
    recurring: [],
    changed: [{ kind: 'placement', count: 4, lastAt: daysAgo(1) }],
  }, 'light');

  assert.match(block, /changed 4 times/);
});

test('nothing remembered yet produces no block rather than an empty heading', () => {
  assert.strictEqual(buildMemoryBlock({ current: [], recurring: [], changed: [] }, 'water'), null);
  assert.strictEqual(buildMemoryBlock(null, 'water'), null);
});

// ── Proposals ───────────────────────────────────────────────────────

const PLANT = { wateringIntervalDays: 9, placement: 'south', species: 'Rosmarinus officinalis' };

test('a valid proposal carries both ends, so the card can show the change', () => {
  const p = sanitizeProposal(
    { field: 'wateringIntervalDays', value: 11, reason: 'Less direct sun after the move' },
    PLANT,
  );
  assert.deepStrictEqual(p, {
    field: 'wateringIntervalDays',
    from: 9,
    to: 11,
    reason: 'Less direct sun after the move',
  });
});

test('anything outside the whitelist is refused', () => {
  // The failure is asymmetric: a wrong interval is visible and fixable in the
  // same card, a wrong name or a touched watering event is not.
  for (const field of ['name', 'imageUrl', 'lastWateredAt', 'subscriptionStatus']) {
    assert.strictEqual(sanitizeProposal({ field, value: 'x', reason: 'because' }, PLANT), null, field);
  }
});

test('values outside the range the rest of the system accepts are refused', () => {
  assert.strictEqual(sanitizeProposal({ field: 'wateringIntervalDays', value: 900, reason: 'r' }, PLANT), null);
  assert.strictEqual(sanitizeProposal({ field: 'wateringAmountMl', value: 5, reason: 'r' }, PLANT), null);
  assert.strictEqual(sanitizeProposal({ field: 'placement', value: 'attic', reason: 'r' }, PLANT), null);
});

test('a proposal that changes nothing is dropped rather than shown', () => {
  // Otherwise it arrives as a card the owner has to dismiss to learn it was
  // pointless.
  assert.strictEqual(sanitizeProposal({ field: 'placement', value: 'south', reason: 'r' }, PLANT), null);
});

test('a proposal without a reason is refused', () => {
  // The reason is the whole card. Without it the owner is asked to approve a
  // number with no argument behind it.
  assert.strictEqual(sanitizeProposal({ field: 'placement', value: 'east' }, PLANT), null);
  assert.strictEqual(sanitizeProposal({ field: 'placement', value: 'east', reason: '  ' }, PLANT), null);
});

test('a pause must be in the future and inside a season', () => {
  const soon = new Date(Date.now() + 14 * 86400000).toISOString();
  const tooFar = new Date(Date.now() + 400 * 86400000).toISOString();

  assert.ok(sanitizeProposal({ field: 'tasksPausedUntil', value: soon, reason: 'Away' }, PLANT));
  assert.strictEqual(sanitizeProposal({ field: 'tasksPausedUntil', value: '2020-01-01', reason: 'r' }, PLANT), null);
  assert.strictEqual(sanitizeProposal({ field: 'tasksPausedUntil', value: tooFar, reason: 'r' }, PLANT), null);
});

test('only plan inputs make the care text stale, and only schedule inputs rebuild chores', () => {
  // Weather-style volatility must never reach the fingerprint: if a daily input
  // invalidated the plan, the plan would be rewritten daily and drift on its own.
  assert.strictEqual(invalidatesPlan('placement'), true);
  assert.strictEqual(invalidatesPlan('wateringIntervalDays'), false);
  assert.strictEqual(invalidatesPlan('tasksPausedUntil'), false);

  assert.strictEqual(invalidatesSchedule('wateringIntervalDays'), true);
  assert.strictEqual(invalidatesSchedule('tasksPausedUntil'), true);
  assert.strictEqual(invalidatesSchedule('species'), false);
});
