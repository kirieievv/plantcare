const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai');
const crypto = require('crypto');
const cors = require('cors')({ origin: true });

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Отправка приветственного письма после регистрации.
 * При создании пользователя в Auth записываем письмо в коллекцию mail —
 * если установлено расширение Firebase "Trigger Email from Firestore", оно отправит письмо.
 * Документация: https://firebase.google.com/products/extensions/firestore-send-email
 */
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  const email = user.email;
  if (!email) return;

  let displayName = user.displayName || null;
  if (!displayName) {
    try {
      const userDoc = await admin.firestore().collection('users').doc(user.uid).get();
      if (userDoc.exists) displayName = userDoc.data().name || 'there';
    } catch (_) {}
  }
  const name = displayName || 'there';

  const subject = 'Welcome to Plant Care! 🌱';
  const html = `
    <h2>Hi ${name}!</h2>
    <p>Thanks for signing up. We're glad to have you.</p>
    <p>Start by adding your first plant and we'll help you with watering reminders and care tips.</p>
    <p>— Plant Care team</p>
  `.trim();
  const text = `Hi ${name}! Thanks for signing up. Start by adding your first plant. — Plant Care team`;

  await admin.firestore().collection('mail').add({
    to: email,
    message: {
      subject,
      text,
      html,
    },
  });
  console.log('Welcome email queued for:', email);
});

const PASSWORD_RESET_CODE_TTL_MS = 10 * 60 * 1000; // 10 minutes
const PASSWORD_RESET_MAX_ATTEMPTS = 5;

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function hashPin(pin, salt) {
  return crypto.createHash('sha256').update(`${pin}:${salt}`).digest('hex');
}

function buildPasswordResetPinEmail(email, pin) {
  const subject = 'Your Plant Care password reset code';
  const text = `Use this code to reset your password: ${pin}. The code expires in 10 minutes.`;
  const html = `
    <h2>Password reset code</h2>
    <p>Use this verification code to reset your password:</p>
    <p style="font-size:28px;font-weight:700;letter-spacing:4px;">${pin}</p>
    <p>This code expires in 10 minutes.</p>
    <p>If you did not request this, you can ignore this email.</p>
    <p>- Plant Care team</p>
  `.trim();

  return {
    to: email,
    message: { subject, text, html },
  };
}

exports.requestPasswordResetPin = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ success: false, error: 'Method not allowed' });
      }

      const email = normalizeEmail(req.body?.email);
      if (!isValidEmail(email)) {
        return res.status(400).json({
          success: false,
          error: 'Please enter a valid email.',
        });
      }

      let userRecord;
      try {
        userRecord = await admin.auth().getUserByEmail(email);
      } catch (e) {
        if (e && e.code === 'auth/user-not-found') {
          return res.status(404).json({
            success: false,
            error: 'No account found with this email.',
          });
        }
        throw e;
      }

      const db = admin.firestore();
      const nowMs = Date.now();
      const expiresAtMs = nowMs + PASSWORD_RESET_CODE_TTL_MS;
      const pin = String(crypto.randomInt(100000, 1000000));
      const salt = crypto.randomBytes(16).toString('hex');
      const pinHash = hashPin(pin, salt);
      const requestIp = String(req.headers['x-forwarded-for'] || req.ip || '').slice(0, 120);

      await db.collection('password_reset_codes').add({
        uid: userRecord.uid,
        emailLower: email,
        pinHash,
        salt,
        attempts: 0,
        maxAttempts: PASSWORD_RESET_MAX_ATTEMPTS,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAtMs: nowMs,
        expiresAtMs,
        expiresAt: admin.firestore.Timestamp.fromMillis(expiresAtMs),
        requestedIp: requestIp,
      });

      await db.collection('mail').add(buildPasswordResetPinEmail(email, pin));
      return res.json({
        success: true,
        message: 'Verification code has been sent.',
      });
    } catch (error) {
      console.error('requestPasswordResetPin error:', error);
      return res.status(500).json({
        success: false,
        error: 'Could not process password reset request right now.',
      });
    }
  });
});

exports.verifyPasswordResetPin = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ success: false, error: 'Method not allowed' });
      }

      const email = normalizeEmail(req.body?.email);
      const pin = String(req.body?.pin || '').trim();
      if (!isValidEmail(email) || !/^\d{6}$/.test(pin)) {
        return res.status(400).json({ success: false, error: 'Invalid code or email.' });
      }

      const db = admin.firestore();
      const snap = await db.collection('password_reset_codes')
        .where('emailLower', '==', email)
        .limit(20)
        .get();

      const docs = [...snap.docs].sort((a, b) => {
        const aMs = Number(a.data()?.createdAtMs || 0);
        const bMs = Number(b.data()?.createdAtMs || 0);
        return bMs - aMs;
      });

      const nowMs = Date.now();
      const candidateDoc = docs.find((doc) => {
        const data = doc.data() || {};
        const isUsed = !!data.usedAt;
        const notExpired = Number(data.expiresAtMs || 0) > nowMs;
        return !isUsed && notExpired;
      });

      if (!candidateDoc) {
        return res.status(400).json({ success: false, error: 'Code is invalid or expired.' });
      }

      const data = candidateDoc.data() || {};
      const attempts = Number(data.attempts || 0);
      const maxAttempts = Number(data.maxAttempts || PASSWORD_RESET_MAX_ATTEMPTS);
      if (attempts >= maxAttempts) {
        return res.status(429).json({ success: false, error: 'Too many attempts. Request a new code.' });
      }

      const expectedHash = String(data.pinHash || '');
      const salt = String(data.salt || '');
      const submittedHash = hashPin(pin, salt);
      if (submittedHash !== expectedHash) {
        await candidateDoc.ref.update({
          attempts: attempts + 1,
          lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return res.status(400).json({ success: false, error: 'Code is invalid or expired.' });
      }

      return res.json({ success: true });
    } catch (error) {
      console.error('verifyPasswordResetPin error:', error);
      return res.status(500).json({
        success: false,
        error: 'Could not verify reset code right now.',
      });
    }
  });
});

exports.confirmPasswordResetPin = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ success: false, error: 'Method not allowed' });
      }

      const email = normalizeEmail(req.body?.email);
      const pin = String(req.body?.pin || '').trim();
      const newPassword = String(req.body?.newPassword || '');

      if (!isValidEmail(email) || !/^\d{6}$/.test(pin)) {
        return res.status(400).json({ success: false, error: 'Invalid code or email.' });
      }
      if (newPassword.length < 6) {
        return res.status(400).json({ success: false, error: 'Password must be at least 6 characters.' });
      }

      const db = admin.firestore();
      const snap = await db.collection('password_reset_codes')
        .where('emailLower', '==', email)
        .limit(20)
        .get();

      const docs = [...snap.docs].sort((a, b) => {
        const aMs = Number(a.data()?.createdAtMs || 0);
        const bMs = Number(b.data()?.createdAtMs || 0);
        return bMs - aMs;
      });

      const nowMs = Date.now();
      const candidateDoc = docs.find((doc) => {
        const data = doc.data() || {};
        const isUsed = !!data.usedAt;
        const notExpired = Number(data.expiresAtMs || 0) > nowMs;
        return !isUsed && notExpired;
      });

      if (!candidateDoc) {
        return res.status(400).json({ success: false, error: 'Code is invalid or expired.' });
      }

      const data = candidateDoc.data() || {};
      const attempts = Number(data.attempts || 0);
      const maxAttempts = Number(data.maxAttempts || PASSWORD_RESET_MAX_ATTEMPTS);
      if (attempts >= maxAttempts) {
        return res.status(429).json({ success: false, error: 'Too many attempts. Request a new code.' });
      }

      const expectedHash = String(data.pinHash || '');
      const salt = String(data.salt || '');
      const submittedHash = hashPin(pin, salt);
      if (submittedHash !== expectedHash) {
        await candidateDoc.ref.update({
          attempts: attempts + 1,
          lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return res.status(400).json({ success: false, error: 'Code is invalid or expired.' });
      }

      let userRecord;
      try {
        userRecord = await admin.auth().getUserByEmail(email);
      } catch (_) {
        return res.status(404).json({ success: false, error: 'Account not found.' });
      }

      await admin.auth().updateUser(userRecord.uid, { password: newPassword });
      await admin.auth().revokeRefreshTokens(userRecord.uid);
      await candidateDoc.ref.update({
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
        consumedIp: String(req.headers['x-forwarded-for'] || req.ip || '').slice(0, 120),
      });

      return res.json({ success: true });
    } catch (error) {
      console.error('confirmPasswordResetPin error:', error);
      return res.status(500).json({
        success: false,
        error: 'Could not reset password right now.',
      });
    }
  });
});

// Initialize OpenAI with API key from Firebase config
let openai;
async function initializeOpenAI() {
  if (!openai) {
    // Try to get API key from Firebase config
    const apiKey = functions.config().openai?.api_key;
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY is not configured in Firebase Functions');
    }
    openai = new OpenAI({
      apiKey: apiKey,
    });
  }
  return openai;
}

/**
 * Analyze plant photo using OpenAI GPT-4 Vision API
 */
/**
 * Get species-based fallback watering days when AI calculation fails
 * Uses plant name and profile to determine appropriate interval
 */
function getSpeciesBasedFallbackDays(plantName, plantProfile) {
  const nameLower = (plantName || '').toLowerCase();
  const profileLower = (plantProfile || '').toLowerCase();
  
  // Check profile first (most reliable)
  if (profileLower.includes('succulent')) {
    return profileLower.includes('large') ? 14 : 10;
  }
  if (profileLower.includes('tropical') || profileLower.includes('broadleaf')) {
    return 5;
  }
  if (profileLower.includes('herbaceous')) {
    return 4;
  }
  if (profileLower.includes('woody')) {
    return 7;
  }
  if (profileLower.includes('palm')) {
    return 10;
  }
  
  // Fallback to name-based detection if profile is missing
  const succulentKeywords = ['cactus', 'succulent', 'aloe', 'echeveria', 'sedum', 'crassula', 'haworthia'];
  const tropicalKeywords = ['monstera', 'philodendron', 'pothos', 'calathea', 'anthurium', 'peace lily', 'fiddle leaf'];
  const dryKeywords = ['snake plant', 'zz plant', 'sansevieria', 'zamioculcas'];
  
  if (succulentKeywords.some(kw => nameLower.includes(kw))) {
    return 10;
  }
  if (tropicalKeywords.some(kw => nameLower.includes(kw))) {
    return 5;
  }
  if (dryKeywords.some(kw => nameLower.includes(kw))) {
    return 14;
  }
  
  // Default fallback (should rarely be used)
  return 7;
}

function toIso(value) {
  if (!value) return null;
  try {
    if (typeof value === 'string') return value;
    if (value.toDate) return value.toDate().toISOString();
    if (value instanceof Date) return value.toISOString();
  } catch (_) {}
  return String(value);
}

async function loadHealthCheckAgentContext(plantId, userId) {
  const db = admin.firestore();
  const context = {
    plant: null,
    recentHealthChecks: [],
    recentWateringEvents: [],
    recentImageUrls: [],
  };

  if (!plantId || !userId) return context;

  // Plant snapshot
  try {
    const plantDoc = await db.collection('plants').doc(plantId).get();
    if (plantDoc.exists) {
      const plantData = plantDoc.data();
      if (!plantData.userId || plantData.userId === userId) {
        context.plant = {
          id: plantDoc.id,
          name: plantData.name || null,
          species: plantData.species || null,
          wateringAmountMl: plantData.wateringAmountMl || null,
          wateringIntervalDays: plantData.wateringIntervalDays || null,
          shouldWaterNow: plantData.shouldWaterNow === true,
          lastWateredAt: plantData.lastWateredAt || null,
          lastHealthCheck: plantData.lastHealthCheck || null,
          healthStatus: plantData.healthStatus || null,
        };
      }
    }
  } catch (e) {
    console.warn('⚠️ Agent context: failed to load plant document:', e.message);
  }

  // Recent health checks (for prior analysis + previous images)
  try {
    const checksSnap = await db
      .collection('health_checks')
      .where('plantId', '==', plantId)
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(12)
      .get();

    context.recentHealthChecks = checksSnap.docs.map((doc) => {
      const d = doc.data() || {};
      return {
        id: doc.id,
        timestamp: toIso(d.timestamp),
        status: d.status || null,
        message: d.message ? String(d.message).slice(0, 200) : null,
        imageUrl: d.imageUrl || null,
        metadata: d.metadata || null,
      };
    });

    context.recentImageUrls = context.recentHealthChecks
      .map((x) => x.imageUrl)
      .filter((url) => typeof url === 'string' && url.startsWith('http'))
      .slice(0, 10);
  } catch (e) {
    console.warn('⚠️ Agent context: failed to load health checks:', e.message);
  }

  // Recent watering events (do not add extra index dependency on userId)
  try {
    const eventsSnap = await db
      .collection('watering_events')
      .where('plantId', '==', plantId)
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();

    context.recentWateringEvents = eventsSnap.docs
      .map((doc) => doc.data() || {})
      .filter((d) => !d.userId || d.userId === userId)
      .map((d) => ({
        timestamp: toIso(d.timestamp),
        amountMl: d.amountMl ?? null,
      }));
  } catch (e) {
    console.warn('⚠️ Agent context: failed to load watering events:', e.message);
  }

  return context;
}

const HEALTH_CHECK_IMAGE_TIERS = [2, 5, 10];

function getPreviousImagesForTier(context, tierSize) {
  return (context.recentImageUrls || []).slice(0, Math.max(0, tierSize));
}

function toDateSafe(value) {
  if (!value) return null;
  try {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  } catch (_) {
    return null;
  }
}

function evaluateHealthCheckAgentResult(recommendations, context) {
  if (!recommendations || typeof recommendations !== 'object') {
    return { ok: false, reason: 'missing_recommendations' };
  }

  const wateringPlan = recommendations.watering_plan || null;
  if (!wateringPlan || wateringPlan.next_watering_in_days === undefined) {
    return { ok: false, reason: 'missing_watering_plan' };
  }

  const plantAssistant = recommendations.plant_assistant || null;
  if (!plantAssistant || !plantAssistant.status) {
    return { ok: false, reason: 'missing_plant_assistant' };
  }

  const reasonShort = wateringPlan.reason_short ? String(wateringPlan.reason_short).trim() : '';
  if (reasonShort.length < 8) {
    return { ok: false, reason: 'weak_reason_short' };
  }

  // Contradiction heuristic: if watered recently and soil is moist/wet, "water now" is likely unstable.
  try {
    const latestWatering = (context.recentWateringEvents || [])[0];
    const latestWateringDate = toDateSafe(latestWatering?.timestamp);
    const soilState = recommendations.soil?.visual_state || 'not_visible';
    const now = new Date();
    if (latestWateringDate) {
      const hoursSinceWatering = (now.getTime() - latestWateringDate.getTime()) / (1000 * 60 * 60);
      const veryRecent = hoursSinceWatering >= 0 && hoursSinceWatering <= 12;
      const moistOrWet = soilState === 'moist' || soilState === 'wet';
      const wantsWaterNow = wateringPlan.should_water_now === true;
      if (veryRecent && moistOrWet && wantsWaterNow) {
        return { ok: false, reason: 'contradiction_recent_watering_vs_soil' };
      }
    }
  } catch (_) {}

  return { ok: true, reason: 'accepted' };
}

function buildHealthCheckContentBlocks(promptText, currentImageUrl, previousImageUrls, isRetry) {
  const blocks = [
    {
      type: 'text',
      text: isRetry
        ? `CRITICAL: Return ONLY valid JSON. ${promptText}`
        : promptText,
    },
    {
      type: 'image_url',
      image_url: { url: currentImageUrl },
    },
  ];

  for (const previousUrl of previousImageUrls) {
    blocks.push({
      type: 'image_url',
      image_url: { url: previousUrl },
    });
  }
  return blocks;
}

function reasonToReadableText(reason) {
  const map = {
    accepted: 'Accepted: output passed quality checks.',
    missing_recommendations: 'Model output did not contain a valid recommendations object.',
    missing_watering_plan: 'Missing watering_plan.next_watering_in_days in model output.',
    missing_plant_assistant: 'Missing plant_assistant.status in model output.',
    weak_reason_short: 'watering_plan.reason_short is too short/low confidence.',
    contradiction_recent_watering_vs_soil: 'Potential contradiction: very recent watering + moist/wet soil but model suggests watering now.',
  };
  return map[reason] || `Unmapped quality reason: ${reason}`;
}

function buildHealthCheckDecisionTraceV2({
  attemptTrace = [],
  accepted = false,
  tierUsed = 2,
  escalationReason = null,
  context = {},
}) {
  const lines = [];
  lines.push('health-check-agent:v2');
  lines.push(
    `context_loaded: healthChecks=${(context.recentHealthChecks || []).length}, wateringEvents=${(context.recentWateringEvents || []).length}, previousImages=${(context.recentImageUrls || []).length}`
  );

  for (const row of attemptTrace) {
    lines.push(
      `attempt_${row.attempt}: tier=${row.tierSize}, prev_images=${row.previousImagesUsed}, accepted=${row.accepted}`
    );
    lines.push(`attempt_${row.attempt}_reason: ${reasonToReadableText(row.reason)}`);
  }

  lines.push(`final: accepted=${accepted}, tier_used=${tierUsed}, escalation_reason=${escalationReason || 'none'}`);
  return lines;
}

function hasOverwateringRiskSignal(recommendations) {
  try {
    const textChunks = [
      recommendations?.plant_assistant?.problem_name,
      recommendations?.plant_assistant?.problem_description,
      recommendations?.health_assessment,
      recommendations?.watering_plan?.reason_short,
      recommendations?.care_recommendations?.water,
      Array.isArray(recommendations?.specific_issues)
        ? recommendations.specific_issues.join(' ')
        : '',
    ];
    const text = textChunks
      .filter((x) => typeof x === 'string' && x.trim().length > 0)
      .join(' ')
      .toLowerCase();

    const riskMarkers = [
      'overwater',
      'over-water',
      'overwatering',
      'too much water',
      'excess water',
      'waterlogged',
      'water logging',
      'soggy',
      'root rot',
      'soil too wet',
      'wet soil',
      'stays wet',
    ];

    return riskMarkers.some((m) => text.includes(m));
  } catch (_) {
    return false;
  }
}

function enforceWateringConsistencyGuard(recommendations) {
  if (!recommendations || !recommendations.watering_plan) {
    return recommendations;
  }

  try {
    const plan = recommendations.watering_plan;
    const soilState = (recommendations.soil?.visual_state || '').toLowerCase();
    const moistureRaw = recommendations.soil?.moisture_current_pct;
    const moisturePct = Number(moistureRaw);
    const hasWetSoilSignal =
      soilState === 'wet' ||
      soilState === 'moist' ||
      (Number.isFinite(moisturePct) && moisturePct >= 65);
    const hasOverwaterSignal = hasOverwateringRiskSignal(recommendations);

    if ((hasOverwaterSignal || hasWetSoilSignal) && plan.should_water_now === true) {
      const currentDays = Number(plan.next_watering_in_days);
      const safeDays = Number.isFinite(currentDays) ? Math.max(2, currentDays) : 2;
      plan.should_water_now = false;
      plan.next_watering_in_days = Math.max(1, Math.min(60, safeDays));
      const baseReason =
        typeof plan.reason_short === 'string' && plan.reason_short.trim().length > 0
          ? plan.reason_short.trim()
          : 'Watering decision adjusted by safety guardrail.';
      plan.reason_short = `${baseReason} Guardrail: delayed watering due to wet/overwatering risk.`;
    }
  } catch (e) {
    console.warn('⚠️ Failed to apply watering consistency guard:', e.message);
  }

  return recommendations;
}

function normalizeRecommendations(recommendations, reqBody = {}) {
  if (!recommendations) return recommendations;
  try {
    let intervalDays = null;
    let shouldWaterNow = false;
    let reasonShort = '';

    // PRIORITY 1: new watering_plan structure
    let rawAmountMl = null;
    if (recommendations.watering_plan && recommendations.watering_plan.next_watering_in_days !== undefined) {
      intervalDays = recommendations.watering_plan.next_watering_in_days;
      shouldWaterNow = recommendations.watering_plan.should_water_now === true;
      reasonShort = recommendations.watering_plan.reason_short || '';
      rawAmountMl = recommendations.watering_plan.amount_ml;
      if (rawAmountMl !== null && rawAmountMl !== undefined) {
        rawAmountMl = clampAmount(rawAmountMl);
      }
    } else {
      // PRIORITY 2: legacy scientific fields
      const hoursFromAI = recommendations.next_after_watering_in_hours || recommendations.next_check_in_hours;
      if (typeof hoursFromAI === 'number' && hoursFromAI > 0) {
        intervalDays = Math.round(hoursFromAI / 24);
        shouldWaterNow = recommendations.mode !== 'recheck_only';
      }
    }

    // PRIORITY 3: species fallback
    if (intervalDays === null || !Number.isFinite(intervalDays) || intervalDays <= 0) {
      const plantName =
        recommendations.name ||
        recommendations.care_recommendations?.name ||
        recommendations.species?.ai_species_guess;
      const plantProfile = recommendations.watering_calculation?.plant_profile || recommendations.plant_profile;
      intervalDays = getSpeciesBasedFallbackDays(plantName, plantProfile);
      shouldWaterNow = false;
    }

    intervalDays = Math.max(1, Math.min(60, intervalDays));

    const species = recommendations.species || {
      user_species_name: reqBody.userSpeciesName || null,
      ai_species_guess: recommendations.name || recommendations.care_recommendations?.name || null,
      species_confidence: recommendations.species?.species_confidence || 0.8,
    };

    if (rawAmountMl === null || rawAmountMl === undefined) {
      if (recommendations.amount_ml !== null && recommendations.amount_ml !== undefined) {
        rawAmountMl = recommendations.amount_ml;
      }
    }
    const safeAmountMl = rawAmountMl === null || rawAmountMl === undefined ? null : clampAmount(rawAmountMl);

    recommendations.species = species;
    recommendations.watering_plan = {
      should_water_now: shouldWaterNow,
      next_watering_in_days: intervalDays,
      amount_ml: safeAmountMl,
      reason_short:
        reasonShort ||
        recommendations.watering_plan?.reason_short ||
        recommendations.reason ||
        recommendations.care_recommendations?.water ||
        'AI-based watering schedule derived from image and historical context.',
    };

    recommendations = enforceWateringConsistencyGuard(recommendations);
  } catch (e) {
    console.error('❌ Error normalizing recommendations:', e);
  }
  return recommendations;
}

function buildHealthCheckAgentPrompt(context, plantNameHint) {
  const plantSummary = context.plant || {};
  const checksSummary = (context.recentHealthChecks || []).map((c, idx) => ({
    idx: idx + 1,
    timestamp: c.timestamp,
    status: c.status,
    recommendedAmountMl: c.metadata?.recommendedAmountMl ?? null,
    wateringAmountText: c.metadata?.watering_amount ?? null,
  }));
  const waterSummary = (context.recentWateringEvents || []).map((w, idx) => ({
    idx: idx + 1,
    timestamp: w.timestamp,
    amountMl: w.amountMl,
  }));

  return `You are Plant Care Health Check Agent.
Analyze the CURRENT image first. Then use historical context and previous images as secondary signals.
Plant name hint: ${plantNameHint || plantSummary.name || 'unknown'}.

Historical context (JSON):
${JSON.stringify({
    plant: plantSummary,
    recentHealthChecks: checksSummary,
    recentWateringEvents: waterSummary,
  }, null, 2)}

Return ONLY valid JSON (no markdown) using this schema:
{
  "species": { "user_species_name": "string|null", "ai_species_guess": "string", "species_confidence": 0.0 },
  "soil": { "visual_state": "very_dry|dry|slightly_dry|moist|wet|not_visible", "moisture_current_pct": 0 },
  "watering_plan": { "should_water_now": true, "next_watering_in_days": 7, "amount_ml": 250, "reason_short": "string" },
  "care_recommendations": {
    "name": "exact plant name from image", "general_description": "detailed description", "moisture": "40-60%",
    "water": "specific water recommendations", "light": "4-6 hours", "temperature": "range", "fertilizer": "schedule",
    "soil": "soil type", "growth_rate": "growth info", "toxicity": "safety", "placement": "placement", "personality": "traits"
  },
  "other_care": { "growth_stage": "Seedling/Young/Mature/Established" },
  "interesting_facts": ["fact 1", "fact 2", "fact 3", "fact 4"],
  "specific_issues": ["risk 1", "risk 2", "risk 3 max"],
  "health_assessment": "current health assessment text",
  "plant_assistant": {
    "status": "healthy or issue_detected", "praise_phrase": "string", "health_summary": "string",
    "maintenance_footer": "string", "problem_name": "string", "problem_description": "string",
    "severity": "mild or moderate or serious", "action_steps": ["step"], "follow_up_days": 5, "reassurance": "string"
  }
}

Rules:
- Keep watering_plan in whole days (1-60).
- amount_ml must be integer and clamped to 50..2500.
- In care_recommendations.name, return botanical/cultivar identification from analysis (e.g., "Fittonia albivenis"), not the user nickname/plant label from app.
- For watering calculations, explicitly account for POT SIZE (if visible): small pots usually need less amount and shorter intervals; larger pots usually need more amount and longer intervals.
- For watering calculations, explicitly account for SOIL STATE from the current image (soil.visual_state + moisture_current_pct): very_dry/dry can justify earlier watering, moist/wet should delay watering.
- If pot size or soil state is not clearly visible, do not hallucinate; mark uncertainty in reason_short and use conservative safe recommendations.
- Use history to adapt advice (avoid contradicting recent watering events unless visible condition strongly requires it).
- If previous images are provided, mention trend in health_assessment (improving/stable/worsening) when possible.
- Also consider these stabilizing factors when available: days since last watering, recent recommendedAmountMl vs actual amountMl from watering_events, and whether the plant was recently marked healthy/issue_detected.
`;
}

function buildPlantChatSystemPrompt(context, options = {}) {
  const locale = (options.locale || 'en').toLowerCase();
  const plantSummary = context.plant || {};
  const checksSummary = (context.recentHealthChecks || []).slice(0, 6).map((c, idx) => ({
    idx: idx + 1,
    timestamp: c.timestamp,
    status: c.status,
    message: c.message || null,
    recommendedAmountMl: c.metadata?.recommendedAmountMl ?? null,
  }));
  const waterSummary = (context.recentWateringEvents || []).slice(0, 8).map((w, idx) => ({
    idx: idx + 1,
    timestamp: w.timestamp,
    amountMl: w.amountMl,
  }));

  return `You are Plant Care chat assistant for one specific plant.
Respond in language locale="${locale}" unless user asks for another language.

Plant identity:
- Name hint: ${options.plantNameHint || plantSummary.name || 'unknown'}
- Species hint: ${options.speciesHint || plantSummary.species || 'unknown'}

Authoritative context (JSON):
${JSON.stringify({
    plant: plantSummary,
    recentHealthChecks: checksSummary,
    recentWateringEvents: waterSummary,
  }, null, 2)}

Rules:
- Keep answer practical and concise (4-8 short bullet points or 1-3 short paragraphs).
- Use this plant context first. If uncertain, say uncertainty clearly.
- Never suggest "water now" when signs indicate overwatering risk or wet soil.
- Prefer safe, conservative actions if data conflicts.
- If user asks for next action, include a short step list.
- Do not fabricate measurements or events that are not in context.
- Return plain text only.
- Do not use markdown syntax (no **bold**, no headings, no bullet markers, no numbered list formatting).
- If multiple tips are needed, write short sentences separated by new lines.
- Keep response concise (max 6-8 short lines).
`;
}

exports.analyzePlantPhoto = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      // Initialize OpenAI with API key from secrets
      const openaiClient = await initializeOpenAI();
      
      // Check if API key is configured
      if (!openaiClient.apiKey) {
        throw new Error('OPENAI_API_KEY is not configured');
      }

      const { base64Image } = req.body;

      if (!base64Image) {
        return res.status(400).json({ error: 'Base64 image is required' });
      }

      console.log('🔍 Starting image analysis');
      console.log('🔍 Image length:', base64Image.length);
      console.log('🔍 Image preview (first 50 chars):', base64Image.substring(0, 50));
      console.log('🔍 Image preview (last 50 chars):', base64Image.substring(base64Image.length - 50));

      // New species-specific watering calculation prompt
      const promptText = `Your goal is to determine, for this specific plant, based only on:

the species you identify from the photo,
the visible soil condition,
the pot size and pot material (if visible),
the plant's size and leaf type,
the surrounding environment (indoor/outdoor, visible light),
how many whole days remain until the next watering.

You must return only a JSON object following the schema below.

General Rules
1. Base the calculation on the actual species, not on generic categories

Use your internal botanical knowledge:
- how often THIS species is usually watered indoors in a pot
- how drought-tolerant it is
- how fast it typically dries
- what watering interval is normal for its physiology

Do NOT use or output any categories like "succulent", "tropical", etc.
You may think in those terms internally, but do not return them.

2. Adjust the interval using the photo

Use factors only if visible; if not visible, safely skip them:
- soil dryness state (very_dry / dry / slightly_dry / moist / wet / not_visible)
- pot diameter + height (approximate)
- pot material (plastic / terracotta / fabric / ceramic)
- size and type of plant (leaf thickness, growth form)
- whether plant appears indoors or outdoors
- light intensity in the photo (bright / medium / dim)

Never require a rephoto if something is missing.

3. Watering Logic

You must determine:
- should_water_now (boolean)
- next_watering_in_days (integer 1–60)

Interpretation:
- If the plant should be watered now, next_watering_in_days means how many days until the watering after this one.
- If the plant should not be watered now, next_watering_in_days means the number of days from today.

4. Output Constraints

Always return whole days only (no hours, no decimals).
The interval must be species-specific — different plants should get different values.
Minimum allowed: 1 day
Maximum allowed: 60 days
Never output hours, minutes, timestamps or dates. Only days.

Output Schema (strict)

Return ONLY a JSON object:

{
  "species": {
    "user_species_name": "string|null",
    "ai_species_guess": "string",
    "species_confidence": 0.0
  },
  "soil": {
    "visual_state": "very_dry|dry|slightly_dry|moist|wet|not_visible",
    "moisture_current_pct": 0
  },
  "watering_plan": {
    "should_water_now": true,
    "next_watering_in_days": 0,
    "amount_ml": 250,
    "reason_short": "string"
  },
  "care_recommendations": {
    "name": "exact plant name from image",
    "general_description": "detailed description of what you see",
    "moisture": "40-60%",
    "water": "specific water recommendations",
    "light": "4-6 hours",
    "temperature": "optimal temperature range",
    "fertilizer": "fertilizer schedule and type",
    "soil": "soil type recommendations",
    "growth_rate": "expected growth rate and mature size",
    "toxicity": "toxicity level for humans and pets",
    "placement": "ideal placement in home or garden",
    "personality": "plant personality traits"
  },
  "other_care": {
    "growth_stage": "Seedling/Young/Mature/Established"
  },
  "interesting_facts": ["fact 1", "fact 2", "fact 3", "fact 4"],
  "specific_issues": ["risk 1", "risk 2", "max 3 items"],
  "health_assessment": "describe plant health condition",
  "plant_assistant": {
    "status": "healthy or issue_detected",
    "praise_phrase": "Short positive phrase for user, e.g. Great job! (when healthy)",
    "health_summary": "2-3 sentences: current state, leaves, soil, tone, no disease signs (when healthy)",
    "maintenance_footer": "Calm reminder: keep caring per recommendations, log watering (when healthy)",
    "problem_name": "Problem title (when issue_detected)",
    "problem_description": "Brief description of what is wrong (when issue_detected)",
    "severity": "mild or moderate or serious (when issue_detected)",
    "action_steps": ["Step 1", "Step 2", "max 3-5 concrete actions (when issue_detected)"],
    "follow_up_days": 5,
    "reassurance": "Short supportive line, e.g. plant can recover (when issue_detected)"
  }
}

Plant assistant rules: Set status to "healthy" if plant looks fine, else "issue_detected". For healthy: fill praise_phrase, health_summary, maintenance_footer; leave problem_* empty or minimal. For issue_detected: fill problem_name, problem_description, severity (mild=5-7 days, moderate=3-5, serious=2-3), action_steps (3-5 concrete steps), follow_up_days (5-7 mild, 3-5 moderate, 2-3 serious), reassurance. Use same language as health_assessment.

specific_issues rules: Array of 2–3 short strings. These are SPECIES-SPECIFIC CARE RISKS (potential issues), NOT current health problems. Examples: "Sensitive to overwatering", "Avoid direct midday sun", "Sensitive to drafts", "Does not tolerate dry air". Short, concrete, no extra text. What the user should watch to avoid harming this species.

Additional Rules:
- species_confidence = a value 0.0–1.0
- moisture_current_pct = approximate surface moisture (0–100)
- reason_short = one sentence explaining the logic (for debugging)

Water amount rules:
- You must output "amount_ml" as a single integer representing how much water to give in ONE watering event.
- Think in terms of pot volume. Typical safe watering amount for potted plants is about 10–20% of the soil volume.
- Very small pots (under 0.5 L) → 50–150 ml.
- Medium pots (0.5–3 L) → 100–500 ml.
- Large pots (3–15 L) → 300–1500 ml.
- Very large containers (clearly huge outdoor tubs) → up to 2500 ml.
- Hard limits:
  - amount_ml MUST be between 50 and 1500 ml for normal potted plants.
  - ONLY if the plant is in a visibly very large container, you MAY go up to 2500 ml.
  - NEVER return more than 2500 ml.
  - If your internal estimate is higher, still cap the value and mention this in reason_short.
- Always prefer a conservative, safe amount that avoids overwatering.

Reasoning Guidance (internal-only):
Consider:
- Typical watering interval for the species (5–10 days, 10–20 days, etc.)
- Smaller pot → dries faster → fewer days
- Fabric/terracotta pot → dries faster
- Bright light → dries faster
- Thick/succulent-like leaves → longer intervals
- Large plant in small pot → dries very fast
- Soil very dry → shorter interval
- Soil moist/wet → longer interval

But output only the required JSON.

Return Format: Return ONLY JSON. No text. No markdown. No explanations outside the JSON block.`;

      console.log('🔍 Sending to OpenAI with image_url format');
      const imageUrl = `data:image/jpeg;base64,${base64Image}`;
      console.log('🔍 Image URL preview:', imageUrl.substring(0, 100) + '...');

      // Retry mechanism for JSON parsing
      let content;
      let recommendations;
      let attempts = 0;
      const maxAttempts = 2;
      
      while (attempts <= maxAttempts) {
        attempts++;
        console.log(`🔄 Attempt ${attempts} of ${maxAttempts + 1}`);
        
        // Use more strict prompt on retry
        let currentPrompt = promptText;
        if (attempts > 1) {
          currentPrompt = `CRITICAL: You MUST respond with ONLY valid JSON, no markdown, no explanations. Return species-specific watering interval in whole days (1-60).

{
  "species": {
    "user_species_name": null,
    "ai_species_guess": "exact plant species name",
    "species_confidence": 0.9
  },
  "soil": {
    "visual_state": "very_dry|dry|slightly_dry|moist|wet|not_visible",
    "moisture_current_pct": 50
  },
  "watering_plan": {
    "should_water_now": false,
    "next_watering_in_days": 7,
    "amount_ml": 250,
    "reason_short": "Species-specific interval based on visible conditions"
  },
  "care_recommendations": {
    "name": "actual plant name",
    "general_description": "what you see",
    "moisture": "40-60%",
    "water": "specific watering guidance",
    "light": "4-6 hours",
    "temperature": "temperature range",
    "fertilizer": "fertilizer schedule",
    "soil": "soil type",
    "growth_rate": "growth info",
    "toxicity": "safety info",
    "placement": "placement advice",
    "personality": "plant traits"
  },
  "other_care": {
    "growth_stage": "Seedling/Young/Mature/Established"
  },
  "interesting_facts": ["fact 1", "fact 2", "fact 3", "fact 4"],
  "specific_issues": ["risk 1", "risk 2"],
  "health_assessment": "health status",
  "plant_assistant": {
    "status": "healthy or issue_detected",
    "praise_phrase": "string",
    "health_summary": "string",
    "maintenance_footer": "string",
    "problem_name": "string",
    "problem_description": "string",
    "severity": "mild or moderate or serious",
    "action_steps": ["string"],
    "follow_up_days": 5,
    "reassurance": "string"
  }
}`;
        }
        
        const response = await openaiClient.chat.completions.create({
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'text',
                  text: currentPrompt
                },
                {
                  type: 'image_url',
                  image_url: {
                    url: imageUrl,
                  },
                },
              ],
            },
          ],
          max_tokens: 3000,
          temperature: attempts > 1 ? 0.3 : 1.0,
        });

        content = response.choices[0].message.content;
        console.log(`✅ Plant analysis successful (attempt ${attempts})`);
        console.log('🔍 AI Response preview:', content.substring(0, 500) + '...');
        console.log('🔍 Full AI Response:', content);

        // Parse the AI response to extract structured information
        recommendations = parseAIResponse(content);
        
        // Check if we got valid watering plan data (new schema) or scientific watering data (old schema)
        const hasNewWateringPlan = recommendations && recommendations.watering_plan && recommendations.watering_plan.next_watering_in_days !== undefined;
        const hasOldWateringData = recommendations && recommendations.amount_ml !== undefined;
        
        if (hasNewWateringPlan || hasOldWateringData) {
          console.log('✅ Valid JSON with watering data parsed successfully');
          if (hasNewWateringPlan) {
            console.log('✅ Using new species-specific watering plan');
          } else {
            console.log('✅ Using legacy scientific watering calculation');
          }
          break;
        } else if (attempts <= maxAttempts) {
          console.log('⚠️ Missing watering data, retrying...');
        } else {
          console.log('❌ Failed to get valid watering data after all retries');
        }
      }

      // Normalize AI recommendations into days-based watering plan per plant.
      recommendations = normalizeRecommendations(recommendations, req.body || {});

      res.json({
        success: true,
        recommendations,
        rawResponse: content
      });

    } catch (error) {
      console.error('❌ Plant Photo Analysis Error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });
});

exports.analyzeHealthCheckAgent = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const openaiClient = await initializeOpenAI();
      if (!openaiClient.apiKey) {
        throw new Error('OPENAI_API_KEY is not configured');
      }

      const { base64Image, plantId, userId, plantName } = req.body || {};
      if (!base64Image) {
        return res.status(400).json({ success: false, error: 'Base64 image is required' });
      }

      const context = await loadHealthCheckAgentContext(plantId, userId);
      const promptText = buildHealthCheckAgentPrompt(context, plantName);
      const currentImageUrl = `data:image/jpeg;base64,${base64Image}`;

      let content = '';
      let recommendations = null;
      let attempts = 0;
      let tierUsed = HEALTH_CHECK_IMAGE_TIERS[0];
      let escalationReason = null;
      const attemptTrace = [];
      let accepted = false;

      for (let tierIndex = 0; tierIndex < HEALTH_CHECK_IMAGE_TIERS.length; tierIndex++) {
        attempts++;
        const tierSize = HEALTH_CHECK_IMAGE_TIERS[tierIndex];
        const previousImageUrls = getPreviousImagesForTier(context, tierSize);
        tierUsed = tierSize;
        const isRetry = tierIndex > 0;
        const contentBlocks = buildHealthCheckContentBlocks(
          promptText,
          currentImageUrl,
          previousImageUrls,
          isRetry
        );

        const response = await openaiClient.chat.completions.create({
          model: 'gpt-4o-mini',
          messages: [{ role: 'user', content: contentBlocks }],
          max_tokens: 3000,
          temperature: isRetry ? 0.3 : 0.8,
        });

        content = response.choices?.[0]?.message?.content || '';
        recommendations = parseAIResponse(content);
        recommendations = normalizeRecommendations(recommendations, req.body || {});
        const quality = evaluateHealthCheckAgentResult(recommendations, context);
        attemptTrace.push({
          attempt: attempts,
          tierSize,
          previousImagesUsed: previousImageUrls.length,
          accepted: quality.ok,
          reason: quality.reason,
        });

        if (quality.ok) {
          accepted = true;
          escalationReason = null;
          break;
        }

        escalationReason = quality.reason;
      }

      // If all tiers failed quality checks, keep the latest normalized output as fallback.
      if (!accepted && !recommendations) {
        recommendations = {
          watering_plan: {
            should_water_now: false,
            next_watering_in_days: 7,
            amount_ml: 200,
            reason_short: 'Fallback after agent retries',
          },
          plant_assistant: {
            status: 'issue_detected',
            problem_name: 'Analysis uncertainty',
            problem_description: 'Could not confidently validate all required fields.',
            severity: 'mild',
            action_steps: ['Re-take a clearer photo in good light', 'Check soil moisture manually'],
            follow_up_days: 3,
            reassurance: 'Plant can recover with consistent monitoring.',
          },
        };
        recommendations = normalizeRecommendations(recommendations, req.body || {});
      }

      return res.json({
        success: true,
        recommendations,
        rawResponse: content,
        agent: {
          attemptsUsed: attempts,
          tierUsed,
          imagesUsed: 1 + getPreviousImagesForTier(context, tierUsed).length,
          escalationReason,
          accepted,
          attemptTrace,
          decisionTraceV2: buildHealthCheckDecisionTraceV2({
            attemptTrace,
            accepted,
            tierUsed,
            escalationReason,
            context,
          }),
          context: {
            healthChecksLoaded: context.recentHealthChecks.length,
            wateringEventsLoaded: context.recentWateringEvents.length,
            previousImagesAvailable: context.recentImageUrls.length,
          },
        },
      });
    } catch (error) {
      console.error('❌ Health Check Agent Error:', error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  });
});

exports.chatPlantAssistant = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const openaiClient = await initializeOpenAI();
      if (!openaiClient.apiKey) {
        throw new Error('OPENAI_API_KEY is not configured');
      }

      const {
        plantId,
        userId,
        message,
        locale,
        plantName,
        species,
        conversation,
      } = req.body || {};

      if (!plantId || !userId || !message) {
        return res.status(400).json({
          success: false,
          error: 'plantId, userId and message are required',
        });
      }

      const context = await loadHealthCheckAgentContext(plantId, userId);
      if (!context.plant) {
        return res.status(403).json({
          success: false,
          error: 'Plant not found or access denied',
        });
      }

      const hasContextSignals =
        (context.recentHealthChecks || []).length > 0 ||
        (context.recentWateringEvents || []).length > 0 ||
        (context.recentImageUrls || []).length > 0;
      // Placeholder for future RAG integration.
      const hasKnowledgeBaseEvidence = false;
      const responseSource = hasKnowledgeBaseEvidence
        ? 'knowledge_base'
        : hasContextSignals
          ? 'context'
          : 'agent';

      const systemPrompt = buildPlantChatSystemPrompt(context, {
        locale,
        plantNameHint: plantName,
        speciesHint: species,
      });

      const history = Array.isArray(conversation)
        ? conversation
            .slice(-12)
            .map((m) => ({
              role: m?.role === 'assistant' ? 'assistant' : 'user',
              content: String(m?.text || '').slice(0, 1200),
            }))
            .filter((m) => m.content.length > 0)
        : [];

      const messages = [
        { role: 'system', content: systemPrompt },
        ...history,
        { role: 'user', content: String(message).slice(0, 1200) },
      ];

      const response = await openaiClient.chat.completions.create({
        model: 'gpt-4o-mini',
        messages,
        max_tokens: 900,
        temperature: 0.4,
      });

      const answer = response.choices?.[0]?.message?.content?.trim() ||
        'I could not generate a response right now. Please try again.';

      return res.json({
        success: true,
        answer,
        source: responseSource,
        sourceDebug: {
          hasContextSignals,
          hasKnowledgeBaseEvidence,
          healthChecksLoaded: (context.recentHealthChecks || []).length,
          wateringEventsLoaded: (context.recentWateringEvents || []).length,
          previousImagesLoaded: (context.recentImageUrls || []).length,
        },
        context: {
          plantId,
          plantName: context.plant?.name || plantName || null,
          species: context.plant?.species || species || null,
        },
      });
    } catch (error) {
      console.error('❌ Plant chat assistant error:', error);
      return res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  });
});

/**
 * Cron job to send watering reminder notifications
 * Runs every 5 minutes to check for plants that need watering reminders
 */
exports.sendWateringReminders = functions.pubsub
  .schedule('every 5 minutes')
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      console.log('🔔 Starting watering reminder check...');
      
      const now = admin.firestore.Timestamp.now();
      const nowDate = now.toDate();
      const db = admin.firestore();
      
      // Query plants that need notifications
      // - nextNotificationAt <= now
      // - not muted
      // - snoozedUntil is null or in the past
      const plantsSnapshot = await db.collection('plants')
        .where('nextNotificationAt', '<=', nowDate.toISOString())
        .where('muted', '==', false)
        .get();
      
      if (plantsSnapshot.empty) {
        console.log('✅ No plants need watering reminders at this time');
        return null;
      }
      
      console.log(`🌱 Found ${plantsSnapshot.docs.length} potential plants for reminders`);
      
      // Group plants by user
      const userPlants = {};
      
      for (const plantDoc of plantsSnapshot.docs) {
        const plant = plantDoc.data();
        const plantId = plantDoc.id;
        
        // Check if snoozed
        if (plant.snoozedUntil) {
          const snoozedUntil = new Date(plant.snoozedUntil);
          if (snoozedUntil > nowDate) {
            console.log(`⏰ Plant ${plant.name} is snoozed until ${snoozedUntil}`);
            continue;
          }
        }
        
        const userId = plant.userId;
        if (!userId) continue;
        
        if (!userPlants[userId]) {
          userPlants[userId] = [];
        }
        
        userPlants[userId].push({
          id: plantId,
          ...plant,
        });
      }
      
      console.log(`👥 Processing reminders for ${Object.keys(userPlants).length} users`);
      
      // Process each user's plants
      const promises = Object.entries(userPlants).map(([userId, plants]) =>
        sendUserReminders(db, userId, plants, nowDate)
      );
      
      await Promise.all(promises);
      
      console.log('✅ Watering reminders sent successfully');
      return null;
    } catch (error) {
      console.error('❌ Error sending watering reminders:', error);
      return null;
    }
  });

/**
 * Send reminders for a specific user's plants
 */
async function sendUserReminders(db, userId, plants, nowDate) {
  try {
    // Get user data
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log(`⚠️ User ${userId} not found`);
      return;
    }
    
    const userData = userDoc.data();
    const fcmTokens = userData.fcmTokens || [];
    
    if (fcmTokens.length === 0) {
      console.log(`⚠️ User ${userId} has no FCM tokens`);
      return;
    }
    
    // Check daily push limit
    const maxPushes = userData.maxPushesPerDay || 3;
    const pushCountToday = await getDailyPushCount(db, userId, nowDate);
    
    if (pushCountToday >= maxPushes) {
      console.log(`⚠️ User ${userId} has reached daily push limit (${maxPushes})`);
      // Roll notifications to next day
      await rollNotificationsToNextDay(db, plants, userData);
      return;
    }
    
    // Get user's timezone and quiet hours
    const timezone = userData.timezone || 'UTC';
    const quietHours = userData.quietHours || null;
    
    // Filter plants based on quiet hours
    const plantsToNotify = await filterByQuietHours(plants, nowDate, timezone, quietHours, db);
    
    if (plantsToNotify.length === 0) {
      console.log(`⚠️ All plants for user ${userId} are in quiet hours`);
      return;
    }
    
    // Batch notifications if multiple plants trigger within 1 hour
    const shouldBatch = plantsToNotify.length > 1;
    
    if (shouldBatch) {
      await sendBatchedNotification(fcmTokens, plantsToNotify, userId, db);
    } else {
      await sendSingleNotification(fcmTokens, plantsToNotify[0], userId, db);
    }
    
    // Increment daily push count
    await incrementDailyPushCount(db, userId, nowDate);
    
    // Update plant schedules
    await updatePlantSchedules(db, plantsToNotify, nowDate);
    
  } catch (error) {
    console.error(`❌ Error sending reminders for user ${userId}:`, error);
  }
}

/**
 * Get the number of pushes sent to a user today
 */
async function getDailyPushCount(db, userId, nowDate) {
  const startOfDay = new Date(nowDate);
  startOfDay.setHours(0, 0, 0, 0);
  
  const countDoc = await db.collection('notification_counts')
    .doc(`${userId}_${startOfDay.toISOString().split('T')[0]}`)
    .get();
  
  return countDoc.exists ? (countDoc.data().count || 0) : 0;
}

/**
 * Increment daily push count for a user
 */
async function incrementDailyPushCount(db, userId, nowDate) {
  const startOfDay = new Date(nowDate);
  startOfDay.setHours(0, 0, 0, 0);
  const docId = `${userId}_${startOfDay.toISOString().split('T')[0]}`;
  
  await db.collection('notification_counts').doc(docId).set({
    userId,
    date: startOfDay.toISOString(),
    count: admin.firestore.FieldValue.increment(1),
  }, { merge: true });
}

/**
 * Filter plants based on quiet hours
 */
async function filterByQuietHours(plants, nowDate, timezone, quietHours, db) {
  if (!quietHours || !quietHours.start || !quietHours.end) {
    return plants; // No quiet hours configured
  }
  
  // Convert current time to user's timezone
  const nowHour = nowDate.getUTCHours(); // Simplified - in production, use proper timezone conversion
  const nowMinute = nowDate.getUTCMinutes();
  const nowTime = `${String(nowHour).padStart(2, '0')}:${String(nowMinute).padStart(2, '0')}`;
  
  const { start, end } = quietHours;
  
  // Check if current time is in quiet hours
  const isQuietTime = isTimeInRange(nowTime, start, end);
  
  if (isQuietTime) {
    console.log(`🔇 Current time ${nowTime} is in quiet hours (${start} - ${end})`);
    
    // Shift notifications to end of quiet hours
    for (const plant of plants) {
      const endOfQuietHours = parseTimeToDate(nowDate, end);
      await db.collection('plants').doc(plant.id).update({
        nextNotificationAt: endOfQuietHours.toISOString(),
      });
    }
    
    return []; // Don't send notifications now
  }
  
  return plants;
}

/**
 * Check if a time is within a range
 */
function isTimeInRange(time, start, end) {
  // Simple comparison (doesn't handle overnight ranges perfectly)
  if (start <= end) {
    return time >= start && time < end;
  } else {
    // Overnight range (e.g., 22:00 - 08:00)
    return time >= start || time < end;
  }
}

/**
 * Parse time string to Date
 */
function parseTimeToDate(baseDate, timeStr) {
  const [hours, minutes] = timeStr.split(':').map(Number);
  const date = new Date(baseDate);
  date.setHours(hours, minutes, 0, 0);
  return date;
}

/**
 * Roll notifications to next day at preferred time
 */
async function rollNotificationsToNextDay(db, plants, userData) {
  const batch = db.batch();
  
  for (const plant of plants) {
    const preferredTime = plant.preferredTime || '18:00';
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    const [hours, minutes] = preferredTime.split(':').map(Number);
    tomorrow.setHours(hours, minutes, 0, 0);
    
    const plantRef = db.collection('plants').doc(plant.id);
    batch.update(plantRef, {
      nextNotificationAt: tomorrow.toISOString(),
    });
  }
  
  await batch.commit();
  console.log(`📅 Rolled ${plants.length} notifications to next day`);
}

/**
 * Send a batched notification for multiple plants
 */
async function sendBatchedNotification(fcmTokens, plants, userId, db) {
  const plantCount = plants.length;
  const firstPlant = plants[0];
  const secondPlant = plants.length > 1 ? plants[1] : null;
  
  let body = '';
  if (plantCount === 2) {
    body = `${firstPlant.name} and ${secondPlant.name} need water`;
  } else {
    body = `${firstPlant.name}, ${secondPlant.name} and ${plantCount - 2} more need water`;
  }
  
  const message = {
    notification: {
      title: `${plantCount} plants need water`,
      body: body,
    },
    data: {
      type: 'batched_reminder',
      plantCount: String(plantCount),
      userId: userId,
    },
    tokens: fcmTokens,
  };
  
  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log(`✅ Batched notification sent to user ${userId}: ${response.successCount} successful, ${response.failureCount} failed`);
    
    // Remove invalid tokens
    await removeInvalidTokens(db, userId, fcmTokens, response);
  } catch (error) {
    console.error(`❌ Error sending batched notification:`, error);
  }
}

/**
 * Send a single plant notification
 */
async function sendSingleNotification(fcmTokens, plant, userId, db) {
  const state = plant.notificationState || 'ok';
  
  let title = '';
  let body = '';
  
  if (state === 'overdue') {
    const streak = plant.overdueStreak || 0;
    if (streak === 0) {
      title = `${plant.name} is thirsty`;
      body = `It's been a while since watering. Please check on your plant.`;
    } else if (streak === 1) {
      title = `${plant.name} really needs water`;
      body = `Your plant hasn't been watered in a while. Time to give it some love!`;
    } else {
      title = `🆘 ${plant.name} is very thirsty!`;
      body = `Please water your plant soon to keep it healthy.`;
    }
  } else if (state === 'due') {
    title = `Time to water ${plant.name}`;
    body = `Your plant is ready for its scheduled watering.`;
  } else {
    // Pre-due reminder
    title = `Heads-up: ${plant.name} needs water soon`;
    body = `Your plant will need water in about 1 hour.`;
  }
  
  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: {
      type: 'single_reminder',
      plantId: plant.id,
      plantName: plant.name,
      state: state,
      action: 'open_plant',
    },
    tokens: fcmTokens,
  };
  
  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log(`✅ Notification sent for ${plant.name}: ${response.successCount} successful, ${response.failureCount} failed`);
    
    // Remove invalid tokens
    await removeInvalidTokens(db, userId, fcmTokens, response);
  } catch (error) {
    console.error(`❌ Error sending notification for ${plant.name}:`, error);
  }
}

/**
 * Remove invalid FCM tokens from user document
 */
async function removeInvalidTokens(db, userId, tokens, response) {
  const invalidTokens = [];
  
  response.responses.forEach((resp, idx) => {
    if (!resp.success) {
      const errorCode = resp.error?.code;
      if (errorCode === 'messaging/invalid-registration-token' ||
          errorCode === 'messaging/registration-token-not-registered') {
        invalidTokens.push(tokens[idx]);
      }
    }
  });
  
  if (invalidTokens.length > 0) {
    console.log(`🗑️ Removing ${invalidTokens.length} invalid tokens for user ${userId}`);
    
    const userRef = db.collection('users').doc(userId);
    await userRef.update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
    });
  }
}

/**
 * Update plant schedules after sending notifications
 */
async function updatePlantSchedules(db, plants, nowDate) {
  const batch = db.batch();
  
  for (const plant of plants) {
    const plantRef = db.collection('plants').doc(plant.id);
    const state = plant.notificationState || 'ok';
    const nextDueAt = plant.nextDueAt ? new Date(plant.nextDueAt) : null;
    
    let updates = {};
    
    if (state === 'ok') {
      // Pre-due reminder sent, schedule due reminder
      updates = {
        nextNotificationAt: nextDueAt?.toISOString() || nowDate.toISOString(),
        notificationState: 'due',
      };
    } else if (state === 'due') {
      // Due reminder sent, schedule first overdue reminder (D+1)
      const tomorrow = new Date(nextDueAt || nowDate);
      tomorrow.setDate(tomorrow.getDate() + 1);
      
      const preferredTime = plant.preferredTime || '18:00';
      const [hours, minutes] = preferredTime.split(':').map(Number);
      tomorrow.setHours(hours, minutes, 0, 0);
      
      updates = {
        nextNotificationAt: tomorrow.toISOString(),
        notificationState: 'overdue',
        overdueStreak: 1,
      };
    } else if (state === 'overdue') {
      // Schedule next overdue reminder
      const streak = plant.overdueStreak || 0;
      const nextStreakDay = getNextOverdueDay(streak + 1);
      
      if (nextStreakDay === null) {
        // Stop sending after D+7
        console.log(`🛑 Stopping overdue reminders for ${plant.name} (streak: ${streak + 1})`);
        updates = {
          overdueStreak: streak + 1,
        };
      } else {
        const nextReminder = new Date(nextDueAt || nowDate);
        nextReminder.setDate(nextReminder.getDate() + nextStreakDay);
        
        const preferredTime = plant.preferredTime || '18:00';
        const [hours, minutes] = preferredTime.split(':').map(Number);
        nextReminder.setHours(hours, minutes, 0, 0);
        
        updates = {
          nextNotificationAt: nextReminder.toISOString(),
          overdueStreak: streak + 1,
        };
      }
    }
    
    batch.update(plantRef, updates);
  }
  
  await batch.commit();
  console.log(`📅 Updated schedules for ${plants.length} plants`);
}

/**
 * Get next overdue reminder day based on streak
 * Returns null if we should stop sending reminders
 */
function getNextOverdueDay(streak) {
  // D+1, D+2, D+3, D+7, then stop
  const schedule = [1, 2, 3, 7];
  
  if (streak >= schedule.length) {
    return null; // Stop sending
  }
  
  return schedule[streak];
}

/**
 * Calculate scientific watering - simplified version without full implementation
 * Returns null if data is insufficient
 */
function calculateScientificWatering(waterCalc) {
  try {
    console.log('🔍 calculateScientificWatering input:', JSON.stringify(waterCalc, null, 2));
    
    // Extract measurements
    const potPresent = waterCalc.pot_present === true || 
                       waterCalc.pot_present === 'yes' || 
                       (typeof waterCalc.pot_present === 'string' && waterCalc.pot_present.toLowerCase() === 'yes');
    const potDiameter = parseDimension(waterCalc.pot_diameter);
    const potHeight = parseDimension(waterCalc.pot_height);
    const plantHeight = parseDimension(waterCalc.plant_height);
    const canopyDiameter = parseDimension(waterCalc.canopy_diameter);
    const soilState = waterCalc.visual_soil_state?.toLowerCase();
    const profile = waterCalc.plant_profile?.toLowerCase();
    
    console.log('🔍 Parsed measurements:', { potPresent, potDiameter, potHeight, plantHeight, canopyDiameter, soilState, profile });
    
    // Validate measurements
    if (potPresent && (!potDiameter || !potHeight)) {
      console.log('⚠️ Has pot but missing pot dimensions');
      return null;
    }
    if (!potPresent && (!plantHeight || !canopyDiameter)) {
      console.log('⚠️ No pot but missing plant dimensions');
      return null;
    }
    
    // Calculate volume
    let effectiveVolumeMl;
    if (potPresent && potDiameter && potHeight) {
      // Cylinder volume: π * r² * h * 0.8 (accounting for not full substrate)
      const radiusCm = potDiameter / 2;
      effectiveVolumeMl = Math.PI * Math.pow(radiusCm, 2) * potHeight * 0.8;
    } else if (plantHeight && canopyDiameter) {
      // Equivalent root volume
      const rootRadiusCm = Math.max(canopyDiameter / 2, plantHeight * 0.05);
      const rootDepthCm = Math.min(Math.max(plantHeight * 0.12, 10), 60);
      effectiveVolumeMl = Math.PI * Math.pow(rootRadiusCm, 2) * rootDepthCm * 0.6;
    } else {
      return null;
    }
    
    // Check soil state for wet/moist
    if (soilState === 'wet' || soilState === 'moist') {
      const nextCheckHours = [24, 48, 72][Math.floor(Math.random() * 3)];
      return {
        amount_ml: 0,
        range_ml: [0, 0],
        next_after_watering_in_hours: 0,
        next_check_in_hours: nextCheckHours,
        mode: 'recheck_only'
      };
    }
    
    // Base fractions by profile
    const profileFractions = {
      'succulent': { base: 0.0225, cap: 0.06 }, // 1.5-3% midpoint
      'succulent_large': { base: 0.03, cap: 0.06 }, // 2-4% midpoint
      'tropical_broadleaf': { base: 0.24, cap: 0.35 }, // 18-30% midpoint
      'herbaceous': { base: 0.20, cap: 0.35 }, // 15-25% midpoint
      'woody_potted': { base: 0.15, cap: 0.25 }, // 10-20% midpoint
      'large_palm_indoor': { base: 0.045, cap: 0.10 } // 3-6% midpoint
    };
    
    const fracs = profileFractions[profile] || { base: 0.15, cap: 0.35 };
    
    // Soil multiplier
    const soilMults = {
      'slightly_dry': 0.7,
      'dry': 1.0,
      'very_dry': 1.15,
      'not_visible': 1.0
    };
    const soilMult = soilMults[soilState] || 1.0;
    
    // Calculate amount
    const baseAmount = effectiveVolumeMl * fracs.base;
    const calculatedRawAmount = baseAmount * soilMult;
    const cappedAmount = Math.min(calculatedRawAmount, effectiveVolumeMl * fracs.cap);
    
    // Rounding
    let amountMl = cappedAmount < 1000 
      ? Math.round(cappedAmount / 10) * 10 
      : Math.round(cappedAmount / 100) * 100;
    
    // Clamp to safe range (50-2500 ml)
    const rawAmountBeforeClamp = amountMl;
    amountMl = clampAmount(amountMl);
    if (rawAmountBeforeClamp !== amountMl) {
      console.log(`[Scientific Amount Raw] ${rawAmountBeforeClamp} [Clamped] ${amountMl}`);
    }
    
    const rangeMl = [Math.round(amountMl * 0.8), Math.round(amountMl * 1.2)];
    
    // Calculate next watering
    const baselineHours = {
      'succulent': 240,
      'succulent_large': 336,
      'herbaceous': 96,
      'tropical_broadleaf': 120,
      'woody_potted': 168,
      'large_palm_indoor': 240
    };
    const baseHours = baselineHours[profile] || 168;
    console.log(`🌱 Scientific calc: profile="${profile}", baseHours=${baseHours}, volume=${effectiveVolumeMl.toFixed(0)}ml, soil="${soilState}"`);
    
    // Modifiers
    let mPot = 1.0;
    if (effectiveVolumeMl < 1000) mPot = 0.6;
    else if (effectiveVolumeMl < 3000) mPot = 0.8;
    else if (effectiveVolumeMl < 10000) mPot = 1.0;
    else if (effectiveVolumeMl < 30000) mPot = 1.2;
    else mPot = 1.4;
    
    const mSoilForInterval = {
      'slightly_dry': 0.9,
      'dry': 1.0,
      'very_dry': 1.1,
      'not_visible': 1.0
    };
    const mSoil = mSoilForInterval[soilState] || 1.0;
    const mAmount = Math.max(0.85, Math.min(1.20, 0.9 + 0.00005 * amountMl));
    const mPersonal = 1.0; // Default personalization
    
    const nextHours = Math.round(baseHours * mPot * mSoil * mAmount * mPersonal / 6) * 6;
    const nextDays = Math.round(nextHours / 24);
    console.log(`🌱 Scientific calc result: ${nextHours}h (${nextDays} days) = ${baseHours} * ${mPot} * ${mSoil} * ${mAmount.toFixed(2)}`);
    
    return {
      amount_ml: amountMl,
      range_ml: rangeMl,
      next_after_watering_in_hours: nextHours,
      next_check_in_hours: 0,
      mode: 'after_watering'
    };
  } catch (error) {
    console.log('❌ Scientific watering calculation error:', error);
    return null;
  }
}

/**
 * Clamp water amount to safe range (50-2500 ml)
 * @param {number} amount - Raw amount from AI
 * @returns {number} - Clamped amount within safe range
 */
function clampAmount(amount) {
  const MIN = 50;
  const MAX = 2500; // absolute safety ceiling
  if (typeof amount !== 'number' || !Number.isFinite(amount)) {
    console.warn(`⚠️ Invalid amount value: ${amount}, defaulting to ${MIN}`);
    return MIN;
  }
  return Math.min(Math.max(amount, MIN), MAX);
}

/**
 * Parse dimension string (e.g., "15 cm" or "6 in") to number in cm
 */
function parseDimension(dimStr) {
  if (dimStr === null || dimStr === undefined) return null;
  
  // If it's already a number, return it
  if (typeof dimStr === 'number') return dimStr;
  
  // Convert to string and try to match with units first
  const match = dimStr.toString().match(/(\d+(?:\.\d+)?)\s*(cm|in)/i);
  if (match) {
    let value = parseFloat(match[1]);
    const unit = match[2].toLowerCase();
    
    if (unit === 'in') {
      value *= 2.54; // Convert to cm
    }
    
    return value;
  }
  
  // Try to match just a number (assume cm if no unit)
  const numMatch = dimStr.toString().match(/(\d+(?:\.\d+)?)/);
  if (numMatch) {
    return parseFloat(numMatch[1]);
  }
  
  return null;
}

/**
 * Transform new JSON structure to legacy format
 */
function transformNewJsonToLegacy(jsonData) {
  const careRec = jsonData.care_recommendations || {};
  const waterCalc = jsonData.watering_calculation || {};
  const otherCare = jsonData.other_care || {};
  const wateringPlan = jsonData.watering_plan || {};
  const species = jsonData.species || {};
  const soil = jsonData.soil || {};
  
  // Build care tips string from care_recommendations
  const careTipsLines = [];
  if (careRec.name) careTipsLines.push(`Cultivar: ${careRec.name}`);
  if (careRec.general_description) careTipsLines.push(`General Description: ${careRec.general_description}`);
  if (careRec.moisture) careTipsLines.push(`Moisture: ${careRec.moisture}`);
  if (careRec.water) careTipsLines.push(`Water: ${careRec.water}`);
  if (careRec.light) careTipsLines.push(`Light: ${careRec.light}`);
  if (careRec.temperature) careTipsLines.push(`Temperature: ${careRec.temperature}`);
  if (careRec.fertilizer) careTipsLines.push(`Fertilizer: ${careRec.fertilizer}`);
  if (careRec.soil) careTipsLines.push(`Soil: ${careRec.soil}`);
  if (careRec.growth_rate) careTipsLines.push(`Growth Rate: ${careRec.growth_rate}`);
  if (careRec.toxicity) careTipsLines.push(`Toxicity: ${careRec.toxicity}`);
  if (careRec.placement) careTipsLines.push(`Placement: ${careRec.placement}`);
  if (careRec.personality) careTipsLines.push(`Personality: ${careRec.personality}`);
  
  // specific_issues = species care risks (2–3 items), not current health problems
  const rawRisks = jsonData.specific_issues;
  let specificIssues = 'No specific issues detected';
  if (Array.isArray(rawRisks) && rawRisks.length > 0) {
    const items = rawRisks
      .map((s) => (typeof s === 'string' ? s.trim() : String(s || '').trim()))
      .filter((s) => s.length > 0)
      .slice(0, 3);
    if (items.length > 0) {
      specificIssues = items.join('\n');
    }
  }

  // Calculate scientific watering (legacy support)
  const scientificWatering = calculateScientificWatering(waterCalc);
  const baseResult = {
    general_description: careRec.general_description || jsonData.health_assessment || '',
    name: species.ai_species_guess || careRec.name || 'Plant',
    species: species.ai_species_guess || careRec.name || '', // Legacy field
    plant_size: 'Medium', // Will be inferred if needed
    pot_size: 'Medium',
    growth_stage: otherCare.growth_stage || 'Mature',
    moisture_level: careRec.moisture || (soil.moisture_current_pct ? `${soil.moisture_current_pct}%` : '50%'),
    light: careRec.light || 'Bright indirect light',
    watering_frequency: 7,
    watering_amount: '200-400 ml',
    specific_issues: specificIssues,
    care_tips: careTipsLines.join('\n'),
    interesting_facts: jsonData.interesting_facts || [],
    // Preserve new structure for client-side processing
    watering_plan: wateringPlan,
    species_data: species,
    soil_data: soil,
    plant_assistant: jsonData.plant_assistant || null,
  };

  if (scientificWatering) {
    return {
      ...baseResult,
      ...scientificWatering
    };
  }

  return baseResult;
}

/**
 * Parse AI response to extract structured information
 */
function parseAIResponse(aiResponse) {
  try {
    // Try to parse as JSON first
    if (aiResponse.trim().startsWith('{')) {
      const jsonData = JSON.parse(aiResponse);
      console.log('✅ Parsed JSON response successfully');
      
      // Transform new JSON structure to legacy format
      if (jsonData.care_recommendations || jsonData.watering_calculation) {
        return transformNewJsonToLegacy(jsonData);
      }
      
      // Already in legacy format, return as-is
      return jsonData;
    }
    
    // Fallback: extract information from text
    const response = aiResponse.toLowerCase();
    
    // Extract name from Name or Plant field
    let plantName = 'Plant';
    const lines = aiResponse.split('\n');
    for (const line of lines) {
      const trimmedLine = line.trim();
      if (trimmedLine.toLowerCase().startsWith('name:') || trimmedLine.toLowerCase().startsWith('plant:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          plantName = parts[1].trim();
          break;
        }
      }
    }
    
    // Extract species
    let species = '';
    for (const line of lines) {
      const trimmedLine = line.trim();
      if (trimmedLine.toLowerCase().startsWith('species:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          species = parts[1].trim();
          break;
        }
      }
    }
    
    // Extract size assessment data
    let plantSize = 'Medium';
    let potSize = 'Medium';
    let growthStage = 'Mature';
    
    for (const line of lines) {
      const trimmedLine = line.trim();
      const lowerLine = trimmedLine.toLowerCase();
      
      if (lowerLine.startsWith('size:') || lowerLine.startsWith('plant size:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          const size = parts[1].trim().toLowerCase();
          if (size.includes('small')) plantSize = 'Small';
          else if (size.includes('large')) plantSize = 'Large';
          else plantSize = 'Medium';
        }
      } else if (lowerLine.startsWith('container size:') || lowerLine.startsWith('pot size:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          const size = parts[1].trim().toLowerCase();
          if (size.includes('small') || size.includes('mini') || size.includes('4')) potSize = 'Small';
          else if (size.includes('large') || size.includes('big') || size.includes('10') || size.includes('12')) potSize = 'Large';
          else potSize = 'Medium';
        }
      } else if (lowerLine.startsWith('growth stage:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          const stage = parts[1].trim().toLowerCase();
          if (stage.includes('seedling')) growthStage = 'Seedling';
          else if (stage.includes('young')) growthStage = 'Young';
          else if (stage.includes('mature')) growthStage = 'Mature';
          else if (stage.includes('established')) growthStage = 'Established';
        }
      }
    }
    
    // Extract moisture level - look for percentage values first
    let moistureLevel = 'Moderate';
    
    // Look for moisture field with percentage
    for (const line of lines) {
      const trimmedLine = line.trim();
      if (trimmedLine.toLowerCase().startsWith('moisture:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          const moistureText = parts[1].trim();
          // Extract percentage if present
          const percentageMatch = moistureText.match(/(\d+)/);
          if (percentageMatch) {
            const percentage = parseInt(percentageMatch[1]);
            if (percentage >= 0 && percentage <= 100) {
              moistureLevel = percentage.toString();
            }
          } else {
            // Fallback to text-based extraction
            if (moistureText.toLowerCase().includes('dry') || moistureText.toLowerCase().includes('underwatered')) {
              moistureLevel = '25';
            } else if (moistureText.toLowerCase().includes('wet') || moistureText.toLowerCase().includes('overwatered')) {
              moistureLevel = '75';
            } else if (moistureText.toLowerCase().includes('moderate') || moistureText.toLowerCase().includes('medium')) {
              moistureLevel = '50';
            }
          }
        }
        break;
      }
    }
    
    // Fallback to old text-based extraction if no moisture field found
    if (moistureLevel == 'Moderate') {
      if (response.includes('dry') || response.includes('underwatered')) {
        moistureLevel = '25';
      } else if (response.includes('wet') || response.includes('overwatered')) {
        moistureLevel = '75';
      }
    }
    
    // Extract light requirements
    let light = 'Bright indirect light';
    if (response.includes('low light') || response.includes('shade')) {
      light = 'Low light';
    } else if (response.includes('direct sun') || response.includes('full sun')) {
      light = 'Direct sunlight';
    }
    
    // Extract watering frequency - more comprehensive detection
    let wateringFrequency = 7;
    
    // Try to extract frequency pattern like "every X days" or "X days"
    const frequencyPattern = /every\s*(\d+)\s*days?|(\d+)\s*days?/gi;
    const frequencyMatch = frequencyPattern.exec(aiResponse);
    
    if (frequencyMatch) {
      const days = frequencyMatch[1] || frequencyMatch[2];
      if (days) {
        wateringFrequency = parseInt(days) || 7;
      }
    }
    
    // Also check for common patterns
    if (aiResponse.includes('daily') || aiResponse.includes('every day') || aiResponse.includes('1 day')) {
      wateringFrequency = 1;
    } else if (aiResponse.includes('every 2 days') || aiResponse.includes('2 days')) {
      wateringFrequency = 2;
    } else if (aiResponse.includes('every 3 days') || aiResponse.includes('3 days')) {
      wateringFrequency = 3;
    } else if (aiResponse.includes('every 4 days') || aiResponse.includes('4 days')) {
      wateringFrequency = 4;
    } else if (aiResponse.includes('every 5 days') || aiResponse.includes('5 days')) {
      wateringFrequency = 5;
    } else if (aiResponse.includes('every 6 days') || aiResponse.includes('6 days')) {
      wateringFrequency = 6;
    } else if (aiResponse.includes('every 7 days') || aiResponse.includes('7 days') || aiResponse.includes('weekly')) {
      wateringFrequency = 7;
    } else if (aiResponse.includes('every 10 days') || aiResponse.includes('10 days')) {
      wateringFrequency = 10;
    } else if (aiResponse.includes('every 14 days') || aiResponse.includes('14 days') || aiResponse.includes('biweekly')) {
      wateringFrequency = 14;
    } else if (aiResponse.includes('every 21 days') || aiResponse.includes('21 days') || aiResponse.includes('3 weeks')) {
      wateringFrequency = 21;
    } else if (aiResponse.includes('monthly') || aiResponse.includes('every month') || aiResponse.includes('30 days')) {
      wateringFrequency = 30;
    }
    
    console.log(`🌱 Extracted watering frequency: ${wateringFrequency} days`);
    
      // Extract watering amount in milliliters
    let wateringAmount = '200-400 ml'; // Default fallback
    const mlPattern = /amount:\s*(\d+\s*-\s*\d+\s*ml)/gi;
    const mlMatch = mlPattern.exec(aiResponse);
    if (mlMatch) {
      wateringAmount = mlMatch[1].trim();
      console.log(`🌱 Extracted watering amount: ${wateringAmount}`);
    } else {
      // Try alternative patterns
      const mlPattern2 = /(\d+)\s*-\s*(\d+)\s*ml/gi;
      const mlMatch2 = mlPattern2.exec(aiResponse);
      if (mlMatch2) {
        wateringAmount = `${mlMatch2[1]}-${mlMatch2[2]} ml`;
        console.log(`🌱 Extracted watering amount: ${wateringAmount}`);
      } else {
        // If no ml amount found, ensure we have a valid default
        console.log(`⚠️ No watering amount found in AI response, using default: ${wateringAmount}`);
      }
    }

    // Extract care recommendations - use a simpler extraction that avoids the template
    const careRecommendations = extractActualCareTips(aiResponse);

    return {
      general_description: aiResponse,
      name: plantName,
      species: species,
      plant_size: plantSize,
      pot_size: potSize,
      growth_stage: growthStage,
      moisture_level: moistureLevel,
      light: light,
      watering_frequency: wateringFrequency,
      watering_amount: wateringAmount,
      specific_issues: extractIssues(aiResponse),
      care_tips: careRecommendations,
      interesting_facts: extractInterestingFacts(aiResponse),
    };
  } catch (e) {
    console.error('❌ Failed to parse AI response:', e);
    return {
      general_description: aiResponse,
      name: 'Plant',
      species: '',
      plant_size: 'Medium',
      pot_size: 'Medium',
      growth_stage: 'Mature',
      moisture_level: 'Moderate',
      light: 'Bright indirect light',
      watering_frequency: 7,
      watering_amount: '200-400 ml',
      specific_issues: 'Please check plant care manually',
      care_tips: 'Monitor soil moisture and light conditions',
      interesting_facts: ['Every plant is unique and has its own special characteristics', 'Plants grow and change throughout their lifecycle', 'Proper care helps plants thrive and stay healthy'],
    };
  }
}

/**
 * Extract actual care tips from AI response, avoiding template instructions
 */
function extractActualCareTips(response) {
  const lines = response.split('\n');
  const careTips = [];
  
  // Look for "CARE RECOMMENDATIONS:" section which contains comprehensive care tips
  let inCareRecommendationsSection = false;
  let inOtherCareSection = false;
  
  for (const line of lines) {
    const trimmedLine = line.trim();
    if (trimmedLine.isEmpty) continue;
    
    const lowerLine = trimmedLine.toLowerCase();
    
    // Start collecting when we hit "CARE RECOMMENDATIONS:" section
    if (lowerLine.includes('care recommendations:')) {
      inCareRecommendationsSection = true;
      continue;
    }
    
    // Also check for "Other Care:" section as backup
    if (lowerLine.includes('other care:')) {
      inOtherCareSection = true;
      continue;
    }
    
    // Stop at these sections - they're not care tips
    if (lowerLine.includes('interesting facts') || 
        lowerLine.includes('fun facts') ||
        lowerLine.includes('health assessment') ||
        lowerLine.includes('watering calculation data') ||
        lowerLine.includes('measure the required data')) {
      if (inCareRecommendationsSection || inOtherCareSection) break;
      continue;
    }
    
    // Skip template/instruction lines
    if (lowerLine.startsWith('**') || 
        lowerLine.includes('fill out the template') ||
        lowerLine.includes('measure the') ||
        lowerLine.includes('assess if') ||
        lowerLine.includes('yes/no') ||
        lowerLine.includes('cm or inches')) {
      continue;
    }
    
    // Collect lines from "CARE RECOMMENDATIONS:" section
    if (inCareRecommendationsSection || inOtherCareSection) {
      // Look for actual care advice lines - more flexible matching
      if (trimmedLine.includes(':') && 
          (lowerLine.startsWith('name') ||
          lowerLine.startsWith('description') ||
          lowerLine.startsWith('general') ||
          lowerLine.startsWith('moisture') ||
          lowerLine.startsWith('water') ||
          lowerLine.startsWith('light') ||
          lowerLine.startsWith('temperature') ||
          lowerLine.startsWith('humidity') ||
          lowerLine.startsWith('soil') ||
          lowerLine.startsWith('fertilizer') ||
          lowerLine.startsWith('growth rate') ||
          lowerLine.startsWith('growth stage') ||
          lowerLine.startsWith('toxicity') ||
          lowerLine.startsWith('placement') ||
          lowerLine.startsWith('personality'))) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          const content = parts.slice(1).join(':').trim();
          if (content.length > 5 && 
              !content.includes('**') && 
              !content.toLowerCase().includes('measure') &&
              !content.toLowerCase().includes('assess') &&
              !content.toLowerCase().includes('estimate') &&
              !content.toLowerCase().includes('fill') &&
              !content.includes('[') &&
              !content.includes(']')) {
            careTips.push(trimmedLine);
          }
        }
      }
    }
  }
  
  // If we found care tips, return them; otherwise return a default message
  if (careTips.length > 0) {
    return careTips.join('\n');
  }
  
  return 'Follow general plant care guidelines based on the plant type and current conditions.';
}

/**
 * Extract structured care recommendations from AI response (DEPRECATED)
 */
function extractStructuredCareRecommendations(response) {
  const sections = [];
  
  // Split response into lines and look for structured sections
  const lines = response.split('\n');
  
  for (const line of lines) {
    const trimmedLine = line.trim();
    if (trimmedLine.isEmpty) continue;
    
    const lowerLine = trimmedLine.toLowerCase();
    
    // Check if we're entering the interesting facts section (end of care content)
    if (lowerLine.includes('interesting facts') || lowerLine.includes('fun facts')) {
      break;
    }
    
    // Extract any line with a colon (Name:, Description:, Watering:, etc.)
    if (trimmedLine.includes(':')) {
      const parts = trimmedLine.split(':');
      if (parts.length >= 2) {
        const title = parts[0].trim();
        const content = parts.slice(1).join(':').trim();
        
        if (title.length > 0 && content.length > 0) {
          // Clean up the title and content
          const cleanTitle = cleanSectionTitle(title);
          const cleanContent = cleanSectionContent(content);
          
          if (cleanTitle.length > 0 && cleanContent.length > 0) {
            sections.push(`${cleanTitle}: ${cleanContent}`);
          }
        }
      }
    }
  }
  
  // If no structured sections found, try to extract from the entire response
  if (sections.length === 0) {
    const careSections = extractCareSectionsFromText(response);
    sections.push(...careSections);
  }
  
  return sections.length === 0 ? 'Follow general plant care guidelines' : sections.join('\n');
}

/**
 * Extract specific issues from AI response
 */
function extractIssues(response) {
  const issues = [];
  
  if (response.toLowerCase().includes('yellow') || response.toLowerCase().includes('yellowing')) {
    issues.push('Yellowing leaves');
  }
  if (response.toLowerCase().includes('brown') || response.toLowerCase().includes('browning')) {
    issues.push('Brown spots or edges');
  }
  if (response.toLowerCase().includes('wilted') || response.toLowerCase().includes('wilting')) {
    issues.push('Wilting or drooping');
  }
  if (response.toLowerCase().includes('dry') || response.toLowerCase().includes('underwatered')) {
    issues.push('Underwatering');
  }
  if (response.includes('wet') || response.includes('overwatered')) {
    issues.push('Overwatering');
  }
  if (response.includes('root rot')) {
    issues.push('Root rot');
  }
  
  return issues.length === 0 ? 'No specific issues detected' : issues.join(', ');
}

/**
 * Extract care tips from AI response
 */
function extractCareTips(response) {
  const tips = [];
  
  if (response.toLowerCase().includes('water')) {
    tips.push('Monitor soil moisture regularly');
  }
  if (response.toLowerCase().includes('light')) {
    tips.push('Ensure proper light conditions');
  }
  if (response.toLowerCase().includes('temperature')) {
    tips.push('Maintain stable temperature');
  }
  if (response.toLowerCase().includes('humidity')) {
    tips.push('Consider humidity levels');
  }
  if (response.toLowerCase().includes('fertilizer')) {
    tips.push('Use appropriate fertilizer');
  }
  
  return tips.length === 0 ? 'Follow general plant care guidelines' : tips.join('. ') + '.';
}

/**
 * Extract interesting facts from AI response
 */
function extractInterestingFacts(response) {
  const facts = [];
  
  // Look for numbered facts (e.g., "1. Lemons are rich in vitamin C")
  const factPattern = /\d+\.\s*(.+)/g;
  let match;
  
  while ((match = factPattern.exec(response)) !== null) {
    const fact = match[1].trim();
    // Only accept meaningful facts (not just instructions or templates)
    if (fact.length > 20 && 
        !fact.toLowerCase().includes('measure') &&
        !fact.toLowerCase().includes('assess') &&
        !fact.toLowerCase().includes('look for') &&
        !fact.toLowerCase().includes('note down') &&
        !fact.toLowerCase().includes('fill') &&
        !fact.toLowerCase().includes('template')) {
      facts.push(fact);
      if (facts.length >= 4) break;
    }
  }
  
  // If no numbered facts found, try to extract from Interesting Facts section
  if (facts.length === 0) {
    const lines = response.split('\n');
    let inInterestingFacts = false;
    
    for (const line of lines) {
      const trimmedLine = line.trim();
      const lowerLine = trimmedLine.toLowerCase();
      
      if (lowerLine.includes('interesting facts')) {
        inInterestingFacts = true;
        continue;
      }
      
      if (inInterestingFacts) {
        // Stop at next major section
        if (lowerLine.includes('health assessment') || 
            lowerLine.includes('care recommendations') ||
            lowerLine.includes('water') ||
            lowerLine.includes('name:')) {
          break;
        }
        
        // Look for lines starting with bullet points or numbers
        if (trimmedLine.length > 20 && 
            (trimmedLine.startsWith('-') || trimmedLine.startsWith('•') || /^\d+\./.test(trimmedLine))) {
          // Extract content after bullet/number
          const content = trimmedLine.replace(/^[-•]\s*/, '').replace(/^\d+\.\s*/, '').trim();
          if (content.length > 20 && 
              !content.toLowerCase().includes('measure') &&
              !content.toLowerCase().includes('assess') &&
              !content.toLowerCase().includes('look for') &&
              !content.toLowerCase().includes('note down') &&
              !content.toLowerCase().includes('fill') &&
              !content.toLowerCase().includes('template') &&
              !content.includes('[') &&
              !content.includes(']')) {
            facts.push(content);
            if (facts.length >= 4) break;
          }
        }
      }
    }
  }
  
  // If still no facts, provide default ones
  if (facts.length === 0) {
    facts.push(
      'Every plant is unique and has its own special characteristics',
      'Plants grow and change throughout their lifecycle',
      'Proper care helps plants thrive and stay healthy',
      'Plants can communicate with each other through chemical signals'
    );
  }
  
  return facts;
}

/**
 * Clean section title for better formatting
 */
function cleanSectionTitle(title) {
  return title.trim().replace(/[^\w\s]/g, '');
}

/**
 * Clean section content for better formatting
 */
function cleanSectionContent(content) {
  return content.trim().replace(/\n+/g, ' ').replace(/\s+/g, ' ');
}

/**
 * Extract care sections from text when structured format fails
 */
function extractCareSectionsFromText(text) {
  const sections = [];
  
  // Look for common care-related keywords
  const careKeywords = ['watering', 'light', 'temperature', 'soil', 'fertilizing', 'humidity'];
  
  for (const keyword of careKeywords) {
    const regex = new RegExp(`${keyword}[^\\n]*`, 'gi');
    const matches = text.match(regex);
    
    if (matches && matches.length > 0) {
      sections.push(matches[0].trim());
    }
  }
  
  return sections;
}
