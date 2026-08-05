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
  if (!current.length && !recurring.length) return null;

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

  return lines.join('\n');
}

module.exports = {
  FACT_KINDS,
  FACT_KIND_NAMES,
  TOPIC_FACT_PRIORITY,
  isKnownKind,
  isCurrent,
  loadMemory,
  recordFacts,
  buildMemoryBlock,
};
