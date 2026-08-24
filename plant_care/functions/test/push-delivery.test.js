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

const { accountIsDeleted, fcmErrorOf, pushHealthUpdate } = require('../index.js');

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

// ── Whether anyone would find out next time ──────────────────────────────────
//
// The outage lasted twenty days because nothing recorded it. These pin the one
// judgement that makes the record trustworthy: a run that sent nothing is not
// evidence either way. Reminders fall due a couple of times a day and some days
// none do — call that healthy and a dead transport shows green, call it stale
// and every quiet weekend cries outage.

test('a run that sent nothing has no opinion', () => {
  assert.strictEqual(
    pushHealthUpdate({ attempted: false, delivered: 0, now: 1000 }),
    null
  );
});

test('one device reached means the transport works', () => {
  const u = pushHealthUpdate({ attempted: true, delivered: 1, now: 1000 });
  assert.strictEqual(u.lastOkAt, 1000);
  assert.strictEqual(u.failures, 0);
  assert.strictEqual(u.lastFailAt, undefined);
});

test('stale tokens alongside a delivery are not a failure', () => {
  // The ordinary case: several dead tokens, one live phone. Nothing is wrong.
  const u = pushHealthUpdate({
    attempted: true,
    delivered: 1,
    error: 'messaging/registration-token-not-registered',
    now: 1000,
  });
  assert.strictEqual(u.lastOkAt, 1000);
  assert.strictEqual(u.failures, 0);
});

test('reaching nobody is the failure worth seeing', () => {
  // The real outage: the batch endpoint answering 404 for every device.
  const u = pushHealthUpdate({
    attempted: true,
    delivered: 0,
    error: 'messaging/unknown-error',
    now: 1000,
  });
  assert.strictEqual(u.lastFailAt, 1000);
  assert.strictEqual(u.failures, 'increment');
  assert.strictEqual(u.lastOkAt, undefined);
  assert.match(u.lastError, /unknown-error/);
});

test('a failure with no error still says something', () => {
  const u = pushHealthUpdate({ attempted: true, delivered: 0, now: 1000 });
  assert.ok(u.lastError && u.lastError.length > 0);
});

test('every attempt is dated, whichever way it went', () => {
  // Without this the panel cannot tell "working" from "not tried lately".
  for (const delivered of [0, 3]) {
    const u = pushHealthUpdate({ attempted: true, delivered, now: 1000 });
    assert.strictEqual(u.lastAttemptAt, 1000);
  }
});
