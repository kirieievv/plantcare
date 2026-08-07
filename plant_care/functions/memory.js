/**
 * What the assistant knows about a plant beyond the plant's own fields.
 *
 * The transcript is a window — twelve messages — so anything said earlier is
 * gone from it within an afternoon. Facts are where the durable half lives:
 * "moved it to the east window", "waters two days early every time", "away
 * from the 10th". They are read back into every prompt regardless of topic,
 * which is what makes one assistant with several entry points behave like one
 * assistant rather than seven amnesiacs.
 *
 * Two rules carry most of the weight here.
 *
 * Only what the owner *stated* is recorded automatically. The model's own
 * conclusions ("looks like you overwater") are not facts, and a fabricated one
 * poisons every later answer while being invisible — which is also why the app
 * has a screen listing these, and why delete has to work.
 *
 * Deduplication is per kind, and not every kind is single-valued. A plant lives
 * in one place, so a new `placement` supersedes the old one. But "away in
 * August" and "there is a cat" are both constraints and must not evict each
 * other. Getting that wrong silently loses information, so the flag is part of
 * the kind's definition rather than a rule applied to all of them.
 */

// ── Kinds ───────────────────────────────────────────────────────────

/**
 * `single`: one current value, a newer fact supersedes it.
 * `ttlDays`: how long it stays current when nothing supersedes it — null means
 * it holds until contradicted, which is right for configuration and wrong for
 * anything describing a moment.
 */
const FACT_KINDS = {
  placement: { single: true, ttlDays: null },
  container: { single: true, ttlDays: null },
  watering_habit: { single: true, ttlDays: null },
  species_correction: { single: true, ttlDays: null },

  environment: { single: false, ttlDays: null },
  intervention: { single: false, ttlDays: 120 },
  symptom: { single: false, ttlDays: 21 },
  constraint: { single: false, ttlDays: 60 },
  goal: { single: false, ttlDays: null },
  preference: { single: false, ttlDays: null },
};

const FACT_KIND_NAMES = Object.keys(FACT_KINDS);

function isKnownKind(kind) {
  return typeof kind === 'string' && Object.hasOwn(FACT_KINDS, kind);
}

/** Which kinds a topic wants to hear about first. Ordering only — never a filter. */
const TOPIC_FACT_PRIORITY = {
  water: ['watering_habit', 'container', 'placement', 'symptom'],
  soil: ['container', 'intervention', 'symptom'],
  light: ['placement', 'environment', 'symptom'],
  temperature: ['environment', 'placement'],
  fertilizer: ['watering_habit', 'intervention'],
  diagnostics: ['symptom', 'intervention', 'environment'],
  general: [],
};

const MAX_FACTS_IN_PROMPT = 18;
const FACTS_COLLECTION = 'facts';

// ── Reading ─────────────────────────────────────────────────────────

function factsRef(db, plantId) {
  return db.collection('plants').doc(plantId).collection(FACTS_COLLECTION);
}

function ageInDays(iso, now) {
  const then = Date.parse(iso);
  if (Number.isNaN(then)) return 0;
  return Math.floor((now - then) / 86400000);
}

/** A fact is current if nothing superseded it and it has not aged out. */
function isCurrent(fact, now) {
  if (fact.supersededAt) return false;
  const ttl = FACT_KINDS[fact.kind]?.ttlDays;
  if (ttl == null) return true;
  return ageInDays(fact.statedAt, now) <= ttl;
}

/**
 * Everything remembered about a plant, split into what still holds and what
 * only history knows.
 *
 * Aged-out facts are kept rather than deleted: a symptom that stops being
 * current is exactly the thing worth counting later. "Yellowing for the third
 * time this season" is not in any single fact.
 */
async function loadMemory(db, plantId, now = Date.now()) {
  const empty = { current: [], recurring: [], changed: [] };
  if (!plantId) return empty;

  let snap;
  try {
    snap = await factsRef(db, plantId).orderBy('statedAt', 'desc').limit(200).get();
  } catch (e) {
    console.warn('⚠️ Memory: could not read facts:', e.message);
    return empty;
  }

  const all = snap.docs.map((d) => ({ id: d.id, ...d.data() })).filter((f) => isKnownKind(f.kind));
  const current = all.filter((f) => isCurrent(f, now));

  // A symptom seen more than once is a pattern, and the pattern is the
  // diagnosis. Counted over history, not over what is current — by the time the
  // third episode starts, the first two have long aged out.
  const symptomCounts = {};
  for (const f of all.filter((f) => f.kind === 'symptom')) {
    const key = String(f.text || '').toLowerCase().slice(0, 40);
    (symptomCounts[key] = symptomCounts[key] || []).push(f);
  }
  const recurring = Object.values(symptomCounts)
    .filter((group) => group.length > 1)
    .map((group) => ({
      text: group[0].text,
      count: group.length,
      lastAt: group[0].statedAt,
      firstAt: group[group.length - 1].statedAt,
    }));

  // Configuration that has moved around says something on its own: a plant
  // relocated four times has not found its spot yet.
  const changed = Object.entries(
    all.filter((f) => FACT_KINDS[f.kind]?.single)
      .reduce((acc, f) => {
        (acc[f.kind] = acc[f.kind] || []).push(f);
        return acc;
      }, {}),
  )
    .filter(([, group]) => group.length > 1)
    .map(([kind, group]) => ({ kind, count: group.length, lastAt: group[0].statedAt }));

  return { current, recurring, changed };
}

// ── Writing ─────────────────────────────────────────────────────────

/**
 * Records what the owner said, superseding the previous value where the kind
 * only has one.
 *
 * Superseding marks rather than deletes: the old value is what makes the
 * history above readable, and the user's own delete is a separate act with a
 * different meaning.
 */
async function recordFacts(db, plantId, facts, { source = 'chat', topic = null } = {}) {
  if (!plantId || !Array.isArray(facts) || !facts.length) return [];

  const clean = facts
    .filter((f) => f && isKnownKind(f.kind))
    .map((f) => ({
      kind: f.kind,
      text: String(f.text || '').trim().slice(0, 240),
      lang: f.lang || null,
    }))
    .filter((f) => f.text.length > 2)
    .slice(0, 5); // a single turn cannot plausibly establish more than this

  if (!clean.length) return [];

  const ref = factsRef(db, plantId);
  const nowIso = new Date().toISOString();
  const batch = db.batch();

  for (const fact of clean) {
    if (FACT_KINDS[fact.kind].single) {
      try {
        const prior = await ref
          .where('kind', '==', fact.kind)
          .where('supersededAt', '==', null)
          .get();
        for (const doc of prior.docs) {
          batch.update(doc.ref, { supersededAt: nowIso });
        }
      } catch (e) {
        console.warn(`⚠️ Memory: could not supersede ${fact.kind}:`, e.message);
      }
    }

    batch.set(ref.doc(), {
      kind: fact.kind,
      text: fact.text,
      lang: fact.lang,
      source,
      topic,
      statedAt: nowIso,
      supersededAt: null,
    });
  }

  await batch.commit();
  return clean;
}

// ── Derived habits ──────────────────────────────────────────────────

/** Below this many waterings there is no pattern, only a couple of events. */
const HABIT_MIN_EVENTS = 4;

/** Average drift under this is punctuality, not a habit worth mentioning. */
const HABIT_MIN_DRIFT_DAYS = 1.5;

/**
 * How the owner actually waters, as opposed to how they were told to.
 *
 * The app has always known this — every watering is timestamped — and has never
 * once used it. Someone who waters two days early every single time is not
 * following a nine-day plan, and advice that assumes they are will keep being
 * wrong in the same direction.
 *
 * Derived on read rather than stored as a fact: it is a summary of events that
 * are already recorded, and writing it down would create a second copy that can
 * disagree with them. Facts are for what only the owner can tell us.
 */
function wateringHabit(plant = {}, events = []) {
  const interval = Number(plant.wateringIntervalDays);
  if (!Number.isFinite(interval) || interval <= 0) return null;

  const times = events
    .map((e) => Date.parse(e.timestamp))
    .filter((t) => !Number.isNaN(t))
    .sort((a, b) => a - b);
  if (times.length < HABIT_MIN_EVENTS) return null;

  const gaps = [];
  for (let i = 1; i < times.length; i += 1) {
    gaps.push((times[i] - times[i - 1]) / 86400000);
  }
  // A gap longer than three cycles is a holiday or a lapse, not a rhythm.
  const rhythm = gaps.filter((g) => g > 0 && g < interval * 3);
  if (rhythm.length < HABIT_MIN_EVENTS - 1) return null;

  const average = rhythm.reduce((a, b) => a + b, 0) / rhythm.length;
  const drift = average - interval;
  if (Math.abs(drift) < HABIT_MIN_DRIFT_DAYS) return null;

  return {
    averageGapDays: Math.round(average * 10) / 10,
    driftDays: Math.round(drift * 10) / 10,
    early: drift < 0,
    samples: rhythm.length,
  };
}

// ── Summary ─────────────────────────────────────────────────────────

/**
 * Two or three lines saying what this plant's life looks like.
 *
 * A projection of the facts, not a thing kept alongside them. That distinction
 * is the whole design: a summary the model writes and then re-writes drifts
 * away from what it was summarising, and nobody notices because there is
 * nothing to compare it against. Derived deterministically it cannot drift —
 * wrong summary means wrong facts, and the facts are on screen.
 *
 * Deliberately not generated by a model. There is no judgement here worth
 * paying for: the facts are already sentences, and the job is choosing which
 * ones describe the plant rather than the week.
 */
const SUMMARY_ORDER = [
  'placement',
  'container',
  'environment',
  'watering_habit',
  'constraint',
  'goal',
  'preference',
];

const SUMMARY_MAX_FACTS = 6;

function buildSummary(memory) {
  const current = (memory && memory.current) || [];
  if (!current.length) return null;

  const rank = (fact) => {
    const i = SUMMARY_ORDER.indexOf(fact.kind);
    return i === -1 ? SUMMARY_ORDER.length : i;
  };

  // Standing conditions and habits only. A symptom belongs in the diagnosis,
  // not in the one-paragraph answer to "what is this plant like".
  const lines = current
    .filter((f) => SUMMARY_ORDER.includes(f.kind))
    .sort((a, b) => rank(a) - rank(b))
    .slice(0, SUMMARY_MAX_FACTS)
    .map((f) => String(f.text || '').trim())
    .filter(Boolean);

  return lines.length ? lines.join(' ') : null;
}

// ── Pending question ────────────────────────────────────────────────

/**
 * The one thing the assistant owes the owner an answer about.
 *
 * A health check runs outside the conversation, so when it finds something that
 * contradicts what the owner told us — a plastic pot where they said ceramic —
 * there is nobody to ask. It waits here until the next time they open the chat.
 *
 * Exactly one slot, and a new question replaces the old one. A queue would let
 * an assistant greet someone with a backlog of interrogations, and the case is
 * rare enough that losing the older question costs nothing.
 */
function memoryDoc(db, plantId) {
  return db.collection('plants').doc(plantId).collection('memory').doc('current');
}

async function setPendingQuestion(db, plantId, question) {
  if (!plantId || !question) return;
  try {
    await memoryDoc(db, plantId).set(
      { pendingQuestion: { text: String(question).slice(0, 240), askedAt: null,
                           raisedAt: new Date().toISOString() } },
      { merge: true },
    );
  } catch (e) {
    console.warn('⚠️ Memory: could not store pending question:', e.message);
  }
}

async function takePendingQuestion(db, plantId) {
  if (!plantId) return null;
  try {
    const snap = await memoryDoc(db, plantId).get();
    const pending = snap.exists ? snap.data().pendingQuestion : null;
    if (!pending || !pending.text) return null;
    // Cleared as it is handed over: asked once is the point, and leaving it
    // would have the assistant open every conversation with the same question.
    await memoryDoc(db, plantId).set({ pendingQuestion: null }, { merge: true });
    return pending.text;
  } catch (e) {
    console.warn('⚠️ Memory: could not read pending question:', e.message);
    return null;
  }
}

// ── Prompt block ────────────────────────────────────────────────────

function shortDate(iso) {
  return typeof iso === 'string' ? iso.slice(0, 10) : '';
}

/**
 * Memory as the model sees it, or null when there is nothing to say.
 *
 * Facts are ordered by what the current topic cares about and never filtered by
 * it: the whole argument for one assistant is that a watering question can be
 * answered with a lighting fact.
 */
function buildMemoryBlock(memory, topic) {
  if (!memory) return null;
  const { current = [], recurring = [], changed = [] } = memory;
  if (!current.length && !recurring.length && !memory.habit) return null;

  const priority = TOPIC_FACT_PRIORITY[topic] || [];
  const rank = (fact) => {
    const i = priority.indexOf(fact.kind);
    return i === -1 ? priority.length : i;
  };

  const lines = [...current]
    .sort((a, b) => rank(a) - rank(b) || String(b.statedAt).localeCompare(String(a.statedAt)))
    .slice(0, MAX_FACTS_IN_PROMPT)
    .map((f) => `- [${f.kind}, ${shortDate(f.statedAt)}] ${f.text}`);

  for (const r of recurring) {
    lines.push(`- [recurring] "${r.text}" reported ${r.count} times, last ${shortDate(r.lastAt)}`);
  }
  for (const c of changed) {
    lines.push(`- [${c.kind}] changed ${c.count} times, last ${shortDate(c.lastAt)}`);
  }
  if (memory.habit) {
    const h = memory.habit;
    lines.push(
      `- [watering_habit] waters every ${h.averageGapDays} days on average, ` +
      `${Math.abs(h.driftDays)} ${h.early ? 'earlier' : 'later'} than planned ` +
      `(${h.samples} waterings)`
    );
  }

  return lines.join('\n');
}

module.exports = {
  FACT_KINDS,
  wateringHabit,
  buildSummary,
  setPendingQuestion,
  takePendingQuestion,
  FACT_KIND_NAMES,
  TOPIC_FACT_PRIORITY,
  isKnownKind,
  isCurrent,
  loadMemory,
  recordFacts,
  buildMemoryBlock,
};
