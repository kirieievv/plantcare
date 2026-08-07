/**
 * The chat window the model actually sees.
 *
 * This used to be assembled in the app, which is how it came to post the FIRST
 * fourteen messages of a conversation instead of the last fourteen: the list is
 * oldest-first and the code said `.take(14)`. Every one of these pins a way the
 * window can silently carry the wrong thing — wrong end, wrong order, a message
 * the user is about to be shown as saying twice, or content from before a clear
 * the user is looking at an empty screen for.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const { loadChatHistory, CHAT_HISTORY_WINDOW } = require('../index.js');

/**
 * Minimal stand-in for the Firestore surface loadChatHistory touches.
 *
 * `messages` is given oldest-first because that is how a human reads a chat;
 * the fake applies the ordering the real query would, so a test that passes
 * here would pass against Firestore for the same reason.
 */
function fakeDb({ messages = [], historyClearedAt = null } = {}) {
  const captured = { where: null, limit: null, orderBy: null };

  const messagesCollection = {
    _docs: messages,
    where(field, op, value) {
      captured.where = { field, op, value };
      return {
        ...messagesCollection,
        _docs: messages.filter((m) => m.createdAt > value),
        orderBy: messagesCollection.orderBy,
        limit: messagesCollection.limit,
      };
    },
    orderBy(field, dir) {
      captured.orderBy = { field, dir };
      const sorted = [...this._docs].sort((a, b) =>
        dir === 'desc' ? b.createdAt - a.createdAt : a.createdAt - b.createdAt);
      return { ...this, _docs: sorted, limit: messagesCollection.limit, orderBy: messagesCollection.orderBy };
    },
    limit(n) {
      captured.limit = n;
      const sliced = this._docs.slice(0, n);
      return { ...this, _docs: sliced, get: async () => ({ docs: sliced.map((d) => ({ data: () => d })) }) };
    },
  };

  const chatDoc = {
    get: async () => ({
      exists: historyClearedAt !== null,
      data: () => ({ historyClearedAt }),
    }),
    collection: () => messagesCollection,
  };

  return {
    captured,
    db: {
      collection: () => ({ doc: () => ({ collection: () => ({ doc: () => chatDoc }) }) }),
    },
  };
}

const msg = (createdAt, role, text) => ({ createdAt, role, text });

test('the window is the newest messages, handed to the model oldest-first', async () => {
  // Twenty turns, so the window has to choose. Taking the wrong end is the
  // original bug and it is invisible in the UI — the user sees a full history
  // and an assistant that has forgotten the last hour.
  const messages = Array.from({ length: 20 }, (_, i) =>
    msg(i + 1, i % 2 === 0 ? 'user' : 'assistant', `turn ${i + 1}`));

  const { db } = fakeDb({ messages });
  const history = await loadChatHistory(db, 'uid', 'plant', 'a new question');

  assert.strictEqual(history.length, CHAT_HISTORY_WINDOW);
  assert.strictEqual(history[0].content, `turn ${20 - CHAT_HISTORY_WINDOW + 1}`);
  assert.strictEqual(history[history.length - 1].content, 'turn 20');
});

test('a cleared history hides everything before the mark', async () => {
  // The clear is soft: the documents are still there. If the model kept reading
  // them it would go on quoting a conversation the user has just wiped.
  const messages = [
    msg(1, 'user', 'before the clear'),
    msg(2, 'assistant', 'also before'),
    msg(9, 'user', 'after the clear'),
  ];

  const { db, captured } = fakeDb({ messages, historyClearedAt: 5 });
  const history = await loadChatHistory(db, 'uid', 'plant', 'unrelated');

  assert.deepStrictEqual(captured.where, { field: 'createdAt', op: '>', value: 5 });
  assert.deepStrictEqual(history.map((m) => m.content), ['after the clear']);
});

test('the message being asked right now is not also fed back as history', async () => {
  // The app writes the user's message before calling us, so whether it has
  // landed is a race. When it has, passing it twice reads to the model as the
  // user repeating themselves.
  const messages = [
    msg(1, 'user', 'older question'),
    msg(2, 'assistant', 'older answer'),
    msg(3, 'user', 'should I water it today?'),
  ];

  const { db } = fakeDb({ messages });
  const history = await loadChatHistory(db, 'uid', 'plant', 'should I water it today?');

  assert.deepStrictEqual(history.map((m) => m.content), ['older question', 'older answer']);
});

test('an identical question asked earlier is kept, only the trailing one is dropped', async () => {
  // Asking the same thing twice a week apart is real history, not the race.
  const messages = [
    msg(1, 'user', 'should I water it today?'),
    msg(2, 'assistant', 'not yet'),
  ];

  const { db } = fakeDb({ messages });
  const history = await loadChatHistory(db, 'uid', 'plant', 'should I water it today?');

  assert.deepStrictEqual(history.map((m) => m.content), ['should I water it today?', 'not yet']);
});

test('roles collapse to user/assistant and empty messages are dropped', async () => {
  const messages = [
    msg(1, 'system', 'whatever this is'),
    msg(2, 'assistant', ''),
    msg(3, 'assistant', 'a real answer'),
  ];

  const { db } = fakeDb({ messages });
  const history = await loadChatHistory(db, 'uid', 'plant', 'q');

  assert.deepStrictEqual(history, [
    { role: 'user', content: 'whatever this is' },
    { role: 'assistant', content: 'a real answer' },
  ]);
});
