/**
 * How long we go on reminding someone about one unwatered plant.
 *
 * It used to be twenty reminders across ten days, two a day, and nobody meant
 * that. The intent was already written into the code a few hundred lines from
 * the constant: the AI-written copy was reserved for "the first 4 days" and
 * everything after it fell back to a template. Four days was the design; the
 * cap of twenty was a leftover nobody trimmed.
 *
 * The shape matters as much as the length. The first day carries two — a
 * warning before the plant is due, and a nudge after, for the person who meant
 * to and forgot. From the second day the plant is simply overdue, and saying so
 * twice a day is nagging rather than helping, so it drops to one.
 *
 * Run with: npm test  (from functions/)
 */

const test = require('node:test');
const assert = require('node:assert');

const {
  reminderSlotAt,
  describeReminderSlot,
  buildGroupedReminderCopy,
  WATERING_EMAIL_MAX_REMINDERS,
} = require('../index.js');

const MIN = 60 * 1000;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;
const LEAD = 30 * MIN;
const FOLLOW = 30 * MIN;

/** 18:00, which is when very nearly every plant in production falls due. */
const due = new Date('2026-08-24T18:00:00.000Z');
const at = (i) => reminderSlotAt(due, i, LEAD, FOLLOW);
const offset = (i) => at(i).getTime() - due.getTime();

test('the first reminder arrives before the plant is due', () => {
  assert.strictEqual(offset(0), -30 * MIN);
});

test('the second comes shortly after, the same day', () => {
  // For the person who saw the first one, meant to, and forgot.
  assert.strictEqual(offset(1), 30 * MIN);
  assert.strictEqual(at(1).getUTCDate(), due.getUTCDate());
});

test('after the first day it is once a day, not twice', () => {
  assert.strictEqual(offset(2), DAY + 30 * MIN);
  assert.strictEqual(offset(3), 2 * DAY + 30 * MIN);
  assert.strictEqual(offset(4), 3 * DAY + 30 * MIN);
});

test('every reminder falls on its own day', () => {
  // The old formula put two on each day, which is how ten days of them
  // happened. Nothing may share a date with its neighbour after day one.
  const days = [1, 2, 3, 4].map((i) => at(i).getUTCDate());
  assert.deepStrictEqual(days, [...new Set(days)].sort((a, b) => a - b));
});

test('the last reminder is on the fourth day and there is no fifth', () => {
  assert.strictEqual(WATERING_EMAIL_MAX_REMINDERS, 5);
  const last = at(WATERING_EMAIL_MAX_REMINDERS - 1);
  assert.strictEqual(Math.round((last - due) / DAY), 3);
});

test('only the very first one is a warning', () => {
  // The rest are about something that has already failed to happen.
  assert.strictEqual(describeReminderSlot(0).isPre, true);
  for (const i of [1, 2, 3, 4]) {
    assert.strictEqual(describeReminderSlot(i).isPre, false, `slot ${i}`);
  }
});

test('the day the reader is told matches the day it arrives', () => {
  // Both slots on the first day say "day 1"; after that the number tracks the
  // slot. Said wrong, a reminder claims a day that is not the one it landed on.
  const told = [0, 1, 2, 3, 4].map((i) => describeReminderSlot(i).dayNum);
  assert.deepStrictEqual(told, [1, 1, 2, 3, 4]);

  for (const i of [0, 1, 2, 3, 4]) {
    const daysLate = Math.max(0, Math.round((at(i) - due) / DAY));
    assert.strictEqual(describeReminderSlot(i).dayNum, daysLate + 1, `slot ${i}`);
  }
});

test('the plant document records which kind was sent', () => {
  assert.strictEqual(describeReminderSlot(0).plantStage, 'pre_sent');
  assert.strictEqual(describeReminderSlot(3).plantStage, 'post_sent');
});

// ── One message for the several plants that came due together ────────────────
//
// Somebody with seven plants got four notifications inside the same minute,
// because reminders went out one per plant. The plan allows ten.

const LOCALES = ['en', 'ru', 'uk', 'de', 'es', 'fr'];
const grouped = (locale, plantNames, userName = 'Vladimir') =>
  buildGroupedReminderCopy({ locale, userName, plantNames });

test('every plant is named, in every language', () => {
  const names = ['Зелёныш', 'Моня', 'Кактус Петрович'];
  for (const locale of LOCALES) {
    const copy = grouped(locale, names);
    for (const name of names) {
      assert.ok(copy.text.includes(name), `${locale} text is missing ${name}`);
      assert.ok(copy.html.includes(name), `${locale} html is missing ${name}`);
    }
    assert.ok(copy.subject.startsWith('3'), `${locale} subject: ${copy.subject}`);
  }
});

test('Russian and Ukrainian count in three forms, not one', () => {
  // "2 растений" is what a naive plural gives, and it reads as broken Russian
  // to every person who receives it.
  const form = (locale, n) =>
    grouped(locale, Array.from({ length: n }, (_, i) => `P${i}`)).subject;

  assert.match(form('ru', 2), /^2 растения ждут/);
  assert.match(form('ru', 4), /^4 растения ждут/);
  assert.match(form('ru', 5), /^5 растений ждут/);
  assert.match(form('ru', 10), /^10 растений ждут/);

  assert.match(form('uk', 2), /^2 рослини чекають/);
  assert.match(form('uk', 5), /^5 рослин чекають/);
});

test('a person with no name is greeted without a dangling comma', () => {
  for (const locale of LOCALES) {
    const copy = buildGroupedReminderCopy({
      locale,
      userName: null,
      plantNames: ['A', 'B'],
    });
    // "Привет, !" and "Bonjour ," are what a greeting built by concatenation
    // does when the name is missing, and every locale here builds one. A
    // greeting that simply ends in a comma — "Hi," — is fine, so the tells are
    // punctuation left stranded after the separator, or a space before it.
    const greeting = copy.text.split('\n\n')[0];
    assert.ok(!/[,:]\s+[!?.,:]/.test(greeting), `${locale}: "${greeting}"`);
    assert.ok(!/\s[,:]/.test(greeting), `${locale}: "${greeting}"`);
    assert.ok(!copy.text.includes('null'), `${locale} leaked a null`);
    assert.ok(!copy.text.includes('undefined'), `${locale} leaked an undefined`);
  }
});

test('the three parts are separate paragraphs, not one run-on line', () => {
  const copy = grouped('en', ['A', 'B']);
  assert.strictEqual(copy.text.split('\n\n').length, 3);
  assert.strictEqual((copy.html.match(/<p>/g) || []).length, 4);
});
