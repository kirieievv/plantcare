const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai');
const crypto = require('crypto');
const cors = require('cors')({ origin: true });

// ── AI Model Configuration ──────────────────────────────────────────
// Change this single line to switch between models.
// Supported: 'gpt-4o-mini', 'gpt-4o', 'gpt-4.1', 'gpt-5.1', etc.
const AI_MODEL = 'gpt-5.1';
const TOKEN_PARAM = AI_MODEL.startsWith('gpt-5') ? 'max_completion_tokens' : 'max_tokens';
// ─────────────────────────────────────────────────────────────────────

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

const WATERING_EMAIL_LEAD_MINUTES = 30;
const WATERING_EMAIL_FOLLOW_UP_MINUTES = 30;
/** Firestore query lower bound for nextDueAt (exclude ancient rows). */
const WATERING_EMAIL_STALE_LOOKBACK_DAYS = 3650;
/** No fixed day-cap on reminder cycles — continues until the user waters. */
const WATERING_EMAIL_MAX_REMINDERS = 100000;
/** Max stale-slot catch-up steps per plant per invocation (avoids timeouts). */
const WATERING_EMAIL_STALE_CATCHUP_MAX_STEPS = 40;
const WATERING_EMAIL_STALE_BUFFER_MS = 20 * 60 * 1000;
const WATERING_EMAIL_QUERY_LIMIT = 200;
const FCM_WATERING_MULTICAST_MAX = 500;
const DAY_MS = 24 * 60 * 60 * 1000;

function sanitizeLocale(value) {
  const locale = String(value || 'en').trim().toLowerCase();
  if (locale.startsWith('es')) return 'es';
  if (locale.startsWith('fr')) return 'fr';
  return 'en';
}

function buildReminderCycleId(plantId, nextDueAt) {
  return `${plantId}:${nextDueAt.toISOString()}`;
}

function buildWateringEmailFallback({ stage, plantName, cultivar, userName, minutesToDue, minutesOverdue, locale }) {
  const safePlantName = plantName || 'your plant';
  const safeUserName = userName || 'there';
  const cultivarHint = cultivar ? ` (${cultivar})` : '';

  if (locale === 'es') {
    if (stage === 'followup_reminder') {
      const subject = `${safePlantName}: sigue pendiente el riego`;
      const text = `Hola ${safeUserName}. Aun no registramos "I have watered" para ${safePlantName}${cultivarHint}. Si ya regaste, marca el boton en la app. Si no, riega cuando puedas.`;
      const html = `<p>Hola ${safeUserName},</p><p>Aun no registramos <strong>I have watered</strong> para <strong>${safePlantName}${cultivarHint}</strong>.</p><p>Si ya regaste, marca el boton en la app. Si no, riega cuando puedas.</p><p>- Plant Care</p>`;
      return { subject, text, html };
    }
    const dueLabel = Number.isFinite(minutesToDue) ? `${minutesToDue} min` : '30 min';
    const subject = `${safePlantName}: riego en ${dueLabel}`;
    const text = `Hola ${safeUserName}. Recordatorio: ${safePlantName}${cultivarHint} deberia regarse en aproximadamente ${dueLabel}. Despues de regar, pulsa "I have watered" en la app.`;
    const html = `<p>Hola ${safeUserName},</p><p>Recordatorio: <strong>${safePlantName}${cultivarHint}</strong> deberia regarse en aproximadamente <strong>${dueLabel}</strong>.</p><p>Despues de regar, pulsa <strong>I have watered</strong> en la app.</p><p>- Plant Care</p>`;
    return { subject, text, html };
  }

  if (locale === 'fr') {
    if (stage === 'followup_reminder') {
      const subject = `${safePlantName}: arrosage toujours en attente`;
      const text = `Bonjour ${safeUserName}. Nous n'avons pas encore recu "I have watered" pour ${safePlantName}${cultivarHint}. Si vous avez deja arrose, confirmez-le dans l'app. Sinon, arrosez quand possible.`;
      const html = `<p>Bonjour ${safeUserName},</p><p>Nous n'avons pas encore recu <strong>I have watered</strong> pour <strong>${safePlantName}${cultivarHint}</strong>.</p><p>Si vous avez deja arrose, confirmez-le dans l'app. Sinon, arrosez quand possible.</p><p>- Plant Care</p>`;
      return { subject, text, html };
    }
    const dueLabel = Number.isFinite(minutesToDue) ? `${minutesToDue} min` : '30 min';
    const subject = `${safePlantName}: arrosage dans ${dueLabel}`;
    const text = `Bonjour ${safeUserName}. Rappel: ${safePlantName}${cultivarHint} devrait etre arrose dans environ ${dueLabel}. Apres arrosage, appuyez sur "I have watered" dans l'app.`;
    const html = `<p>Bonjour ${safeUserName},</p><p>Rappel: <strong>${safePlantName}${cultivarHint}</strong> devrait etre arrose dans environ <strong>${dueLabel}</strong>.</p><p>Apres arrosage, appuyez sur <strong>I have watered</strong> dans l'app.</p><p>- Plant Care</p>`;
    return { subject, text, html };
  }

  if (stage === 'followup_reminder') {
    const overdueLabel = Number.isFinite(minutesOverdue) ? `${minutesOverdue} min` : '30 min';
    const subject = `${safePlantName}: watering still pending`;
    const text = `Hi ${safeUserName}. We still do not see "I have watered" for ${safePlantName}${cultivarHint}. It is about ${overdueLabel} past due. If you already watered, please tap the button in the app.`;
    const html = `<p>Hi ${safeUserName},</p><p>We still do not see <strong>I have watered</strong> for <strong>${safePlantName}${cultivarHint}</strong>.</p><p>It is about <strong>${overdueLabel}</strong> past due. If you already watered, please tap the button in the app.</p><p>- Plant Care</p>`;
    return { subject, text, html };
  }

  const dueLabel = Number.isFinite(minutesToDue) ? `${minutesToDue} min` : '30 min';
  const subject = `${safePlantName}: watering in ${dueLabel}`;
  const text = `Hi ${safeUserName}. Reminder: ${safePlantName}${cultivarHint} is due for watering in about ${dueLabel}. After watering, please tap "I have watered" in the app.`;
  const html = `<p>Hi ${safeUserName},</p><p>Reminder: <strong>${safePlantName}${cultivarHint}</strong> is due for watering in about <strong>${dueLabel}</strong>.</p><p>After watering, please tap <strong>I have watered</strong> in the app.</p><p>- Plant Care</p>`;
  return { subject, text, html };
}

function buildWateringEmailPrompt(input) {
  const payload = {
    locale: input.locale,
    stage: input.stage,
    plantName: input.plantName,
    cultivar: input.cultivar || null,
    userName: input.userName || null,
    minutesToDue: input.minutesToDue ?? null,
    minutesOverdue: input.minutesOverdue ?? null,
    recommendedAmountMl: input.recommendedAmountMl ?? null,
  };

  return `You generate short watering reminder emails for Plant Care app.
Return ONLY valid JSON:
{
  "subject": "string",
  "text": "string",
  "html": "string"
}

Rules:
- Language locale="${input.locale}".
- Stage is "${input.stage}".
- Mention the plant name naturally.
- Keep it concise and friendly.
- No markdown.
- Subject max 60 chars.
- Text max 320 chars.
- HTML must be simple <p> blocks only.
- Include exact button label: "I have watered".
- Do not invent scientific claims.

Input JSON:
${JSON.stringify(payload, null, 2)}`;
}

async function generateWateringEmailWithAI(input) {
  const fallback = buildWateringEmailFallback(input);
  try {
    const openaiClient = await initializeOpenAI();
    if (!openaiClient || !openaiClient.apiKey) return fallback;

    const response = await openaiClient.chat.completions.create({
      model: AI_MODEL,
      temperature: 0.3,
      [TOKEN_PARAM]: 260,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: 'You are a concise email copywriter. Output JSON only.' },
        { role: 'user', content: buildWateringEmailPrompt(input) },
      ],
    });

    const content = response?.choices?.[0]?.message?.content;
    if (!content) return fallback;
    const parsed = JSON.parse(content);
    const subject = String(parsed.subject || '').trim();
    const text = String(parsed.text || '').trim();
    const html = String(parsed.html || '').trim();
    if (!subject || !text || !html) return fallback;
    if (subject.length > 100 || text.length > 1200 || html.length > 6000) return fallback;
    return { subject, text, html };
  } catch (e) {
    console.warn('⚠️ Watering email AI generation failed, fallback used:', e.message);
    return fallback;
  }
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

// ── Wikipedia plant image search ──────────────────────────────────
function wikiImageSearch(scientificName) {
  const https = require('https');
  const slug = scientificName.replace(/\s+/g, '_');
  const url = `https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(slug)}`;

  return new Promise((resolve) => {
    https.get(url, { headers: { 'User-Agent': 'PlantCareApp/1.0' } }, (resp) => {
      let data = '';
      resp.on('data', (chunk) => { data += chunk; });
      resp.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve(parsed.thumbnail?.source || null);
        } catch (e) { resolve(null); }
      });
    }).on('error', () => resolve(null));
  });
}

exports.searchPlantImages = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const { speciesNames } = req.body;
      if (!speciesNames || !Array.isArray(speciesNames) || speciesNames.length === 0) {
        return res.status(400).json({ error: 'speciesNames array is required' });
      }

      const results = await Promise.all(
        speciesNames.map(async (name) => {
          const imageUrl = await wikiImageSearch(name);
          return { name, imageUrl };
        })
      );

      res.json({ results });
    } catch (error) {
      console.error('❌ searchPlantImages error:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// ── Plant photo analysis (with top-3 species identification) ──────
exports.analyzePlantPhoto = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      // Initialize OpenAI with API key from secrets
      const openaiClient = await initializeOpenAI();
      
      // Check if API key is configured
      if (!openaiClient.apiKey) {
        throw new Error('OPENAI_API_KEY is not configured');
      }

      const { base64Image, userHint, confirmedSpecies } = req.body;

      if (!base64Image) {
        return res.status(400).json({ error: 'Base64 image is required' });
      }

      console.log('🔍 Starting image analysis');
      console.log('🔍 Image length:', base64Image.length);
      if (userHint) console.log('🔍 User hint:', userHint);
      if (confirmedSpecies) console.log('🔍 Confirmed species:', confirmedSpecies);

      // ── STEP 1: If species is already confirmed, skip identification ──
      if (confirmedSpecies) {
        console.log('🔍 Species confirmed, fetching full recommendations for:', confirmedSpecies);
        const fullPrompt = buildFullAnalysisPrompt(confirmedSpecies);
        const imageUrl = `data:image/jpeg;base64,${base64Image}`;

        const response = await openaiClient.chat.completions.create({
          model: AI_MODEL,
          messages: [{
            role: 'user',
            content: [
              { type: 'text', text: fullPrompt },
              { type: 'image_url', image_url: { url: imageUrl } },
            ],
          }],
          [TOKEN_PARAM]: 3000,
          temperature: 0.5,
        });

        const content = response.choices[0].message.content;
        let recommendations = parseAIResponse(content);
        recommendations = normalizeRecommendations(recommendations, req.body || {});

        return res.json({ success: true, recommendations, rawResponse: content });
      }

      // ── STEP 2: Identify top 3 species candidates ──
      const identifyPrompt = buildSpeciesIdentificationPrompt(userHint);
      const imageUrl = `data:image/jpeg;base64,${base64Image}`;

      const idResponse = await openaiClient.chat.completions.create({
        model: AI_MODEL,
        messages: [{
          role: 'user',
          content: [
            { type: 'text', text: identifyPrompt },
            { type: 'image_url', image_url: { url: imageUrl } },
          ],
        }],
        [TOKEN_PARAM]: 1000,
        temperature: 0.7,
      });

      const idContent = idResponse.choices[0].message.content;
      console.log('🔍 Species identification response:', idContent);

      let speciesCandidates;
      try {
        const cleaned = idContent.replace(/```json\s*/g, '').replace(/```\s*/g, '').trim();
        speciesCandidates = JSON.parse(cleaned);
      } catch (e) {
        console.error('❌ Failed to parse species candidates:', e.message);
        speciesCandidates = { top_3_species: [{ scientific_name: 'Unknown', common_name: 'Unknown plant', confidence: 0.5, visual_hint: 'Could not identify' }] };
      }

      // Fetch images from Wikipedia for each candidate
      if (speciesCandidates.top_3_species) {
        await Promise.all(
          speciesCandidates.top_3_species.map(async (sp) => {
            sp.image_url = await wikiImageSearch(sp.scientific_name);
          })
        );
      }

      return res.json({
        success: true,
        step: 'identification',
        speciesCandidates: speciesCandidates.top_3_species || [],
      });

    } catch (error) {
      console.error('❌ Plant Photo Analysis Error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });
});

function buildSpeciesIdentificationPrompt(userHint) {
  const hintLine = userHint
    ? `The user suggests this might be: "${userHint}". Consider this hint but still rely on your visual analysis.`
    : '';

  return `Analyze this plant photo and identify the TOP 3 most likely species.
${hintLine}

Return ONLY valid JSON (no markdown, no explanations):
{
  "top_3_species": [
    {
      "scientific_name": "Genus species",
      "common_name": "Common name in English",
      "confidence": 0.95,
      "visual_hint": "Brief 1-sentence description of key visual features that distinguish this species"
    },
    {
      "scientific_name": "...",
      "common_name": "...",
      "confidence": 0.7,
      "visual_hint": "..."
    },
    {
      "scientific_name": "...",
      "common_name": "...",
      "confidence": 0.4,
      "visual_hint": "..."
    }
  ]
}

Rules:
- confidence is 0.0–1.0, must decrease from first to third
- scientific_name must be real botanical names (Genus species format)
- common_name should be the most widely used English common name
- visual_hint should describe what makes this species look like the photo
- Always return exactly 3 candidates, even if uncertain
- If the photo is unclear, still provide your best guesses with lower confidence`;
}

function buildFullAnalysisPrompt(confirmedSpecies) {
  return `This plant has been identified as: ${confirmedSpecies}.

Your goal is to determine, for this specific plant, based only on:

the species you identify from the photo (confirmed as ${confirmedSpecies}),
the visible soil condition,
the pot size and pot material (if visible),
the plant's size and leaf type,
the surrounding environment (indoor/outdoor, visible light),
how many whole days remain until the next watering.

You must return only a JSON object following the schema below.

General Rules
1. Base the calculation on the confirmed species: ${confirmedSpecies}

Use your internal botanical knowledge:
- how often THIS species is usually watered indoors in a pot
- how drought-tolerant it is
- how fast it typically dries
- what watering interval is normal for its physiology

Do NOT use or output any categories like "succulent", "tropical", etc.

2. Adjust the interval using the photo

Use factors only if visible; if not visible, safely skip them:
- soil dryness state (very_dry / dry / slightly_dry / moist / wet / not_visible)
- pot diameter + height (approximate)
- pot material (plastic / terracotta / fabric / ceramic)
- size and type of plant (leaf thickness, growth form)
- whether plant appears indoors or outdoors
- light intensity in the photo (bright / medium / dim)

3. Watering Logic
- should_water_now (boolean)
- next_watering_in_days (integer 1–60)
- If should water now, next_watering_in_days = days until the watering after this one.
- If should not water now, next_watering_in_days = days from today.

4. Output: whole days only, 1–60 range.

Return ONLY a JSON object:
{
  "species": { "user_species_name": null, "ai_species_guess": "${confirmedSpecies}", "species_confidence": 1.0 },
  "soil": { "visual_state": "...", "moisture_current_pct": 0 },
  "watering_plan": { "should_water_now": false, "next_watering_in_days": 7, "amount_ml": 250, "reason_short": "..." },
  "care_recommendations": {
    "name": "${confirmedSpecies}", "general_description": "...", "moisture": "...", "water": "...",
    "light": "...", "temperature": "...", "fertilizer": "...", "soil": "...",
    "growth_rate": "...", "toxicity": "...", "placement": "...", "personality": "..."
  },
  "other_care": { "growth_stage": "Seedling/Young/Mature/Established" },
  "interesting_facts": ["...", "...", "...", "..."],
  "specific_issues": ["...", "...", "..."],
  "health_assessment": "...",
  "plant_assistant": {
    "status": "healthy or issue_detected", "praise_phrase": "...", "health_summary": "...",
    "maintenance_footer": "...", "problem_name": "...", "problem_description": "...",
    "severity": "mild/moderate/serious", "action_steps": ["..."], "follow_up_days": 5, "reassurance": "..."
  }
}

Plant assistant rules: "healthy" if plant looks fine, else "issue_detected".
specific_issues: 2-3 SPECIES-SPECIFIC CARE RISKS (not current problems).
amount_ml: 50-1500 for normal pots, up to 2500 for very large containers.
In care_recommendations.name, use "${confirmedSpecies}".

Return ONLY JSON. No text. No markdown.`;
}

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
          model: AI_MODEL,
          messages: [{ role: 'user', content: contentBlocks }],
          [TOKEN_PARAM]: 3000,
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
        model: AI_MODEL,
        messages,
        [TOKEN_PARAM]: 900,
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

exports.sendTestWateringReminderEmail = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ success: false, error: 'Method not allowed' });
      }

      const {
        plantId,
        userId,
        stage = 'first_reminder',
        locale,
      } = req.body || {};

      if (!plantId || !userId) {
        return res.status(400).json({
          success: false,
          error: 'plantId and userId are required',
        });
      }

      if (stage !== 'first_reminder' && stage !== 'followup_reminder') {
        return res.status(400).json({
          success: false,
          error: 'Invalid stage. Use first_reminder or followup_reminder.',
        });
      }

      const authHeader = String(req.headers.authorization || '');
      const bearerToken = authHeader.startsWith('Bearer ')
        ? authHeader.slice('Bearer '.length).trim()
        : '';
      if (!bearerToken) {
        return res.status(401).json({ success: false, error: 'Missing bearer token.' });
      }

      let decoded;
      try {
        decoded = await admin.auth().verifyIdToken(bearerToken);
      } catch (_) {
        return res.status(401).json({ success: false, error: 'Invalid auth token.' });
      }

      if (!decoded || decoded.uid !== userId) {
        return res.status(403).json({ success: false, error: 'User mismatch.' });
      }

      const db = admin.firestore();
      const plantDoc = await db.collection('plants').doc(plantId).get();
      if (!plantDoc.exists) {
        return res.status(404).json({ success: false, error: 'Plant not found.' });
      }

      const plantData = plantDoc.data() || {};
      if (plantData.userId !== userId) {
        return res.status(403).json({ success: false, error: 'Plant access denied.' });
      }

      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.exists ? (userDoc.data() || {}) : {};
      const userRecord = await admin.auth().getUser(userId);
      const email = userData.email || userRecord.email || null;
      if (!email || !isValidEmail(email)) {
        return res.status(400).json({ success: false, error: 'No valid user email found.' });
      }

      const nextDueAt = toDateSafe(plantData.nextDueAt || plantData.nextWatering) || new Date(Date.now() + 30 * 60 * 1000);
      const now = new Date();
      const minutesToDue = Math.max(0, Math.round((nextDueAt.getTime() - now.getTime()) / 60000));
      const minutesOverdue = Math.max(0, Math.round((now.getTime() - nextDueAt.getTime()) / 60000));

      const emailCopy = await generateWateringEmailWithAI({
        stage,
        locale: sanitizeLocale(locale || userData.locale || userData.language || 'en'),
        plantName: plantData.name || 'your plant',
        cultivar: plantData.aiName || plantData.species || null,
        userName: userData.name || userRecord.displayName || null,
        minutesToDue,
        minutesOverdue,
        recommendedAmountMl: plantData.wateringAmountMl || null,
      });

      await db.collection('mail').add({
        to: email,
        message: {
          subject: emailCopy.subject,
          text: emailCopy.text,
          html: emailCopy.html,
        },
      });

      return res.json({
        success: true,
        queued: true,
        stage,
        to: email,
      });
    } catch (error) {
      console.error('sendTestWateringReminderEmail error:', error);
      return res.status(500).json({
        success: false,
        error: 'Could not queue test watering email.',
      });
    }
  });
});

/**
 * Remove invalid FCM tokens from the fcm_tokens collection
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

    const batch = db.batch();
    for (const token of invalidTokens) {
      batch.delete(db.collection('fcm_tokens').doc(token));
    }
    await batch.commit();

    const userRef = db.collection('users').doc(userId);
    const userSnap = await userRef.get();
    if (userSnap.exists) {
      const arr = userSnap.data().fcmTokens;
      if (Array.isArray(arr)) {
        const next = arr.filter((t) => !invalidTokens.includes(String(t)));
        if (next.length !== arr.length) {
          await userRef.update({ fcmTokens: next });
        }
      }
    }
  }
}

function truncateForFcmNotification(s, maxLen) {
  const t = String(s || '').trim().replace(/\s+/g, ' ');
  if (t.length <= maxLen) return t;
  return `${t.slice(0, maxLen - 1)}…`;
}

/**
 * FCM for the same watering reminder slot as email (shared subject/text).
 */
async function sendWateringReminderPushMulticast(
  db,
  userId,
  tokens,
  plantId,
  plantName,
  emailCopy,
  stage
) {
  if (!tokens || tokens.length === 0) return 0;
  let successTotal = 0;
  for (let i = 0; i < tokens.length; i += FCM_WATERING_MULTICAST_MAX) {
    const chunk = tokens.slice(i, i + FCM_WATERING_MULTICAST_MAX);
    const title = truncateForFcmNotification(emailCopy.subject, 100);
    const body = truncateForFcmNotification(emailCopy.text, 240);
    const message = {
      notification: { title, body },
      data: {
        type: 'watering_reminder',
        stage: String(stage),
        plantId: String(plantId),
        plantName: String(plantName || 'Plant'),
        action: 'open_plant',
      },
      android: { priority: 'high' },
      apns: {
        headers: { 'apns-priority': '10' },
        payload: { aps: { sound: 'default' } },
      },
      tokens: chunk,
    };
    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      successTotal += response.successCount;
      if (response.failureCount > 0) {
        const firstErr = response.responses.find((r) => !r.success)?.error;
        console.warn(
          `⚠️ FCM watering reminder partial failure user=${userId} ok=${response.successCount} fail=${response.failureCount} first=${firstErr?.code || firstErr?.message || firstErr}`
        );
      }
      await removeInvalidTokens(db, userId, chunk, response);
    } catch (e) {
      console.error('❌ FCM watering reminder send error:', e.message);
    }
  }
  return successTotal;
}

/**
 * On-demand HTTP function to validate and clean up stale FCM tokens
 * from the fcm_tokens collection. For each token document it sends a
 * dry-run message; tokens no longer registered with FCM are deleted.
 *
 * Call via: https://<region>-<project>.cloudfunctions.net/cleanupStaleFCMTokens
 */
exports.cleanupStaleFCMTokens = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const db = admin.firestore();
      const tokenSnap = await db.collection('fcm_tokens').get();

      let totalTokensChecked = 0;
      let totalTokensRemoved = 0;

      for (const tokenDoc of tokenSnap.docs) {
        const token = tokenDoc.id;
        totalTokensChecked++;
        try {
          await admin.messaging().send(
            { token, notification: { title: 'test' } },
            true // dryRun
          );
        } catch (err) {
          const code = err.code || '';
          if (
            code === 'messaging/invalid-registration-token' ||
            code === 'messaging/registration-token-not-registered' ||
            code === 'messaging/invalid-argument'
          ) {
            await tokenDoc.ref.delete();
            totalTokensRemoved++;
            console.log(`🗑️ Deleted stale token for user ${tokenDoc.data().userId}`);
          }
        }
      }

      const summary = {
        success: true,
        tokensChecked: totalTokensChecked,
        tokensRemoved: totalTokensRemoved,
      };
      console.log('✅ cleanupStaleFCMTokens finished:', summary);
      res.status(200).json(summary);
    } catch (error) {
      console.error('❌ cleanupStaleFCMTokens error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });
});

/**
 * One-time migration: copy fcmTokens[] from each user doc into the
 * dedicated fcm_tokens collection (doc ID = token, body = { userId }).
 * Safe to run multiple times — uses set() which is idempotent.
 *
 * Call via: https://<region>-<project>.cloudfunctions.net/migrateFcmTokens
 */
exports.migrateFcmTokens = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const db = admin.firestore();
      const usersSnap = await db.collection('users').get();

      let usersProcessed = 0;
      let tokensMigrated = 0;

      for (const userDoc of usersSnap.docs) {
        const data = userDoc.data();
        const tokens = data.fcmTokens || [];
        if (tokens.length === 0) continue;

        usersProcessed++;
        const batch = db.batch();
        for (const token of tokens) {
          batch.set(db.collection('fcm_tokens').doc(token), {
            userId: userDoc.id,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          tokensMigrated++;
        }
        await batch.commit();
      }

      const summary = {
        success: true,
        usersProcessed,
        tokensMigrated,
      };
      console.log('✅ migrateFcmTokens finished:', summary);
      res.status(200).json(summary);
    } catch (error) {
      console.error('❌ migrateFcmTokens error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });
});

/**
 * FCM tokens for a user: fcm_tokens collection + legacy users.fcmTokens[].
 */
async function fetchMergedFcmTokens(db, uid) {
  const snap = await db.collection('fcm_tokens').where('userId', '==', uid).get();
  const seen = new Set();
  const tokens = [];
  for (const d of snap.docs) {
    if (!seen.has(d.id)) {
      seen.add(d.id);
      tokens.push(d.id);
    }
  }
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      const arr = userDoc.data().fcmTokens;
      if (Array.isArray(arr)) {
        for (const t of arr) {
          const s = typeof t === 'string' ? t.trim() : '';
          if (s.length > 20 && !seen.has(s)) {
            seen.add(s);
            tokens.push(s);
          }
        }
      }
    }
  } catch (_) {}
  return tokens;
}

/**
 * Test / scheduled push (same transport as watering reminders).
 */
async function sendFcmTestMulticast(db, userId, tokens, title, body) {
  if (!tokens || tokens.length === 0) return 0;
  let successTotal = 0;
  const t = truncateForFcmNotification(title, 100);
  const b = truncateForFcmNotification(body, 240);
  for (let i = 0; i < tokens.length; i += FCM_WATERING_MULTICAST_MAX) {
    const chunk = tokens.slice(i, i + FCM_WATERING_MULTICAST_MAX);
    const message = {
      notification: { title: t, body: b },
      data: {
        type: 'test_push',
        action: 'none',
      },
      android: { priority: 'high' },
      apns: {
        headers: { 'apns-priority': '10' },
        payload: { aps: { sound: 'default' } },
      },
      tokens: chunk,
    };
    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      successTotal += response.successCount;
      if (response.failureCount > 0) {
        const firstErr = response.responses.find((r) => !r.success)?.error;
        console.warn(
          `⚠️ FCM test push partial failure user=${userId} ok=${response.successCount} fail=${response.failureCount} first=${firstErr?.code || firstErr?.message || firstErr}`
        );
      }
      await removeInvalidTokens(db, userId, chunk, response);
    } catch (e) {
      console.error('❌ FCM test push send error:', e.message);
    }
  }
  return successTotal;
}

/**
 * Schedule a test FCM push for the signed-in user (delay 1–1440 minutes).
 * POST JSON: { delayMinutes?: number, title?: string, body?: string }
 * Header: Authorization: Bearer <Firebase ID token>
 *
 * A scheduled job sends the push shortly after sendAt (runs every minute).
 */
exports.scheduleTestPush = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ success: false, error: 'Method not allowed' });
      }

      const authHeader = String(req.headers.authorization || '');
      const bearerToken = authHeader.startsWith('Bearer ')
        ? authHeader.slice('Bearer '.length).trim()
        : '';
      if (!bearerToken) {
        return res.status(401).json({ success: false, error: 'Missing bearer token.' });
      }

      let decoded;
      try {
        decoded = await admin.auth().verifyIdToken(bearerToken);
      } catch (_) {
        return res.status(401).json({ success: false, error: 'Invalid auth token.' });
      }

      const uid = decoded.uid;
      const body = req.body || {};
      let delayMinutes = Number(body.delayMinutes);
      if (!Number.isFinite(delayMinutes)) delayMinutes = 20;
      delayMinutes = Math.round(delayMinutes);
      delayMinutes = Math.min(1440, Math.max(1, delayMinutes));

      const title =
        typeof body.title === 'string' && body.title.trim()
          ? body.title.trim().slice(0, 80)
          : 'Plant Care — test push';
      const text =
        typeof body.body === 'string' && body.body.trim()
          ? body.body.trim().slice(0, 200)
          : `Тестовый push через ${delayMinutes} мин. Если видишь это уведомление — FCM работает.`;

      const sendAt = admin.firestore.Timestamp.fromMillis(Date.now() + delayMinutes * 60 * 1000);
      const db = admin.firestore();
      const ref = await db.collection('scheduled_test_pushes').add({
        userId: uid,
        sendAt,
        status: 'pending',
        title,
        body: text,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.json({
        success: true,
        id: ref.id,
        sendAt: sendAt.toDate().toISOString(),
        delayMinutes,
      });
    } catch (error) {
      console.error('scheduleTestPush error:', error);
      return res.status(500).json({ success: false, error: error.message });
    }
  });
});

/**
 * Sends due scheduled test pushes (created by scheduleTestPush).
 */
exports.processScheduledTestPushes = functions.pubsub
  .schedule('every 1 minutes')
  .timeZone('Etc/UTC')
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const snap = await db
      .collection('scheduled_test_pushes')
      .where('sendAt', '<=', now)
      .orderBy('sendAt', 'asc')
      .limit(100)
      .get();

    let sent = 0;
    let failed = 0;
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      if (data.status !== 'pending') continue;
      const uid = data.userId;
      if (!uid) {
        await doc.ref.update({
          status: 'failed',
          error: 'missing userId',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        failed += 1;
        continue;
      }

      const tokens = await fetchMergedFcmTokens(db, uid);
      if (tokens.length === 0) {
        await doc.ref.update({
          status: 'failed',
          error: 'no_fcm_tokens',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        failed += 1;
        continue;
      }

      const title = data.title || 'Plant Care — test push';
      const body = data.body || 'Test push';
      const ok = await sendFcmTestMulticast(db, uid, tokens, title, body);
      if (ok > 0) {
        await doc.ref.update({
          status: 'sent',
          devicesOk: ok,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        sent += 1;
        console.log(`✅ scheduled test push sent doc=${doc.id} user=${uid} devices=${ok}`);
      } else {
        await doc.ref.update({
          status: 'failed',
          error: 'fcm_zero_success',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        failed += 1;
      }
    }

    if (sent || failed) {
      console.log(`📲 processScheduledTestPushes: sent=${sent} failed=${failed}`);
    }
    return null;
  });

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

/**
 * Watering reminders: same schedule for email (mail collection) and FCM.
 * User prefs: users.{uid}.wateringReminderChannels { email, push } (default both true).
 */
exports.processWateringEmailReminders = functions.pubsub
  .schedule('every 10 minutes')
  .timeZone('Etc/UTC')
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();
    const preWindowMs = WATERING_EMAIL_LEAD_MINUTES * 60 * 1000;
    const followWindowMs = WATERING_EMAIL_FOLLOW_UP_MINUTES * 60 * 1000;
    const horizon = new Date(now.getTime() + preWindowMs);
    const staleCutoff = new Date(now.getTime() - WATERING_EMAIL_STALE_LOOKBACK_DAYS * DAY_MS);
    const nowIso = now.toISOString();
    const userCache = new Map();
    const fcmTokenCache = new Map();

    function getReminderTime(nextDueAt, index) {
      const day = Math.floor(index / 2);
      const isPre = index % 2 === 0;
      const baseTime = nextDueAt.getTime() + day * DAY_MS;
      return new Date(isPre ? baseTime - preWindowMs : baseTime + followWindowMs);
    }

    async function getUserInfo(uid) {
      if (userCache.has(uid)) return userCache.get(uid);
      let info = {
        email: null,
        locale: 'en',
        name: null,
        channels: { email: true, push: true },
      };
      try {
        const userDoc = await db.collection('users').doc(uid).get();
        const data = userDoc.exists ? (userDoc.data() || {}) : {};
        const ch = data.wateringReminderChannels || {};
        info = {
          email: data.email || data.emailLower || null,
          locale: sanitizeLocale(data.locale || data.language || 'en'),
          name: data.name || data.displayName || null,
          channels: {
            email: ch.email !== false,
            push: ch.push !== false,
          },
        };
      } catch (_) {}

      if (!info.email) {
        try {
          const userRecord = await admin.auth().getUser(uid);
          info.email = userRecord.email || null;
          info.name = info.name || userRecord.displayName || null;
        } catch (_) {}
      }

      userCache.set(uid, info);
      return info;
    }

    async function getFcmTokensForUser(uid) {
      if (fcmTokenCache.has(uid)) return fcmTokenCache.get(uid);
      const snap = await db.collection('fcm_tokens').where('userId', '==', uid).get();
      const seen = new Set();
      const tokens = [];
      for (const d of snap.docs) {
        if (!seen.has(d.id)) {
          seen.add(d.id);
          tokens.push(d.id);
        }
      }
      try {
        const userDoc = await db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          const arr = userDoc.data().fcmTokens;
          if (Array.isArray(arr)) {
            for (const t of arr) {
              const s = typeof t === 'string' ? t.trim() : '';
              if (s.length > 20 && !seen.has(s)) {
                seen.add(s);
                tokens.push(s);
              }
            }
          }
        }
      } catch (_) {}
      fcmTokenCache.set(uid, tokens);
      return tokens;
    }

    function toDateOrNull(value) {
      if (!value) return null;
      if (value instanceof Date) return value;
      if (typeof value === 'string') {
        const d = new Date(value);
        return Number.isNaN(d.getTime()) ? null : d;
      }
      if (value.toDate) {
        try {
          return value.toDate();
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    function hasWateredSince(data, threshold) {
      const lastWatered = toDateOrNull(data.lastWateredAt || data.lastWatered);
      if (!lastWatered || !threshold) return false;
      return lastWatered.getTime() >= threshold.getTime();
    }

    const candidatesSnap = await db
      .collection('plants')
      .where('nextDueAt', '>=', staleCutoff.toISOString())
      .where('nextDueAt', '<=', horizon.toISOString())
      .limit(WATERING_EMAIL_QUERY_LIMIT)
      .get();

    let slotsCompleted = 0;
    let fcmDeliveredTotal = 0;
    let skipped = 0;

    for (const doc of candidatesSnap.docs) {
      const data = doc.data() || {};
      const uid = data.userId;
      if (!uid || data.muted === true) {
        skipped += 1;
        continue;
      }

      const nextDueAt = toDateOrNull(data.nextDueAt || data.nextWatering);
      if (!nextDueAt) {
        skipped += 1;
        continue;
      }

      const cycleId = buildReminderCycleId(doc.id, nextDueAt);

      let remindersSentCount;
      if (data.reminderCycleId === cycleId) {
        if (typeof data.remindersSentCount === 'number') {
          remindersSentCount = data.remindersSentCount;
        } else if (data.reminderFollowUpSentAt) {
          remindersSentCount = 2;
        } else if (data.reminderFirstSentAt) {
          remindersSentCount = 1;
        } else {
          remindersSentCount = 0;
        }
      } else {
        remindersSentCount = 0;
      }

      if (remindersSentCount >= WATERING_EMAIL_MAX_REMINDERS) {
        skipped += 1;
        continue;
      }

      const cycleStart = new Date(nextDueAt.getTime() - preWindowMs);
      if (hasWateredSince(data, cycleStart)) {
        if (data.reminderCycleId === cycleId && data.reminderStage !== 'completed') {
          await doc.ref.update({
            reminderCycleId: cycleId,
            reminderStage: 'completed',
            notificationState: 'ok',
            reminderLastCheckedAt: nowIso,
          });
        }
        skipped += 1;
        continue;
      }

      let staleCatchupSteps = 0;
      while (remindersSentCount < WATERING_EMAIL_MAX_REMINDERS) {
        const rt = getReminderTime(nextDueAt, remindersSentCount);
        if (now.getTime() > rt.getTime() + WATERING_EMAIL_STALE_BUFFER_MS) {
          remindersSentCount++;
          staleCatchupSteps += 1;
          if (staleCatchupSteps > WATERING_EMAIL_STALE_CATCHUP_MAX_STEPS) {
            break;
          }
        } else {
          break;
        }
      }

      if (remindersSentCount >= WATERING_EMAIL_MAX_REMINDERS) {
        await doc.ref.update({
          reminderCycleId: cycleId,
          remindersSentCount: WATERING_EMAIL_MAX_REMINDERS,
          reminderStage: 'completed',
          reminderLastCheckedAt: nowIso,
        });
        skipped += 1;
        continue;
      }

      const nextReminderTime = getReminderTime(nextDueAt, remindersSentCount);
      if (now.getTime() < nextReminderTime.getTime()) {
        skipped += 1;
        continue;
      }

      const userInfo = await getUserInfo(uid);
      const { channels } = userInfo;
      if (!channels.email && !channels.push) {
        skipped += 1;
        continue;
      }

      const hasValidEmail = !!(userInfo.email && isValidEmail(userInfo.email));
      const fcmTokens = channels.push ? await getFcmTokensForUser(uid) : [];
      const canTryEmail = channels.email && hasValidEmail;
      const canTryPush = channels.push && fcmTokens.length > 0;

      if (channels.push && fcmTokens.length === 0) {
        console.warn(
          `⚠️ Watering reminder: push enabled but no fcm_tokens for uid=${uid} plant=${doc.id}`
        );
      }

      if (!canTryEmail && !canTryPush) {
        console.warn(
          `⚠️ Reminder skipped: no delivery path for uid=${uid} (channels email=${channels.email}, push=${channels.push})`
        );
        skipped += 1;
        continue;
      }

      const isPre = remindersSentCount % 2 === 0;
      const stage = isPre ? 'first_reminder' : 'followup_reminder';
      const dayNum = Math.floor(remindersSentCount / 2) + 1;

      const locale = sanitizeLocale(userInfo.locale);
      const minutesToDue = Math.max(0, Math.round((nextDueAt.getTime() - now.getTime()) / 60000));
      const minutesOverdue = Math.max(0, Math.round((now.getTime() - nextDueAt.getTime()) / 60000));
      const plantName = data.name || 'your plant';
      const cultivar = data.aiName || data.species || null;

      const emailCopy = await generateWateringEmailWithAI({
        stage,
        locale,
        plantName,
        cultivar,
        userName: userInfo.name || null,
        minutesToDue,
        minutesOverdue,
        recommendedAmountMl: data.wateringAmountMl || null,
      });

      let mailQueued = false;
      if (canTryEmail) {
        try {
          await db.collection('mail').add({
            to: userInfo.email,
            message: {
              subject: emailCopy.subject,
              text: emailCopy.text,
              html: emailCopy.html,
            },
          });
          mailQueued = true;
        } catch (e) {
          console.error(`❌ mail queue failed for plant ${doc.id}:`, e.message);
        }
      }

      let pushSuccess = 0;
      if (canTryPush) {
        pushSuccess = await sendWateringReminderPushMulticast(
          db,
          uid,
          fcmTokens,
          doc.id,
          plantName,
          emailCopy,
          stage
        );
      }

      const delivered = mailQueued || pushSuccess > 0;
      if (!delivered) {
        skipped += 1;
        continue;
      }

      fcmDeliveredTotal += pushSuccess;

      const newCount = remindersSentCount + 1;
      await doc.ref.update({
        reminderCycleId: cycleId,
        remindersSentCount: newCount,
        reminderLastSentAt: nowIso,
        reminderLastCheckedAt: nowIso,
        reminderStage: newCount >= WATERING_EMAIL_MAX_REMINDERS ? 'completed' : (isPre ? 'pre_sent' : 'post_sent'),
        notificationState: isPre ? 'due' : 'overdue',
      });

      slotsCompleted += 1;
      console.log(
        `📬 Reminder slot #${newCount} (day ${dayNum}, ${isPre ? 'pre' : 'post'}) plant=${doc.id} mail=${mailQueued ? 'yes' : 'no'} fcm_ok=${pushSuccess}`
      );
    }

    console.log(
      `✅ processWateringEmailReminders done: slots=${slotsCompleted}, fcm_devices_ok=${fcmDeliveredTotal}, skipped=${skipped}, scanned=${candidatesSnap.size}`
    );
    return null;
  });
