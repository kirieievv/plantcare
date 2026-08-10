/**
 * What a confirmed chat proposal actually writes to the plant.
 *
 * The pot's size is the case worth pinning: it now travels with a second field
 * saying who measured it, and the health check replaces the number whenever
 * that field says "guess". Miss the companion and the chain bites — the owner
 * states 20 cm, the plant keeps the size marked as estimated, and the next scan
 * quietly overwrites what they said with a reading off a photo.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const { proposalUpdate } = require('../proposals.js');

test('a stated pot size is recorded as measured by the owner', () => {
  const update = proposalUpdate({ field: 'potDiameterCm', to: 20 });

  assert.equal(update.potDiameterCm, 20);
  assert.equal(update.potDiameterSource, 'user');
});

test('other fields travel alone', () => {
  const update = proposalUpdate({ field: 'placement', to: 'south' });

  assert.deepEqual(update, { placement: 'south' });
});

test('growing conditions describe a stated size without a qualifier', () => {
  const { describeGrowingConditions } = require('../index.js');

  const stated = describeGrowingConditions({
    potDiameterCm: 20,
    potDiameterSource: 'user',
  });
  const guessed = describeGrowingConditions({
    potDiameterCm: 16,
    potDiameterSource: 'assumed',
  });

  // The owner's number is stated plainly; the fallback says what it is, so the
  // model does not spend an invented 16 cm on the watering dose.
  assert.match(stated, /Pot: 20 cm\./);
  assert.match(guessed, /assumed default/);
});
