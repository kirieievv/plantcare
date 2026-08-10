/**
 * Weather, stage 1: where the user is and what it is like there (SPEC 12).
 *
 * Two deliberate limits, both from the spec:
 *
 *   1. No thresholds. Nothing here says "above 32 °C water a day earlier".
 *      The agent already knows the species, the pot diameter, the material and
 *      the placement from the quiz — it can weigh the weather against all of
 *      that better than a constant can, and changing its mind then costs a
 *      prompt rather than a release.
 *
 *   2. No tasks. Weather reaches the agent as context and stops there. The
 *      watering schedule is untouched.
 *
 * Everything is in Celsius in here and in the prompt. Fahrenheit exists only at
 * the moment of drawing a label, and only for the United States.
 */

const admin = require('firebase-admin');

/**
 * How long a city's weather is worth reusing when nobody asked for it.
 *
 * Was three hours, which is long enough for the temperature on the header to
 * be visibly wrong. An hour costs nothing worth counting: the cache is keyed by
 * city, so the outbound calls scale with how many cities the users are in, not
 * with how many users there are or how often they open the app.
 */
const WEATHER_TTL_MS = 60 * 60 * 1000;

/**
 * How long it is worth reusing when the user pulled the screen down.
 *
 * A gesture that hands back the same number it already showed reads as broken,
 * so the bar for refetching drops. It does not drop to zero: nothing stops a
 * person pulling once a second, and this is what keeps that from becoming a
 * request per pull.
 */
const WEATHER_FORCED_TTL_MS = 10 * 60 * 1000;

/** Coordinates are rounded to this many decimals — ~1 km, enough for weather. */
const COORD_PRECISION = 2;

/**
 * One shared record per city, not per user and not per plant.
 *
 * Two neighbours asking on the same morning is one request upstream. The key is
 * the rounded coordinate pair, which is also why the rounding exists: at two
 * decimals it identifies a city, not a person.
 */
function cityKeyOf(lat, lon) {
  return `${round(lat)}_${round(lon)}`;
}

function round(value) {
  return Number(Number(value).toFixed(COORD_PRECISION));
}

/** Minimal JSON GET. Rejects rather than throwing inside the callback. */
function getJson(url, timeoutMs = 6000) {
  const https = require('https');
  return new Promise((resolve, reject) => {
    const req = https.get(
      url,
      { headers: { 'User-Agent': 'BotanlyApp/1.0' } },
      (resp) => {
        let data = '';
        resp.on('data', (chunk) => {
          data += chunk;
        });
        resp.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`bad JSON from ${url}: ${e.message}`));
          }
        });
      }
    );
    req.on('error', reject);
    req.setTimeout(timeoutMs, () => {
      req.destroy(new Error(`timeout after ${timeoutMs}ms: ${url}`));
    });
  });
}

/**
 * The caller's public IP, as seen through Cloud Functions' proxy.
 *
 * `x-forwarded-for` is a chain; the client is the first entry. Falls back to
 * the socket address for local runs.
 */
function clientIpOf(req) {
  const chain = String(req.headers['x-forwarded-for'] || '');
  const first = chain.split(',')[0].trim();
  return first || req.socket?.remoteAddress || '';
}

/**
 * City from IP. No permission prompt, on purpose (SPEC 3.1): a location dialog
 * on first launch costs a slice of sign-ups, and for weather the accuracy of an
 * IP lookup is plenty.
 *
 * Returns null when the provider cannot place the address — a datacentre IP or
 * a local run. The caller then shows the date alone.
 */
async function lookupCityByIp(ip, language = 'en') {
  if (!ip || ip.startsWith('127.') || ip === '::1') return null;

  // ip-api's free tier: no key, and it returns the timezone, which we need for
  // knowing when the user's morning is.
  const url =
    `http://ip-api.com/json/${encodeURIComponent(ip)}` +
    `?fields=status,country,countryCode,city,lat,lon,timezone&lang=${encodeURIComponent(language)}`;

  const http = require('http');
  const body = await new Promise((resolve, reject) => {
    const req = http.get(url, (resp) => {
      let data = '';
      resp.on('data', (c) => {
        data += c;
      });
      resp.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    });
    req.on('error', reject);
    req.setTimeout(6000, () => req.destroy(new Error('ip lookup timeout')));
  });

  if (!body || body.status !== 'success' || !body.city) return null;

  return {
    city: body.city,
    countryCode: body.countryCode || null,
    lat: round(body.lat),
    lon: round(body.lon),
    timezone: body.timezone || null,
  };
}

/** Open-Meteo's WMO code, collapsed to the four states the design draws. */
function conditionFromCode(code) {
  if (code === 0 || code === 1) return 'sun';
  if (code >= 71 && code <= 77) return 'cold'; // snow
  if (code >= 85 && code <= 86) return 'cold';
  if (code >= 51 && code <= 67) return 'rain';
  if (code >= 80 && code <= 82) return 'rain';
  if (code >= 95) return 'rain'; // thunderstorm
  return 'cloud';
}

/**
 * Whether a cached record still counts as current for the age being asked for.
 *
 * A separate function because the same record has two answers: fresh enough for
 * someone who just opened the app, stale for someone who pulled the screen down
 * asking for a new number. That is the whole difference between the two paths,
 * and inside `weatherForCity` it could only be exercised with a live Firestore.
 *
 * `now` is a parameter so the boundaries can be asked about directly rather
 * than by waiting an hour.
 */
function isFresh(cached, maxAgeMs, now = Date.now()) {
  const at = millisOf(cached && cached.fetchedAt);
  return at !== null && now - at < maxAgeMs;
}

/** Milliseconds from a Firestore Timestamp or a plain number, else null. */
function millisOf(v) {
  if (v === null || v === undefined) return null;
  const at = typeof v.toMillis === 'function' ? v.toMillis() : Number(v);
  return Number.isFinite(at) ? at : null;
}

/**
 * How long the provider must behave before a run of failures is forgotten.
 *
 * Not reset on the first success: a provider failing one call in three would
 * then always read zero, because the successes in between keep wiping it. The
 * count is meant to survive exactly that.
 */
const HEALTH_QUIET_MS = 60 * 60 * 1000;

/**
 * What the health record should become after one call to the provider.
 *
 * Kept apart from the writing so it can be asked about directly. `failures`
 * comes back as the string 'increment' rather than a Firestore sentinel — the
 * decision is which of the two to do, and that is testable without a database.
 */
function providerHealthUpdate({ ok, error, previous, now = Date.now() }) {
  if (!ok) {
    return {
      lastFailAt: now,
      lastError: String(error || 'unknown').slice(0, 200),
      failures: 'increment',
    };
  }

  const lastFailAt = millisOf(previous && previous.lastFailAt);
  const settled = lastFailAt === null || now - lastFailAt >= HEALTH_QUIET_MS;
  return settled ? { lastOkAt: now, failures: 0 } : { lastOkAt: now };
}

/**
 * Writes down whether the provider answered, so an outage is noticeable.
 *
 * The app survives losing the weather: the header falls back to the date alone
 * and the watering schedule to its plain interval. That is the point — and also
 * the problem, because nothing about it is visible. A console warning lands in
 * Cloud Logging, which nobody opens, so the feature could quietly disappear for
 * weeks.
 *
 * Failing to write this must never cost the caller its answer: it is a report
 * about the request, not part of it.
 */
async function recordProviderOutcome({ ok, error }) {
  try {
    const db = admin.firestore();
    const ref = db.collection('system').doc('weather_health');
    const previous = (await ref.get()).data() || null;

    const update = providerHealthUpdate({ ok, error, previous });
    const write = { ...update };
    if (write.lastOkAt) write.lastOkAt = admin.firestore.Timestamp.now();
    if (write.lastFailAt) write.lastFailAt = admin.firestore.Timestamp.now();
    if (write.failures === 'increment') {
      write.failures = admin.firestore.FieldValue.increment(1);
    }

    await ref.set(write, { merge: true });
  } catch (e) {
    console.warn(`⚠️ weather: health write failed: ${e.message}`);
  }
}

/**
 * Current weather plus a week of highs and lows, from the shared city cache.
 *
 * A stale record beats no record: if the provider is down we hand back whatever
 * was cached last. The home screen must never wait on this to draw.
 */
async function weatherForCity(lat, lon, { maxAgeMs = WEATHER_TTL_MS } = {}) {
  const db = admin.firestore();
  const key = cityKeyOf(lat, lon);
  const ref = db.collection('weather').doc(key);

  let cached = null;
  try {
    const snap = await ref.get();
    if (snap.exists) cached = snap.data();
  } catch (e) {
    console.warn(`⚠️ weather: cache read failed for ${key}: ${e.message}`);
  }

  if (isFresh(cached, maxAgeMs)) return cached;

  try {
    const url =
      'https://api.open-meteo.com/v1/forecast' +
      `?latitude=${round(lat)}&longitude=${round(lon)}` +
      '&current=temperature_2m,relative_humidity_2m,weather_code' +
      '&daily=temperature_2m_max,temperature_2m_min,weather_code' +
      '&forecast_days=7&timezone=auto';
    const body = await getJson(url);

    const current = body.current || {};
    const daily = body.daily || {};
    const record = {
      // Always Celsius in storage and in the prompt (SPEC 6.1). The display
      // layer is the only place that ever converts.
      tempC: Number(current.temperature_2m),
      humidity: Number(current.relative_humidity_2m),
      condition: conditionFromCode(Number(current.weather_code)),
      forecast: (daily.time || []).slice(0, 7).map((date, i) => ({
        date,
        maxC: Number(daily.temperature_2m_max?.[i]),
        minC: Number(daily.temperature_2m_min?.[i]),
        condition: conditionFromCode(Number(daily.weather_code?.[i])),
      })),
      fetchedAt: admin.firestore.Timestamp.now(),
    };

    if (!Number.isFinite(record.tempC)) {
      throw new Error('provider returned no temperature');
    }

    await ref.set(record, { merge: true });
    await recordProviderOutcome({ ok: true });
    return record;
  } catch (e) {
    console.warn(`⚠️ weather: fetch failed for ${key}: ${e.message}`);
    await recordProviderOutcome({ ok: false, error: e.message });
    // Stale is better than blank; blank is better than an error.
    return cached || null;
  }
}

/** The user's stored location, or null if they have none yet. */
async function locationOf(userId) {
  if (!userId) return null;
  try {
    const snap = await admin.firestore().collection('users').doc(userId).get();
    const loc = snap.data()?.geo;
    if (!loc || !Number.isFinite(loc.lat) || !Number.isFinite(loc.lon)) {
      return null;
    }
    return loc;
  } catch (e) {
    console.warn(`⚠️ weather: could not read location for ${userId}: ${e}`);
    return null;
  }
}

/**
 * City suggestions for a typed prefix, in the user's language.
 *
 * Doubles as the geocoder: each hit carries its own coordinates, which is what
 * makes a manually chosen city actually change the weather. Typing a name
 * without resolving it would store a label and keep the old sky.
 *
 * No dictionary of our own (SPEC 6.2): the provider localises the names, so
 * "Munich" comes back as "Мюнхен" in Russian and "München" in German without us
 * maintaining a translation table that would rot.
 */
async function searchCities(query, language = 'en', count = 6) {
  const name = String(query || '').trim();
  if (name.length < 2) return [];

  const url =
    'https://geocoding-api.open-meteo.com/v1/search' +
    `?name=${encodeURIComponent(name)}` +
    `&count=${Math.min(Math.max(count, 1), 10)}` +
    `&language=${encodeURIComponent(language)}&format=json`;

  const body = await getJson(url);
  return (body.results || []).map((r) => ({
    city: r.name,
    // Region and country disambiguate the four Springfields.
    region: r.admin1 || null,
    country: r.country || null,
    countryCode: r.country_code || null,
    lat: round(r.latitude),
    lon: round(r.longitude),
    timezone: r.timezone || null,
  }));
}

const CONDITION_WORDS = {
  sun: 'clear',
  cloud: 'overcast',
  rain: 'rain',
  cold: 'snow or freezing',
};

/**
 * The weather as one short block for the agent, or null when there is none.
 *
 * Prose rather than raw fields, for the same reason the growing conditions are
 * written out: the model reasons about "36 °C, clear, humidity 28%" far better
 * than about a JSON object, and it costs a line.
 *
 * No interpretation here. Whether 36 °C matters for this plant is the agent's
 * call — it can see the pot, the placement and the species.
 */
function describeWeather(weather, location) {
  if (!weather || !Number.isFinite(weather.tempC)) return null;

  const where = location?.city ? ` in ${location.city}` : '';
  const parts = [
    `Weather${where}: ${Math.round(weather.tempC)} °C, ` +
      `${CONDITION_WORDS[weather.condition] || weather.condition}` +
      (Number.isFinite(weather.humidity)
        ? `, humidity ${Math.round(weather.humidity)}%`
        : '') +
      '.',
  ];

  const days = (weather.forecast || []).filter((d) => Number.isFinite(d.maxC));
  if (days.length >= 3) {
    const highs = days.map((d) => d.maxC);
    const lows = days.map((d) => d.minC).filter(Number.isFinite);
    parts.push(
      `Next ${days.length} days: ${Math.round(Math.min(...lows))}–` +
        `${Math.round(Math.max(...highs))} °C.`
    );
  }

  return parts.join(' ');
}

/** The subset stored alongside a health check (SPEC 5.2). */
function weatherSnapshot(weather) {
  if (!weather || !Number.isFinite(weather.tempC)) return null;
  return {
    tempC: weather.tempC,
    condition: weather.condition || null,
    humidity: Number.isFinite(weather.humidity) ? weather.humidity : null,
    fetchedAt: weather.fetchedAt || admin.firestore.Timestamp.now(),
  };
}

module.exports = {
  WEATHER_TTL_MS,
  WEATHER_FORCED_TTL_MS,
  HEALTH_QUIET_MS,
  isFresh,
  providerHealthUpdate,
  cityKeyOf,
  clientIpOf,
  conditionFromCode,
  describeWeather,
  locationOf,
  lookupCityByIp,
  searchCities,
  weatherForCity,
  weatherSnapshot,
};
