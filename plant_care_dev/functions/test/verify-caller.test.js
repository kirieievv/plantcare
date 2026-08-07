/**
 * Who the caller is allowed to say they are.
 *
 * Two failures are being pinned here at once, and they pull in opposite
 * directions.
 *
 * The first is the one that made this function exist: endpoints used to take
 * `userId` straight out of the request body and believe it, so anyone who knew
 * a plant id could read that plant's conversation. Every new endpoint has to
 * refuse that outright.
 *
 * The second is what happens the moment the fix ships. The copy of the app in
 * the App Store sends no token and cannot be updated on our schedule. Demand a
 * token from it and its chat goes dark for everyone who has not updated —
 * to close a door that is standing open in production right now anyway. So the
 * endpoints that already exist there keep accepting the old shape until the
 * update has spread, and the new ones never do.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const { verifyCaller } = require('../index.js');

/** Records what the endpoint would have sent back, without a real response. */
function fakeRes() {
  return {
    statusCode: null,
    payload: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.payload = body;
      return this;
    },
  };
}

test('a new endpoint refuses a body-supplied uid', async () => {
  const res = fakeRes();
  const uid = await verifyCaller(
    { headers: {}, method: 'POST', body: { userId: 'someone-elses-uid' } },
    res,
  );

  assert.strictEqual(uid, null, 'must not hand back an unverified uid');
  assert.strictEqual(res.statusCode, 401);
});

test('an existing endpoint still accepts the old shape', async () => {
  const res = fakeRes();
  const uid = await verifyCaller(
    { headers: {}, method: 'POST', body: { userId: 'live-app-user' } },
    res,
    { allowLegacyBody: true },
  );

  assert.strictEqual(uid, 'live-app-user');
  assert.strictEqual(res.statusCode, null, 'the shipped app must not get a 401');
});

test('the old shape is read from the query string on a GET', async () => {
  const res = fakeRes();
  const uid = await verifyCaller(
    { headers: {}, method: 'GET', query: { userId: 'live-app-user' }, body: {} },
    res,
    { allowLegacyBody: true },
  );

  assert.strictEqual(uid, 'live-app-user');
});

test('no token and no uid is still rejected, legacy or not', async () => {
  for (const opts of [undefined, { allowLegacyBody: true }]) {
    const res = fakeRes();
    const uid = await verifyCaller(
      { headers: {}, method: 'POST', body: {} },
      res,
      opts,
    );

    assert.strictEqual(uid, null);
    assert.strictEqual(res.statusCode, 401);
  }
});

test('a blank uid is not an identity', async () => {
  const res = fakeRes();
  const uid = await verifyCaller(
    { headers: {}, method: 'POST', body: { userId: '   ' } },
    res,
    { allowLegacyBody: true },
  );

  assert.strictEqual(uid, null, 'whitespace must not pass as a user');
  assert.strictEqual(res.statusCode, 401);
});

test('a bearer token is checked even when the old shape is allowed', async () => {
  // A token that cannot be verified must lose, rather than quietly falling
  // through to the uid sitting in the body — otherwise the compatibility path
  // becomes a way to launder a rejected token into an accepted identity.
  const res = fakeRes();
  const uid = await verifyCaller(
    {
      headers: { authorization: 'Bearer not-a-real-token' },
      method: 'POST',
      body: { userId: 'someone-elses-uid' },
    },
    res,
    { allowLegacyBody: true },
  );

  assert.strictEqual(uid, null);
  assert.strictEqual(res.statusCode, 401);
});
