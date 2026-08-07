/**
 * The growing-conditions line every prompt about a plant carries.
 *
 * It exists because the model kept telling people to move a plant to a brighter
 * window it was already standing at, and kept asking about drainage the user had
 * answered when the plant was added. These pin the two ways that goes wrong:
 * a plant from before the quiz must produce no line at all (rather than a line
 * full of "unknown"), and a "no" must never read as an absent answer.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const { describeGrowingConditions } = require('../index.js');

test('a fully answered quiz reads as prose, not as field names', () => {
  const line = describeGrowingConditions({
    potDiameterCm: 24,
    potMaterial: 'terracotta',
    hasDrainage: true,
    placement: 'north',
    nearHeatSource: true,
  });

  assert.match(line, /Pot: 24 cm terracotta with drainage holes\./);
  assert.match(line, /north-facing window/);
  assert.match(line, /radiator or air conditioner/);
});

test('a plant added before the quiz produces no line at all', () => {
  // An empty line is the point: a paragraph of "unknown" invites the model to
  // guess, which is exactly what the quiz was added to stop.
  assert.strictEqual(describeGrowingConditions({ name: 'Fikusych' }), null);
  assert.strictEqual(describeGrowingConditions(null), null);
});

test('"no drainage" is stated loudly, not omitted', () => {
  const line = describeGrowingConditions({
    potDiameterCm: 16,
    potMaterial: 'plastic',
    hasDrainage: false,
  });
  assert.match(line, /NO drainage holes/);
});

test('"not sure" about the material drops the word rather than printing it', () => {
  const line = describeGrowingConditions({
    potDiameterCm: 16,
    potMaterial: 'unknown',
    hasDrainage: true,
  });
  assert.strictEqual(line, 'Pot: 16 cm with drainage holes.');
});

test('a quiet radiator answer adds nothing', () => {
  const line = describeGrowingConditions({
    placement: 'south',
    nearHeatSource: false,
  });
  assert.strictEqual(line, 'Placement: south-facing window (6-8 h direct sun).');
});
