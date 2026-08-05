/**
 * The narrow set of plant data the assistant may propose changing, and the
 * validation that keeps a proposal from being whatever the model felt like.
 *
 * Two separate ideas live behind this list.
 *
 * The owner's own statements are recorded silently — being asked to confirm
 * something you just said is absurd. What needs confirming is the *conclusion*
 * drawn from it: moving a plant to a darker window is a fact, stretching the
 * watering schedule from nine days to eleven is a consequence, and that one
 * changes when the reminders fire. So the flow is: fact in silently, derived
 * change out as a card.
 *
 * The whitelist is a whitelist because the failure is asymmetric. Nothing here
 * is worse than a wrong number the owner can see and fix in the same card. The
 * name, the photo, watering events, anything to do with the subscription — a
 * wrong write there is either destructive or invisible, so the model is not
 * given the vocabulary to ask for it.
 */

const PLACEMENTS = ['south', 'east', 'north', 'room', 'balcony', 'bath'];
const POT_MATERIALS = ['plastic', 'ceramic', 'terracotta', 'unknown'];

/** Longest pause worth honouring. Beyond this the owner has effectively left. */
const MAX_PAUSE_DAYS = 120;

const PROPOSABLE_FIELDS = {
  placement: { type: 'enum', values: PLACEMENTS },
  potMaterial: { type: 'enum', values: POT_MATERIALS },
  potDiameterCm: { type: 'int', min: 4, max: 100 },
  hasDrainage: { type: 'bool' },
  nearHeatSource: { type: 'bool' },
  // Clamped to the same range the analyser is held to, so a proposal cannot
  // reach a value the rest of the system treats as impossible.
  wateringIntervalDays: { type: 'int', min: 1, max: 60 },
  wateringAmountMl: { type: 'int', min: 50, max: 2500 },
  species: { type: 'string', max: 80 },
  // Set only through a confirmed proposal — there is no toggle for it in the
  // app. An absence is agreed in conversation or not at all.
  tasksPausedUntil: { type: 'date', maxDaysAhead: MAX_PAUSE_DAYS },
};

/** Compact shape handed to the model, so it does not have to guess types. */
const PROPOSABLE_FIELDS_HINT = Object.fromEntries(
  Object.entries(PROPOSABLE_FIELDS).map(([field, spec]) => {
    switch (spec.type) {
      case 'enum': return [field, spec.values.join('|')];
      case 'int': return [field, `integer ${spec.min}-${spec.max}`];
      case 'bool': return [field, 'true|false'];
      case 'date': return [field, `ISO date, at most ${spec.maxDaysAhead} days ahead`];
      default: return [field, `string, max ${spec.max} chars`];
    }
  }),
);

function coerce(spec, raw) {
  switch (spec.type) {
    case 'enum': {
      const value = String(raw).trim().toLowerCase();
      return spec.values.includes(value) ? value : null;
    }
    case 'int': {
      const value = Math.round(Number(raw));
      if (!Number.isFinite(value)) return null;
      return value >= spec.min && value <= spec.max ? value : null;
    }
    case 'bool': {
      if (typeof raw === 'boolean') return raw;
      if (raw === 'true') return true;
      if (raw === 'false') return false;
      return null;
    }
    case 'date': {
      const at = Date.parse(raw);
      if (Number.isNaN(at)) return null;
      const daysAhead = (at - Date.now()) / 86400000;
      // A pause that has already ended is not a pause, and one a year out is a
      // typo rather than a holiday.
      if (daysAhead <= 0 || daysAhead > spec.maxDaysAhead) return null;
      return new Date(at).toISOString();
    }
    default: {
      const value = String(raw).trim().slice(0, spec.max);
      return value.length ? value : null;
    }
  }
}

/**
 * Turns whatever the model returned into a proposal worth showing, or null.
 *
 * `current` is carried alongside so the card can say "9 days → 11 days" rather
 * than just asserting the new value, and so a proposal that changes nothing can
 * be dropped here instead of arriving as a card the owner has to dismiss.
 */
function sanitizeProposal(raw, plant = {}) {
  if (!raw || typeof raw !== 'object') return null;

  const field = String(raw.field || '').trim();
  const spec = PROPOSABLE_FIELDS[field];
  if (!spec) return null;

  const value = coerce(spec, raw.value);
  if (value === null) return null;

  const current = plant[field] ?? null;
  if (current !== null && String(current) === String(value)) return null;

  const reason = String(raw.reason || '').trim().slice(0, 200);
  if (!reason) return null;

  return { field, from: current, to: value, reason };
}

/** Applies a proposal the owner has confirmed. Assumes it has been sanitized. */
function proposalUpdate(proposal) {
  return { [proposal.field]: proposal.to };
}

/**
 * Whether a confirmed change makes the standing plan stale.
 *
 * Only the inputs the plan is actually derived from count. A paused schedule
 * changes when reminders fire, not what the plant needs, so it does not trigger
 * a rewrite of the care text — the point of the fingerprint is that identical
 * inputs never pay for a regeneration.
 */
const PLAN_INPUTS = [
  'placement',
  'potMaterial',
  'potDiameterCm',
  'hasDrainage',
  'nearHeatSource',
  'species',
];

function invalidatesPlan(field) {
  return PLAN_INPUTS.includes(field);
}

/** Whether a confirmed change means the scheduled chores have to be rebuilt. */
function invalidatesSchedule(field) {
  return ['wateringIntervalDays', 'wateringAmountMl', 'tasksPausedUntil'].includes(field);
}

module.exports = {
  PROPOSABLE_FIELDS,
  PROPOSABLE_FIELDS_HINT,
  PLAN_INPUTS,
  MAX_PAUSE_DAYS,
  sanitizeProposal,
  proposalUpdate,
  invalidatesPlan,
  invalidatesSchedule,
};
