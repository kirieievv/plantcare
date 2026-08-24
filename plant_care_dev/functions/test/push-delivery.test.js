/**
 * Two things that let a twenty-day push outage go unnoticed.
 *
 * The first is who gets written to. An account deleted itself fourteen minutes
 * after signing up; its plants stayed, because keeping the history is
 * deliberate, and the reminder job went on emailing the person who had left —
 * thirty-eight times over eleven days. The job read the user document for the
 * address and the channel switches and never looked at whether the account was
 * still there.
 *
 * The second is what gets recorded. Pushes were logged only when at least one
 * device was reached, so a transport that reached nothing wrote nothing, and an
 * empty collection reads exactly like "no reminders were due". The failure has
 * to be storable — which means a Google error page has to come back as a short
 * string, not as itself.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const { accountIsDeleted, fcmErrorOf } = require('../index.js');

test('an account that deleted itself is deleted', () => {
  // Both fields, as deleteAccount writes them.
  assert.strictEqual(
    accountIsDeleted({ status: 'deleted', deletedAt: new Date() }),
    true
  );
});

test('either field alone still means the account left', () => {
  // Older documents, and any write that only managed half the update.
  assert.strictEqual(accountIsDeleted({ status: 'deleted' }), true);
  assert.strictEqual(accountIsDeleted({ deletedAt: new Date() }), true);
});

test('an ordinary account is not deleted', () => {
  assert.strictEqual(
    accountIsDeleted({ email: 'someone@example.com', status: 'active' }),
    false
  );
  assert.strictEqual(accountIsDeleted({}), false);
});

test('a missing document is not a deletion', () => {
  // getUserInfo falls back to Auth when Firestore has nothing; treating that
  // as deleted would silence reminders for everyone it happens to.
  assert.strictEqual(accountIsDeleted(null), false);
  assert.strictEqual(accountIsDeleted(undefined), false);
});

test('an FCM error code survives as the code', () => {
  assert.strictEqual(
    fcmErrorOf({ code: 'messaging/registration-token-not-registered' }),
    'messaging/registration-token-not-registered'
  );
});

test('an error nested under errorInfo is found too', () => {
  // What sendEachForMulticast puts on the per-token responses.
  assert.strictEqual(
    fcmErrorOf({ errorInfo: { code: 'messaging/invalid-argument' } }),
    'messaging/invalid-argument'
  );
});

test('the outage itself fits in a document', () => {
  // The real one: a 404 HTML page from the decommissioned /batch endpoint.
  const html = `An unknown server error was returned. Raw server response: "<!DOCTYPE html>\n<html lang=en>\n  <title>Error 404 (Not Found)!!1</title>\n${'  <style>x{}\n'.repeat(60)}"`;
  const stored = fcmErrorOf(new Error(html));
  assert.ok(stored.length <= 200, `stored ${stored.length} characters`);
  assert.ok(!stored.includes('\n'), 'newlines collapsed');
  assert.ok(stored.includes('404'), 'still says what went wrong');
});

test('no error is null, not the string "undefined"', () => {
  assert.strictEqual(fcmErrorOf(null), null);
  assert.strictEqual(fcmErrorOf(undefined), null);
});
