/**
 * How much sooner or later a plant needs water than its plan says, today.
 *
 * The plan is a baseline for the plant: species, pot, drainage, where it
 * stands. It is deliberately stable — regenerating it as conditions wobble is
 * how the sheet ends up disagreeing with the paragraph underneath it. But a
 * baseline is wrong on the days that matter: soil in a 34 °C week does not dry
 * at the pace it does at 18 °C, and an owner following the calendar waters a
 * dry plant three days late.
 *
 * So weather never touches the plan. It produces an offset on top of it,
 * computed here by rule, stored nowhere, and recomputed from scratch whenever
 * anything asks. Nothing to drift, nothing to invalidate.
 *
 * The numbers are intentionally coarse. This is not a soil model — it is the
 * difference between "in four days" and "in three", which is the resolution the
 * owner acts at anyway. Being roughly right daily beats being precisely wrong
 * about a plant nobody has looked at.
 */

/** Below this the adjustment is noise; the schedule stays where it is. */
const MIN_SHIFT_DAYS = 1;

/** Ceiling on the shift either way, so no forecast can rewrite the plan. */
const MAX_SHIFT_DAYS = 3;

/**
 * Temperature the baseline assumes. Indoor plants live indoors, so this is
 * about how much the outside is pulling the room away from ordinary room
 * temperature, not the absolute reading.
 */
const BASELINE_TEMP_C = 21;

/**
 * Fraction of the interval gained or lost per degree away from the baseline.
 *
 * Roughly 3% per degree: a 10 °C heatwave takes about a third off the interval,
 * which matches the "every 9 days becomes every 6" that people report and is
 * small enough that a mild day changes nothing after rounding.
 */
const PER_DEGREE = 0.03;

/** How much of the weather reaches a plant that lives inside. */
const INDOOR_DAMPING = 0.45;

/**
 * A plant on a balcony is outdoors: the weather is its weather, not a hint
 * about its room.
 */
const OUTDOOR_PLACEMENTS = ['balcony'];

/**
 * Returns `{ days, reasonKey, tempC }`, or null when nothing should move.
 *
 * `reasonKey` is a key rather than a sentence: the reason is shown to the owner
 * next to a date that moved, so it has to arrive in their language, and this
 * module has no business knowing which that is.
 */
function wateringAdjustment(plant = {}, weather = null) {
  const baseInterval = Number(plant.wateringIntervalDays);
  if (!Number.isFinite(baseInterval) || baseInterval <= 0) return null;
  if (!weather || !Number.isFinite(weather.tempC)) return null;

  const outdoor = OUTDOOR_PLACEMENTS.includes(plant.placement);
  const damping = outdoor ? 1 : INDOOR_DAMPING;

  // Cold outside means the heating is on, not that the room is cold. For a
  // plant standing over a radiator the outside reading says the opposite of
  // what it says for one that is not: the colder it gets, the drier its air.
  // Reading it the ordinary way produced "freezing outside, so water less
  // often" for a plant sitting on the radiator, which is backwards.
  const heatingOn = plant.nearHeatSource === true && weather.tempC < 12;

  let factor = heatingOn
    ? 0.2
    : (weather.tempC - BASELINE_TEMP_C) * PER_DEGREE * damping;

  // Damp air slows drying; dry air speeds it. Small on purpose — humidity
  // outside says less about a heated room than temperature does, and says
  // nothing at all about one with the heating running.
  if (!heatingOn && Number.isFinite(weather.humidity)) {
    factor -= ((weather.humidity - 55) / 100) * 0.2 * damping;
  }

  // Warmer than baseline shortens the interval, so the sign inverts here.
  const shiftedInterval = baseInterval * (1 - factor);
  const rawShift = shiftedInterval - baseInterval;

  const days = Math.max(
    -MAX_SHIFT_DAYS,
    Math.min(MAX_SHIFT_DAYS, Math.round(rawShift)),
  );
  if (Math.abs(days) < MIN_SHIFT_DAYS) return null;

  return {
    days,
    tempC: Math.round(weather.tempC),
    // Earlier is the case worth naming precisely — it is the one where doing
    // nothing harms the plant.
    reasonKey: days < 0 ? (heatingOn ? 'heating' : 'heat') : 'cool',
  };
}

/**
 * The interval to actually schedule against, weather included.
 *
 * Clamped to the same 1-60 the rest of the system treats as possible, so an
 * adjustment can never produce a date the scheduler would refuse.
 */
function adjustedInterval(plant = {}, weather = null) {
  const base = Number(plant.wateringIntervalDays);
  if (!Number.isFinite(base) || base <= 0) return null;
  const adjustment = wateringAdjustment(plant, weather);
  if (!adjustment) return base;
  return Math.max(1, Math.min(60, base + adjustment.days));
}

module.exports = {
  MIN_SHIFT_DAYS,
  MAX_SHIFT_DAYS,
  BASELINE_TEMP_C,
  wateringAdjustment,
  adjustedInterval,
};
