const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai');
const crypto = require('crypto');
const cors = require('cors')({ origin: true });
const { taskStrings, normaliseLocale } = require('./task_strings');

// ── AI Model Configuration ──────────────────────────────────────────
// Model for watering reminder emails — cheap, template-style text.
const WATERING_EMAIL_MODEL = 'gpt-4o-mini';
const WATERING_EMAIL_TOKEN_PARAM = WATERING_EMAIL_MODEL.startsWith('gpt-5') ? 'max_completion_tokens' : 'max_tokens';

// Model for plant photo analysis (add plant + health checks) — quality matters.
const ANALYSIS_MODEL = 'gpt-5.1';
const ANALYSIS_TOKEN_PARAM = ANALYSIS_MODEL.startsWith('gpt-5') ? 'max_completion_tokens' : 'max_tokens';

// Model for chat assistant.
const CHAT_MODEL = 'gpt-5.1';
const CHAT_TOKEN_PARAM = CHAT_MODEL.startsWith('gpt-5') ? 'max_completion_tokens' : 'max_tokens';

// Prices in USD per 1M tokens (source: openai.com/api/pricing, April 2026)
const MODEL_PRICING = {
  'gpt-5.4':       { input: 2.50,  cachedInput: 0.25,   output: 15.00  },
  'gpt-5.4-mini':  { input: 0.75,  cachedInput: 0.075,  output: 4.50   },
  'gpt-5.4-nano':  { input: 0.20,  cachedInput: 0.02,   output: 1.25   },
  'gpt-5.4-pro':   { input: 30.00, cachedInput: null,   output: 180.00 },
  'gpt-5.2':       { input: 1.75,  cachedInput: 0.175,  output: 14.00  },
  'gpt-5.2-pro':   { input: 21.00, cachedInput: null,   output: 168.00 },
  'gpt-5.1':       { input: 1.25,  cachedInput: 0.125,  output: 10.00  },
  'gpt-5':         { input: 1.25,  cachedInput: 0.125,  output: 10.00  },
  'gpt-5-mini':    { input: 0.25,  cachedInput: 0.025,  output: 2.00   },
  'gpt-5-nano':    { input: 0.05,  cachedInput: 0.005,  output: 0.40   },
  'gpt-5-pro':     { input: 15.00, cachedInput: null,   output: 120.00 },
  'gpt-4.1':       { input: 2.00,  cachedInput: 0.50,   output: 8.00   },
  'gpt-4.1-mini':  { input: 0.40,  cachedInput: 0.10,   output: 1.60   },
  'gpt-4.1-nano':  { input: 0.10,  cachedInput: 0.025,  output: 0.40   },
  'gpt-4o':        { input: 2.50,  cachedInput: 1.25,   output: 10.00  },
  'gpt-4o-mini':   { input: 0.15,  cachedInput: 0.075,  output: 0.60   },
  'o4-mini':       { input: 1.10,  cachedInput: 0.275,  output: 4.40   },
  'o3':            { input: 2.00,  cachedInput: 0.50,   output: 8.00   },
  'o3-mini':       { input: 1.10,  cachedInput: 0.55,   output: 4.40   },
  'o3-pro':        { input: 20.00, cachedInput: null,   output: 80.00  },
  'o1':            { input: 15.00, cachedInput: 7.50,   output: 60.00  },
  'o1-mini':       { input: 1.10,  cachedInput: 0.55,   output: 4.40   },
};

function calcAiCost(model, inputTokens, outputTokens) {
  const p = MODEL_PRICING[model];
  if (!p) return null;
  return (inputTokens * p.input + outputTokens * p.output) / 1_000_000;
}

async function saveAiUsage(db, { userId, plantId, type, model, usage }) {
  if (!usage) return;
  try {
    const inputTokens = usage.prompt_tokens || 0;
    const outputTokens = usage.completion_tokens || 0;
    const totalTokens = usage.total_tokens || (inputTokens + outputTokens);
    const costUsd = calcAiCost(model, inputTokens, outputTokens);
    await db.collection('ai_usage').add({
      userId: userId || null,
      plantId: plantId || null,
      type,
      model,
      inputTokens,
      outputTokens,
      totalTokens,
      costUsd,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Update running totals (used by admin Overview — no index required)
    await db.collection('system').doc('ai_totals').set({
      totalCalls: admin.firestore.FieldValue.increment(1),
      totalCostUsd: admin.firestore.FieldValue.increment(costUsd ?? 0),
      totalTokens: admin.firestore.FieldValue.increment(totalTokens),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  } catch (e) {
    console.warn('⚠️ saveAiUsage failed:', e.message);
  }
}
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
            error: 'No account with that email address exists. Please check the email or sign up.',
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

// Initialize OpenAI with the key from the environment.
//
// This used to read `functions.config().openai.api_key`. The Runtime Config API
// behind that call is being shut down and deploys fail once it goes, so the key
// now travels the same way every other secret here does — through `.env`, which
// is git-ignored and set per project.
let openai;
async function initializeOpenAI() {
  if (!openai) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY is not set in the functions environment');
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
const WATERING_EMAIL_STALE_LOOKBACK_DAYS = 11;
/** Max stale-slot catch-up steps per plant per invocation (avoids timeouts). */
const WATERING_EMAIL_MAX_REMINDERS = 20;
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
  if (locale.startsWith('de')) return 'de';
  if (locale.startsWith('ru')) return 'ru';
  if (locale.startsWith('uk')) return 'uk';
  return 'en';
}

function buildReminderCycleId(plantId, nextDueAt) {
  return `v2:${plantId}:${nextDueAt.toISOString()}`;
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

  if (locale === 'de') {
    if (stage === 'followup_reminder') {
      const subject = `${safePlantName}: Gießen noch ausstehend`;
      const text = `Hallo ${safeUserName}. Wir haben noch kein "I have watered" für ${safePlantName}${cultivarHint} erhalten. Falls du schon gegossen hast, tippe den Button in der App. Wenn nicht, gieße bitte, sobald du kannst.`;
      const html = `<p>Hallo ${safeUserName},</p><p>Wir haben noch kein <strong>I have watered</strong> für <strong>${safePlantName}${cultivarHint}</strong> erhalten.</p><p>Falls du schon gegossen hast, tippe den Button in der App. Wenn nicht, gieße bitte, sobald du kannst.</p><p>- Plant Care</p>`;
      return { subject, text, html };
    }
    const dueLabel = Number.isFinite(minutesToDue) ? `${minutesToDue} min` : '30 min';
    const subject = `${safePlantName}: Gießen in ${dueLabel}`;
    const text = `Hallo ${safeUserName}. Erinnerung: ${safePlantName}${cultivarHint} sollte in etwa ${dueLabel} gegossen werden. Tippe nach dem Gießen auf "I have watered" in der App.`;
    const html = `<p>Hallo ${safeUserName},</p><p>Erinnerung: <strong>${safePlantName}${cultivarHint}</strong> sollte in etwa <strong>${dueLabel}</strong> gegossen werden.</p><p>Tippe nach dem Gießen auf <strong>I have watered</strong> in der App.</p><p>- Plant Care</p>`;
    return { subject, text, html };
  }

  if (locale === 'ru') {
    if (stage === 'followup_reminder') {
      const subject = `${safePlantName}: полив всё ещё ожидается`;
      const text = `Привет, ${safeUserName}. Мы пока не видим "I have watered" для ${safePlantName}${cultivarHint}. Если вы уже полили, нажмите кнопку в приложении. Если нет — полейте, когда сможете.`;
      const html = `<p>Привет, ${safeUserName}!</p><p>Мы пока не видим <strong>I have watered</strong> для <strong>${safePlantName}${cultivarHint}</strong>.</p><p>Если вы уже полили, нажмите кнопку в приложении. Если нет — полейте, когда сможете.</p><p>- Plant Care</p>`;
      return { subject, text, html };
    }
    const dueLabel = Number.isFinite(minutesToDue) ? `${minutesToDue} мин` : '30 мин';
    const subject = `${safePlantName}: полив через ${dueLabel}`;
    const text = `Привет, ${safeUserName}. Напоминание: ${safePlantName}${cultivarHint} нужно полить примерно через ${dueLabel}. После полива нажмите "I have watered" в приложении.`;
    const html = `<p>Привет, ${safeUserName}!</p><p>Напоминание: <strong>${safePlantName}${cultivarHint}</strong> нужно полить примерно через <strong>${dueLabel}</strong>.</p><p>После полива нажмите <strong>I have watered</strong> в приложении.</p><p>- Plant Care</p>`;
    return { subject, text, html };
  }

  if (locale === 'uk') {
    if (stage === 'followup_reminder') {
      const subject = `${safePlantName}: полив усе ще очікується`;
      const text = `Привіт, ${safeUserName}. Ми поки не бачимо "I have watered" для ${safePlantName}${cultivarHint}. Якщо ви вже полили, натисніть кнопку в застосунку. Якщо ні — полийте, коли зможете.`;
      const html = `<p>Привіт, ${safeUserName}!</p><p>Ми поки не бачимо <strong>I have watered</strong> для <strong>${safePlantName}${cultivarHint}</strong>.</p><p>Якщо ви вже полили, натисніть кнопку в застосунку. Якщо ні — полийте, коли зможете.</p><p>- Plant Care</p>`;
      return { subject, text, html };
    }
    const dueLabel = Number.isFinite(minutesToDue) ? `${minutesToDue} хв` : '30 хв';
    const subject = `${safePlantName}: полив через ${dueLabel}`;
    const text = `Привіт, ${safeUserName}. Нагадування: ${safePlantName}${cultivarHint} треба полити приблизно через ${dueLabel}. Після поливу натисніть "I have watered" у застосунку.`;
    const html = `<p>Привіт, ${safeUserName}!</p><p>Нагадування: <strong>${safePlantName}${cultivarHint}</strong> треба полити приблизно через <strong>${dueLabel}</strong>.</p><p>Після поливу натисніть <strong>I have watered</strong> у застосунку.</p><p>- Plant Care</p>`;
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

async function generateWateringEmailWithAI(input, usageCtx) {
  const fallback = buildWateringEmailFallback(input);
  try {
    const openaiClient = await initializeOpenAI();
    if (!openaiClient || !openaiClient.apiKey) return fallback;

    const response = await openaiClient.chat.completions.create({
      model: WATERING_EMAIL_MODEL,
      temperature: 0.3,
      [WATERING_EMAIL_TOKEN_PARAM]: 260,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: 'You are a concise email copywriter. Output JSON only.' },
        { role: 'user', content: buildWateringEmailPrompt(input) },
      ],
    });

    if (response.usage && usageCtx) {
      const db = admin.firestore();
      await saveAiUsage(db, { ...usageCtx, type: 'watering_email', model: WATERING_EMAIL_MODEL, usage: response.usage });
    }

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

const HEALTH_CHECK_IMAGE_TIERS = [1, 3];

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

  // The result screen renders a score ring, finding cards and an action checklist —
  // all three have to arrive or the user gets an empty layout.
  const score = Number(recommendations.health_score);
  if (!Number.isFinite(score) || score < 0 || score > 100) {
    return { ok: false, reason: 'missing_health_score' };
  }

  const hasTitled = (arr) =>
    Array.isArray(arr) && arr.some((x) => x && String(x.title || '').trim().length > 0);
  if (!hasTitled(recommendations.findings)) {
    return { ok: false, reason: 'missing_findings' };
  }
  if (!hasTitled(recommendations.recommendations)) {
    return { ok: false, reason: 'missing_recommendations_list' };
  }

  // A "healthy" verdict paired with a failing score (or vice versa) reads as broken
  // to the user: green chip over a red ring.
  const status = String(plantAssistant.status || '').toLowerCase();
  if (status === 'healthy' && score < 75) {
    return { ok: false, reason: 'score_contradicts_healthy' };
  }
  if (status === 'issue_detected' && score >= 75) {
    return { ok: false, reason: 'score_contradicts_issue' };
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

function buildHealthCheckContentBlocks(promptText, currentImageUrls, previousImageUrls, isRetry) {
  // currentImageUrls can be a single string (legacy) or an array (multi-photo)
  const currentUrls = Array.isArray(currentImageUrls) ? currentImageUrls : [currentImageUrls];

  const photoLabels = ['Photo 1 (full plant)', 'Photo 2 (close-up)', 'Photo 3 (problem area)'];

  const blocks = [
    {
      type: 'text',
      text: isRetry
        ? `CRITICAL: Return ONLY valid JSON. ${promptText}`
        : promptText,
    },
  ];

  currentUrls.forEach((url, idx) => {
    if (!url) return;
    if (currentUrls.length > 1) {
      blocks.push({ type: 'text', text: photoLabels[idx] || `Photo ${idx + 1}` });
    }
    blocks.push({ type: 'image_url', image_url: { url } });
  });

  for (const previousUrl of previousImageUrls) {
    blocks.push({ type: 'image_url', image_url: { url: previousUrl } });
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
    recommendations = normalizeHealthReport(recommendations);
  } catch (e) {
    console.error('❌ Error normalizing recommendations:', e);
  }
  return recommendations;
}

/** Categories the client can render an icon for; anything else falls back to 'leaves'. */
const FINDING_CATEGORIES = ['light', 'water', 'soil', 'leaves', 'pests'];

const MAX_FINDINGS = 3;
const MAX_HEALTH_RECOMMENDATIONS = 3;

/**
 * Clamps and trims the health-report fields (score / findings / recommendations)
 * so the client can render them without defensive checks. Drops entries with no
 * title rather than showing an empty card.
 */
function normalizeHealthReport(recommendations) {
  if (!recommendations || typeof recommendations !== 'object') return recommendations;

  const str = (v) => (typeof v === 'string' ? v.trim() : '');

  // Score: keep AI value when usable, otherwise derive from status so the ring
  // always has something to draw.
  let score = Number(recommendations.health_score);
  if (!Number.isFinite(score)) {
    const status = str(recommendations.plant_assistant?.status).toLowerCase();
    score = status === 'issue_detected' ? 60 : status === 'healthy' ? 90 : NaN;
  }
  recommendations.health_score = Number.isFinite(score)
    ? Math.max(0, Math.min(100, Math.round(score)))
    : null;

  const rawFindings = Array.isArray(recommendations.findings) ? recommendations.findings : [];
  recommendations.findings = rawFindings
    .map((f) => {
      const category = str(f?.category).toLowerCase();
      return {
        category: FINDING_CATEGORIES.includes(category) ? category : 'leaves',
        title: str(f?.title),
        text: str(f?.text),
      };
    })
    .filter((f) => f.title)
    .slice(0, MAX_FINDINGS);

  const rawRecs = Array.isArray(recommendations.recommendations)
    ? recommendations.recommendations
    : [];
  recommendations.recommendations = rawRecs
    .map((r, idx) => {
      const priority = Number(r?.priority);
      return {
        priority: Number.isFinite(priority) ? Math.max(1, Math.min(3, Math.round(priority))) : idx + 1,
        title: str(r?.title),
        explanation: str(r?.explanation),
        action_label: str(r?.action_label),
        done: false,
      };
    })
    .filter((r) => r.title)
    .sort((a, b) => a.priority - b.priority)
    .slice(0, MAX_HEALTH_RECOMMENDATIONS);

  return recommendations;
}

function resolveLanguageName(code) {
  const map = {
    de: 'German',
    es: 'Spanish',
    fr: 'French',
    ru: 'Russian',
    uk: 'Ukrainian',
  };
  return map[code] || 'English';
}

function buildHealthCheckAgentPrompt(context, plantNameHint, language) {
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
    "moisture_check_tip": "practical tip for THIS plant on how to check soil moisture (e.g. finger test depth, expected feel, plant-specific cues)",
    "water": "specific water recommendations", "light": "4-6 hours", "temperature": "range", "fertilizer": "schedule",
    "soil": "soil type", "growth_rate": "growth info", "toxicity": "safety", "placement": "placement", "personality": "traits",
    "details": {
      "watering_season": "active growth season, e.g. spring-summer",
      "light_hours": "daily hours as digits, e.g. 4-6",
      "light_type": "e.g. bright indirect",
      "temperature_optimal": "e.g. 18-26 °C",
      "temperature_minimum": "lowest tolerated, e.g. 10-12 °C",
      "fertilizer_frequency": "e.g. every 2 weeks",
      "fertilizer_dose": "e.g. half strength",
      "soil_short": "soil in 3-4 words",
      "temperature_short": "temperature in 3-4 words",
      "fertilizer_short": "feeding in 3-4 words",
      "placement_short": "placement in 3-4 words"
    }
  },
  "other_care": { "growth_stage": "Seedling/Young/Mature/Established" },
  "interesting_facts": ["fact 1", "fact 2", "fact 3", "fact 4"],
  "specific_issues": ["risk 1", "risk 2", "risk 3 max"],
  "health_assessment": "current health assessment text",
  "health_score": 0,
  "findings": [ { "category": "light|water|soil|leaves|pests", "title": "string", "text": "string" } ],
  "recommendations": [ { "priority": 1, "title": "string", "explanation": "string", "action_label": "string" } ],
  "plant_assistant": {
    "status": "healthy or issue_detected", "praise_phrase": "string", "health_summary": "string",
    "maintenance_footer": "string", "problem_name": "string", "problem_description": "string",
    "severity": "mild or moderate or serious", "action_steps": ["step"], "follow_up_days": 5, "reassurance": "string"
  }
}

Rules:
- health_score is an integer 0-100 summarising overall condition from the CURRENT image:
  90-100 thriving, 75-89 healthy with minor notes, 55-74 needs attention, 30-54 struggling, 0-29 critical.
  It must agree with plant_assistant.status: status="healthy" implies >= 75, "issue_detected" implies < 75.
- findings: 2-3 items, each a specific observation from the image. "title" is 2-4 words, "text" is one
  sentence. Report positive observations too — a healthy plant still gets findings (e.g. watering on schedule).
- recommendations: 1-3 concrete actions, ordered by importance. "priority" is 1 (most important) to 3.
  "title" is the action in 2-5 words, "explanation" is one sentence on why, "action_label" is the button
  text for adding it to the care plan. A healthy plant gets 1 preventive recommendation.
- Keep watering_plan in whole days (1-60).
- amount_ml must be integer and clamped to 50..2500.
- In care_recommendations.name, return botanical/cultivar identification from analysis (e.g., "Fittonia albivenis"), not the user nickname/plant label from app.
- For watering calculations, explicitly account for POT SIZE (if visible): small pots usually need less amount and shorter intervals; larger pots usually need more amount and longer intervals.
- For watering calculations, explicitly account for SOIL STATE from the current image (soil.visual_state + moisture_current_pct): very_dry/dry can justify earlier watering, moist/wet should delay watering.
- If pot size or soil state is not clearly visible, do not hallucinate; mark uncertainty in reason_short and use conservative safe recommendations.
- Use history to adapt advice (avoid contradicting recent watering events unless visible condition strongly requires it).
- If previous images are provided, mention trend in health_assessment (improving/stable/worsening) when possible.
- Also consider these stabilizing factors when available: days since last watering, recent recommendedAmountMl vs actual amountMl from watering_events, and whether the plant was recently marked healthy/issue_detected.
- care_recommendations.details are compact UI labels, not prose: max 30 characters each, no full sentences, no trailing period. Fill every key; omit one only if the species genuinely has no such requirement.
- details.light_hours is digits and an optional dash only ("4-6"), with no unit word. details.temperature_optimal and details.temperature_minimum must include the °C unit.
- plant_assistant fields by status — REQUIRED, never omit:
  - If status="healthy": praise_phrase (encouraging short phrase), health_summary (1-2 sentence assessment), maintenance_footer (short care reminder). Leave problem_name/problem_description/severity/action_steps/reassurance empty.
  - If status="issue_detected": problem_name, problem_description, severity, action_steps (array), follow_up_days, reassurance. Leave praise_phrase/health_summary/maintenance_footer empty.
- CRITICAL: Write ALL string text fields in ${resolveLanguageName(language)}. Keep ONLY scientific names (species.ai_species_guess) and fixed enum values (soil.visual_state, other_care.growth_stage, findings[].category, plant_assistant.status, plant_assistant.severity) in English.`;
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

      const { base64Image, base64Images, userHint, confirmedSpecies, language } = req.body;

      // Support both single base64Image (legacy) and base64Images[] array
      const imageList = base64Images && Array.isArray(base64Images) && base64Images.length > 0
        ? base64Images
        : (base64Image ? [base64Image] : []);

      if (imageList.length === 0) {
        return res.status(400).json({ error: 'Base64 image is required' });
      }

      const primaryImage = imageList[0];

      console.log('🔍 Starting image analysis');
      console.log('🔍 Photo count:', imageList.length);
      if (userHint) console.log('🔍 User hint:', userHint);
      if (confirmedSpecies) console.log('🔍 Confirmed species:', confirmedSpecies);

      // Build content blocks (multi-image aware)
      function buildImageContentBlocks(promptText, images) {
        const blocks = [{ type: 'text', text: promptText }];
        images.forEach((b64, idx) => {
          if (!b64) return;
          if (images.length > 1) {
            const label = idx === 0 ? 'Photo 1 (whole plant with pot)' : 'Photo 2 (close-up of leaves)';
            blocks.push({ type: 'text', text: label });
          }
          blocks.push({ type: 'image_url', image_url: { url: `data:image/jpeg;base64,${b64}` } });
        });
        return blocks;
      }

      // ── STEP 1: If species is already confirmed, skip identification ──
      if (confirmedSpecies) {
        console.log('🔍 Species confirmed, fetching full recommendations for:', confirmedSpecies);
        const fullPrompt = buildFullAnalysisPrompt(confirmedSpecies, language);

        const response = await openaiClient.chat.completions.create({
          model: ANALYSIS_MODEL,
          messages: [{
            role: 'user',
            content: buildImageContentBlocks(fullPrompt, imageList),
          }],
          [ANALYSIS_TOKEN_PARAM]: 3000,
          temperature: 0.5,
          // Same guard as the health check: a single malformed bracket sends
          // parseAIResponse into its text-scraping fallback, which silently
          // produces a half-empty plant instead of failing loudly.
          response_format: { type: 'json_object' },
        });

        if (response.usage) {
          const db = admin.firestore();
          await saveAiUsage(db, { userId: req.body.userId || null, plantId: req.body.plantId || null, type: 'plant_analysis', model: ANALYSIS_MODEL, usage: response.usage });
        }

        const content = response.choices[0].message.content;
        let recommendations = parseAIResponse(content);
        recommendations = normalizeRecommendations(recommendations, req.body || {});

        return res.json({ success: true, recommendations, rawResponse: content });
      }

      // ── STEP 2: Identify top 3 species candidates ──
      const identifyPrompt = buildSpeciesIdentificationPrompt(userHint, language);

      const idResponse = await openaiClient.chat.completions.create({
        model: ANALYSIS_MODEL,
        messages: [{
          role: 'user',
          content: buildImageContentBlocks(identifyPrompt, imageList),
        }],
        [ANALYSIS_TOKEN_PARAM]: 1000,
        temperature: 0.7,
        response_format: { type: 'json_object' },
      });

      if (idResponse.usage) {
        const db = admin.firestore();
        await saveAiUsage(db, { userId: req.body.userId || null, plantId: req.body.plantId || null, type: 'plant_identification', model: ANALYSIS_MODEL, usage: idResponse.usage });
      }

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

function buildSpeciesIdentificationPrompt(userHint, language) {
  const hintLine = userHint
    ? `The user suggests this might be: "${userHint}". Consider this hint but still rely on your visual analysis.`
    : '';

  const langName = resolveLanguageName(language);
  const langInstruction = langName !== 'English'
    ? `IMPORTANT: Write "common_name" and "visual_hint" in ${langName}. Keep "scientific_name" in Latin (unchanged).`
    : 'Write "common_name" and "visual_hint" in English.';

  return `Analyze this plant photo and identify the TOP 3 most likely species.
${hintLine}

${langInstruction}

Return ONLY valid JSON (no markdown, no explanations):
{
  "top_3_species": [
    {
      "scientific_name": "Genus species",
      "common_name": "Common name in ${langName}",
      "confidence": 0.95,
      "visual_hint": "Brief 1-sentence description of key visual features in ${langName}"
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
- scientific_name must be real botanical names (Genus species format) — always in Latin, never translated
- common_name must be in ${langName}
- visual_hint must be in ${langName} and describe what makes this species look like the photo
- Always return exactly 3 candidates, even if uncertain
- If the photo is unclear, still provide your best guesses with lower confidence`;
}

function buildFullAnalysisPrompt(confirmedSpecies, language) {
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
    "name": "${confirmedSpecies}", "general_description": "...", "moisture": "...",
    "moisture_check_tip": "practical tip for THIS plant on how to check soil moisture (e.g. finger test depth, expected feel, plant-specific cues)",
    "ideal_soil_moisture_min": 10,
    "ideal_soil_moisture_max": 20,
    "water": "...", "light": "...", "temperature": "...", "fertilizer": "...", "soil": "...",
    "growth_rate": "...", "toxicity": "...", "placement": "...", "personality": "...",
    "details": {
      "watering_season": "active growth season, e.g. spring-summer",
      "light_hours": "daily hours as digits, e.g. 4-6",
      "light_type": "e.g. bright indirect",
      "temperature_optimal": "e.g. 18-26 °C",
      "temperature_minimum": "lowest tolerated, e.g. 10-12 °C",
      "fertilizer_frequency": "e.g. every 2 weeks",
      "fertilizer_dose": "e.g. half strength",
      "soil_short": "soil in 3-4 words",
      "temperature_short": "temperature in 3-4 words",
      "fertilizer_short": "feeding in 3-4 words",
      "placement_short": "placement in 3-4 words"
    }
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
care_recommendations.details are compact UI labels, not prose: max 30 characters each, no full sentences, no trailing period. Fill every key; omit one only if the species genuinely has no such requirement. details.light_hours is digits and an optional dash only ("4-6"), with no unit word; details.temperature_optimal and details.temperature_minimum must include the °C unit.
care_recommendations.ideal_soil_moisture_min / ideal_soil_moisture_max: the IDEAL soil moisture percentage range for THIS species based on its botanical needs (0–100). Base this on species biology, NOT on the current visual soil state in the photo. Examples: cactus/succulent → 5–15; drought-tolerant → 15–30; average indoor → 30–50; tropical/moisture-loving → 50–70; bog plant → 70–90. These are integer percentages.

Return ONLY JSON. No text. No markdown.
CRITICAL: Write ALL string text fields in ${resolveLanguageName(language)}. Keep ONLY species scientific name (ai_species_guess) and fixed enum values (soil.visual_state, other_care.growth_stage, plant_assistant.status, plant_assistant.severity) in English.`;
}

exports.analyzeHealthCheckAgent = functions.runWith({ timeoutSeconds: 120, memory: '512MB' }).https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const openaiClient = await initializeOpenAI();
      if (!openaiClient.apiKey) {
        throw new Error('OPENAI_API_KEY is not configured');
      }

      const { base64Image, base64Images, plantId, userId, plantName, language } = req.body || {};

      // Support both single image (legacy) and multi-image array
      const imageList = base64Images && Array.isArray(base64Images) && base64Images.length > 0
        ? base64Images
        : (base64Image ? [base64Image] : []);

      if (imageList.length === 0) {
        return res.status(400).json({ success: false, error: 'At least one base64 image is required' });
      }

      const context = await loadHealthCheckAgentContext(plantId, userId);
      const promptText = buildHealthCheckAgentPrompt(context, plantName, language);
      const currentImageUrl = imageList.map(b64 => `data:image/jpeg;base64,${b64}`);

      const accUsage = { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 };

      // One retry: the result screen needs score + findings + recommendations, and a
      // single sampling at temperature 0.8 drops them often enough to be worth asking
      // again. The retry also widens the historical image tier so the model has more
      // to compare against.
      let content = '';
      let parsed = null;
      let verdict = { ok: false, reason: 'not_attempted' };
      let previousImagesUsed = 0;
      let attemptsUsed = 0;

      for (let attempt = 0; attempt < HEALTH_CHECK_IMAGE_TIERS.length; attempt++) {
        const isRetry = attempt > 0;
        const previousImageUrls = getPreviousImagesForTier(
          context,
          HEALTH_CHECK_IMAGE_TIERS[attempt]
        );
        const contentBlocks = buildHealthCheckContentBlocks(
          promptText,
          currentImageUrl,
          previousImageUrls,
          isRetry
        );

        const response = await openaiClient.chat.completions.create({
          model: ANALYSIS_MODEL,
          messages: [{ role: 'user', content: contentBlocks }],
          [ANALYSIS_TOKEN_PARAM]: 3000,
          temperature: 0.8,
          // Without this the model occasionally closes an array with `}` — the
          // parse then fails, parseAIResponse silently drops to its text-scraping
          // fallback, and the whole structured payload is lost.
          response_format: { type: 'json_object' },
        });

        attemptsUsed = attempt + 1;
        previousImagesUsed = previousImageUrls.length;

        if (response.usage) {
          accUsage.prompt_tokens += response.usage.prompt_tokens || 0;
          accUsage.completion_tokens += response.usage.completion_tokens || 0;
          accUsage.total_tokens += response.usage.total_tokens || 0;
        }

        content = response.choices?.[0]?.message?.content || '';
        parsed = parseAIResponse(content);
        verdict = evaluateHealthCheckAgentResult(parsed, context);
        if (verdict.ok) break;

        console.warn(
          `⚠️ Health check attempt ${attemptsUsed} rejected: ${verdict.reason}` +
            (attempt < HEALTH_CHECK_IMAGE_TIERS.length - 1 ? ' — retrying' : ' — using anyway')
        );
      }

      // Even a rejected result gets normalized and returned: the fallbacks there give
      // the user a usable screen, which beats an error toast after a 30-second wait.
      let recommendations = normalizeRecommendations(parsed, req.body || {});

      if (accUsage.total_tokens > 0) {
        const db = admin.firestore();
        await saveAiUsage(db, { userId, plantId, type: 'health_check', model: ANALYSIS_MODEL, usage: accUsage });
      }

      return res.json({
        success: true,
        recommendations,
        rawResponse: content,
        agent: {
          attemptsUsed,
          previousImagesUsed,
          accepted: verdict.ok,
          rejectedReason: verdict.ok ? null : verdict.reason,
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

// ── Chat image quota helpers ────────────────────────────────────────
const CHAT_IMAGE_DAILY_LIMIT = 2;

function todayUtcString() {
  return new Date().toISOString().slice(0, 10); // "YYYY-MM-DD"
}

async function getChatImageQuota(db, userId, plantId) {
  const ref = db
    .collection('users')
    .doc(userId)
    .collection('chat_quotas')
    .doc(plantId);
  const snap = await ref.get();
  const today = todayUtcString();
  if (!snap.exists) return { usedToday: 0, date: today, ref };
  const data = snap.data();
  if (data.date !== today) return { usedToday: 0, date: today, ref };
  return { usedToday: data.usedToday || 0, date: today, ref };
}

async function incrementChatImageQuota(db, userId, plantId) {
  const { usedToday, date, ref } = await getChatImageQuota(db, userId, plantId);
  await ref.set({ usedToday: usedToday + 1, date, dailyLimit: CHAT_IMAGE_DAILY_LIMIT }, { merge: true });
  return usedToday + 1;
}

// ── Chat image quota read endpoint ──────────────────────────────────
exports.chatImageQuota = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const { userId, plantId } = req.method === 'GET' ? req.query : (req.body || {});
      if (!userId || !plantId) {
        return res.status(400).json({ success: false, error: 'userId and plantId are required' });
      }
      const db = admin.firestore();
      const { usedToday } = await getChatImageQuota(db, userId, plantId);
      return res.json({
        success: true,
        usedToday,
        dailyLimit: CHAT_IMAGE_DAILY_LIMIT,
        remaining: Math.max(0, CHAT_IMAGE_DAILY_LIMIT - usedToday),
        resetAt: `${todayUtcString()}T24:00:00Z`,
      });
    } catch (error) {
      console.error('❌ chatImageQuota error:', error);
      return res.status(500).json({ success: false, error: error.message });
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
        base64Image, // base64-encoded JPEG sent directly (no Storage upload)
        imageUrl,    // legacy: Storage URL (kept for backwards compat)
      } = req.body || {};

      if (!plantId || !userId || !message) {
        return res.status(400).json({
          success: false,
          error: 'plantId, userId and message are required',
        });
      }

      // Resolve image: prefer base64, fall back to URL
      const hasImage = !!(base64Image || imageUrl);
      const resolvedImageUrl = base64Image
        ? `data:image/jpeg;base64,${base64Image}`
        : (imageUrl || null);

      const db = admin.firestore();

      // ── Image quota check ──────────────────────────────────────────
      let quotaUsed = 0;
      if (hasImage) {
        const quota = await getChatImageQuota(db, userId, plantId);
        if (quota.usedToday >= CHAT_IMAGE_DAILY_LIMIT) {
          return res.status(429).json({
            success: false,
            error: 'daily_image_limit_reached',
            usedToday: quota.usedToday,
            dailyLimit: CHAT_IMAGE_DAILY_LIMIT,
          });
        }
        quotaUsed = await incrementChatImageQuota(db, userId, plantId);
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
            .slice(-20)
            .map((m) => ({
              role: m?.role === 'assistant' ? 'assistant' : 'user',
              content: String(m?.text || '').slice(0, 1500),
            }))
            .filter((m) => m.content.length > 0)
        : [];

      // ── Build user message content (text only, or text + image) ────
      const userMessageContent = resolvedImageUrl
        ? [
            { type: 'text', text: String(message).slice(0, 1500) },
            { type: 'image_url', image_url: { url: resolvedImageUrl, detail: 'high' } },
          ]
        : String(message).slice(0, 1500);

      const messages = [
        { role: 'system', content: systemPrompt },
        ...history,
        { role: 'user', content: userMessageContent },
      ];

      const response = await openaiClient.chat.completions.create({
        model: CHAT_MODEL,
        messages,
        [CHAT_TOKEN_PARAM]: 2000,
        temperature: 0.4,
      });

      if (response.usage) {
        const dbUsage = admin.firestore();
        await saveAiUsage(dbUsage, { userId, plantId, type: 'chat', model: CHAT_MODEL, usage: response.usage });
      }

      const answer = response.choices?.[0]?.message?.content?.trim() ||
        'I could not generate a response right now. Please try again.';

      return res.json({
        success: true,
        answer,
        source: responseSource,
        quotaUsed: hasImage ? quotaUsed : null,
        quotaRemaining: hasImage ? Math.max(0, CHAT_IMAGE_DAILY_LIMIT - quotaUsed) : null,
        sourceDebug: {
          hasContextSignals,
          hasKnowledgeBaseEvidence,
          healthChecksLoaded: (context.recentHealthChecks || []).length,
          wateringEventsLoaded: (context.recentWateringEvents || []).length,
          previousImagesLoaded: (context.recentImageUrls || []).length,
          imageAttached: hasImage,
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
      }, { userId, plantId });

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
  const title = truncateForFcmNotification(emailCopy.subject, 100);
  const body = truncateForFcmNotification(emailCopy.text, 240);
  for (let i = 0; i < tokens.length; i += FCM_WATERING_MULTICAST_MAX) {
    const chunk = tokens.slice(i, i + FCM_WATERING_MULTICAST_MAX);
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
      const response = await admin.messaging().sendMulticast(message);
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
  if (successTotal > 0) {
    try {
      await db.collection('push_notifications').add({
        userId,
        plantId: plantId || null,
        plantName: plantName || null,
        title,
        body,
        stage: stage || null,
        successCount: successTotal,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console.warn('⚠️ push_notifications log failed:', e.message);
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
      const response = await admin.messaging().sendMulticast(message);
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
  if (careRec.soil) careTipsLines.push(`Soil: ${careRec.soil}`);
  if (careRec.moisture) careTipsLines.push(`Moisture: ${careRec.moisture}`);
  if (careRec.moisture_check_tip) careTipsLines.push(`Moisture Check: ${careRec.moisture_check_tip}`);
  if (careRec.water) careTipsLines.push(`Water: ${careRec.water}`);
  if (careRec.light) careTipsLines.push(`Light: ${careRec.light}`);
  if (careRec.temperature) careTipsLines.push(`Temperature: ${careRec.temperature}`);
  if (careRec.fertilizer) careTipsLines.push(`Fertilizer: ${careRec.fertilizer}`);
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
    // Ideal soil moisture range from AI
    ideal_soil_moisture_min: careRec.ideal_soil_moisture_min ?? null,
    ideal_soil_moisture_max: careRec.ideal_soil_moisture_max ?? null,
    // Pass the full structured object so the client can build
    // localized section titles in the user's language.
    care_recommendations: careRec,
    // Health-report fields. This transform rebuilds the payload field by field,
    // so anything not listed here is dropped before the client ever sees it.
    health_score: jsonData.health_score ?? null,
    findings: Array.isArray(jsonData.findings) ? jsonData.findings : [],
    recommendations: Array.isArray(jsonData.recommendations) ? jsonData.recommendations : [],
    // The result validator reads soil state to spot "water now" advice that
    // contradicts a recent watering; without it that guard silently no-ops.
    soil,
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

      const emailPayload = {
        stage,
        locale,
        plantName,
        cultivar,
        userName: userInfo.name || null,
        minutesToDue,
        minutesOverdue,
        recommendedAmountMl: data.wateringAmountMl || null,
      };

      // AI for first 4 days (slots 0-7); fallback for days 4-9.
      // Push-only users also get AI-generated text for the first 4 days.
      const shouldUseAI = (canTryEmail || canTryPush) && remindersSentCount < 8;
      const emailCopy = shouldUseAI
        ? await generateWateringEmailWithAI(emailPayload, { userId: uid, plantId: doc.id })
        : buildWateringEmailFallback(emailPayload);

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

// ═══════════════════════════════════════════════════════════════════
//  generateSeasonalTips — weekly cron + manual HTTP trigger
// ═══════════════════════════════════════════════════════════════════

function getISOWeek(date) {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
}

function getWeekKey(date) {
  const w = getISOWeek(date);
  return `${date.getFullYear()}-W${String(w).padStart(2, '0')}`;
}

function getWeekStart(date) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  d.setDate(diff);
  return d.toISOString().split('T')[0];
}

function getSeason(date) {
  const m = date.getMonth();
  if (m >= 2 && m <= 4) return 'spring';
  if (m >= 5 && m <= 7) return 'summer';
  if (m >= 8 && m <= 10) return 'autumn';
  return 'winter';
}

const TIPS_MODEL = 'gpt-5.1';
const TIPS_TOKEN_PARAM = TIPS_MODEL.startsWith('gpt-5') ? 'max_completion_tokens' : 'max_tokens';

async function doGenerateSeasonalTips() {
  const db = admin.firestore();
  const now = new Date();
  const weekKey = getWeekKey(now);
  const season = getSeason(now);
  const monthName = now.toLocaleString('en-US', { month: 'long' });

  const openaiClient = await initializeOpenAI();

  const prompt = `You are a plant care expert. Generate 21 seasonal plant care tips for home gardeners.

Context:
- Current season: ${season}
- Current month: ${monthName}
- Year: ${now.getFullYear()}

Requirements:
- 21 unique tips, each 1-2 sentences
- Mix of: watering advice, light/positioning, pest prevention, fertilizing, seasonal tasks, fun facts
- Relevant to the current season and month
- Practical, actionable, friendly tone
- Each tip must be translated into 4 languages

Return a JSON array of exactly 21 objects:
[
  {
    "index": 0,
    "en": "English tip text",
    "de": "German tip text",
    "es": "Spanish tip text",
    "fr": "French tip text",
    "category": "watering|light|pests|fertilizing|seasonal|general"
  },
  ...
]

Return ONLY the JSON array, no markdown fences, no explanation.`;

  const response = await openaiClient.chat.completions.create({
    model: TIPS_MODEL,
    messages: [
      { role: 'system', content: 'You are a helpful plant care assistant. Always respond with valid JSON.' },
      { role: 'user', content: prompt },
    ],
    [TIPS_TOKEN_PARAM]: 6000,
    temperature: 0.7,
  });

  const raw = response.choices?.[0]?.message?.content?.trim() || '[]';
  let tips;
  try {
    const cleaned = raw.replace(/^```json?\s*/i, '').replace(/```\s*$/, '').trim();
    tips = JSON.parse(cleaned);
  } catch (e) {
    console.error('❌ generateSeasonalTips: Failed to parse AI response:', e.message);
    throw new Error('Failed to parse tips JSON from AI');
  }

  if (!Array.isArray(tips) || tips.length < 21) {
    throw new Error(`Expected 21 tips, got ${Array.isArray(tips) ? tips.length : 0}`);
  }

  const usage = response.usage || {};
  const inputTokens = usage.prompt_tokens || 0;
  const outputTokens = usage.completion_tokens || 0;
  const totalTokens = usage.total_tokens || (inputTokens + outputTokens);
  const costUsd = calcAiCost(TIPS_MODEL, inputTokens, outputTokens);

  await db.collection('seasonal_tips').doc(weekKey).set({
    weekKey,
    weekStart: getWeekStart(now),
    season,
    month: monthName,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    model: TIPS_MODEL,
    usage: { prompt_tokens: inputTokens, completion_tokens: outputTokens, total_tokens: totalTokens },
    estimatedCostUsd: costUsd,
    tips: tips.slice(0, 21).map((t, i) => ({
      index: i,
      en: t.en || '',
      de: t.de || '',
      es: t.es || '',
      fr: t.fr || '',
      category: t.category || 'general',
    })),
  });

  await saveAiUsage(db, {
    userId: 'system',
    plantId: null,
    type: 'seasonal_tips',
    model: TIPS_MODEL,
    usage,
  });

  console.log(`✅ generateSeasonalTips: ${weekKey} — ${tips.length} tips, ${totalTokens} tokens, $${costUsd?.toFixed(4) || '?'}`);
  return { weekKey, tipsCount: tips.length, totalTokens, costUsd };
}

// Scheduled: every Sunday at 23:00 UTC
exports.generateSeasonalTipsCron = functions.pubsub
  .schedule('0 23 * * 0')
  .timeZone('UTC')
  .onRun(async () => {
    await doGenerateSeasonalTips();
    return null;
  });

// Manual HTTP trigger (for admin / testing)
exports.generateSeasonalTips = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ success: false, error: 'POST only' });
      }
      const result = await doGenerateSeasonalTips();
      return res.json({ success: true, ...result });
    } catch (error) {
      console.error('❌ generateSeasonalTips error:', error);
      return res.status(500).json({ success: false, error: error.message });
    }
  });
});

// ── Stripe ──────────────────────────────────────────────────────────────────

const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY || '';
const STRIPE_PRICE_MONTHLY = process.env.STRIPE_PRICE_MONTHLY || 'price_1TUtsuBxYoTdS5idFawLwpPs';
const STRIPE_PRICE_ANNUAL = process.env.STRIPE_PRICE_ANNUAL || 'price_1TUtumBxYoTdS5idOLeprsVn';

/**
 * Creates a Stripe Checkout session for web subscriptions.
 * Called from Flutter web via Firebase callable function.
 */
exports.createStripeCheckout = functions.https.onCall(async (data, context) => {
  const stripe = require('stripe')(STRIPE_SECRET_KEY);

  const priceId = data.priceId;
  const successUrl = data.successUrl || 'https://botanly.app/?stripe_success=1';
  const cancelUrl = data.cancelUrl || 'https://botanly.app/?stripe_cancel=1';
  const uid = context.auth?.uid || data.uid;

  if (!priceId) {
    throw new functions.https.HttpsError('invalid-argument', 'priceId is required');
  }
  if (priceId !== STRIPE_PRICE_MONTHLY && priceId !== STRIPE_PRICE_ANNUAL) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid priceId');
  }

  const sessionParams = {
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    mode: 'subscription',
    success_url: successUrl,
    cancel_url: cancelUrl,
  };

  if (uid) {
    sessionParams.metadata = { firebaseUid: uid };
    sessionParams.subscription_data = { metadata: { firebaseUid: uid } };
    // Try to find or create Stripe customer linked to Firebase UID
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(uid).get();
    const stripeCustomerId = userDoc.exists ? userDoc.data().stripeCustomerId : null;
    if (stripeCustomerId) {
      sessionParams.customer = stripeCustomerId;
    }
  }

  const session = await stripe.checkout.sessions.create(sessionParams);

  // Save session ID to Firestore for tracking
  if (uid) {
    await admin.firestore().collection('users').doc(uid).set(
      { stripeCheckoutSessionId: session.id },
      { merge: true }
    );
  }

  console.log(`✅ Stripe checkout session created: ${session.id} for uid=${uid}`);
  return { url: session.url, sessionId: session.id };
});

/**
 * Creates a Stripe Billing Portal session so web users can manage their
 * subscription (cancel, update payment method, view invoices).
 * Requires the user to have a stripeCustomerId saved in Firestore.
 */
exports.createPortalSession = functions.https.onCall(async (data, context) => {
  const stripe = require('stripe')(STRIPE_SECRET_KEY);
  const db = admin.firestore();

  const uid = context.auth?.uid || data.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'User not found');
  }

  const stripeCustomerId = userDoc.data().stripeCustomerId;
  if (!stripeCustomerId) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'No Stripe customer found. Please subscribe first.'
    );
  }

  const returnUrl = data.returnUrl || 'https://botanly.app/home';

  const session = await stripe.billingPortal.sessions.create({
    customer: stripeCustomerId,
    return_url: returnUrl,
  });

  console.log(`✅ Stripe portal session created for uid=${uid}`);
  return { url: session.url };
});

/**
 * Stripe webhook handler — updates Firestore subscription status.
 * Configure in Stripe Dashboard: https://dashboard.stripe.com/webhooks
 * Events to enable: checkout.session.completed, customer.subscription.updated,
 *                   customer.subscription.deleted
 */
exports.onStripeWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

  const stripe = require('stripe')(STRIPE_SECRET_KEY);
  const db = admin.firestore();

  // Verify webhook signature
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  let event = req.body;

  if (webhookSecret) {
    const sig = req.headers['stripe-signature'];
    try {
      event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
    } catch (err) {
      console.error('❌ Stripe webhook signature verification failed:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }
  }

  const eventType = event.type;
  console.log(`📩 Stripe webhook: ${eventType}`);

  try {
    if (eventType === 'checkout.session.completed') {
      const session = event.data.object;
      const uid = session.metadata?.firebaseUid;
      const customerId = session.customer;
      const subscriptionId = session.subscription;

      if (uid) {
        const update = {
          subscriptionStatus: 'active',
          stripeCustomerId: customerId || null,
          stripeSubscriptionId: subscriptionId || null,
          subscriptionExpiresAt: null,
          autoRenewEnabled: true,
        };

        // Fetch subscription to get period end
        if (subscriptionId) {
          const subscription = await stripe.subscriptions.retrieve(subscriptionId);
          const periodEndRaw = subscription.current_period_end
            || subscription.items?.data?.[0]?.current_period_end
            || subscription.billing_cycle_anchor;
          if (periodEndRaw && typeof periodEndRaw === 'number') {
            const periodEnd = new Date(periodEndRaw * 1000);
            if (!isNaN(periodEnd.getTime())) {
              update.subscriptionExpiresAt = admin.firestore.Timestamp.fromDate(periodEnd);
            }
          }
        }

        await db.collection('users').doc(uid).set(update, { merge: true });
        console.log(`✅ Stripe: activated subscription for uid=${uid}`);
      }
    } else if (eventType === 'customer.subscription.updated') {
      const subscription = event.data.object;
      const previousAttributes = event.data.previous_attributes || {};
      const uid = subscription.metadata?.firebaseUid;

      if (!uid) {
        // Try to find user by stripeCustomerId
        const snap = await db.collection('users')
          .where('stripeCustomerId', '==', subscription.customer)
          .limit(1).get();
        if (!snap.empty) {
          const userUid = snap.docs[0].id;
          await _updateStripeSubscription(db, userUid, subscription, previousAttributes);
        }
      } else {
        await _updateStripeSubscription(db, uid, subscription, previousAttributes);
      }
    } else if (eventType === 'customer.subscription.deleted') {
      const subscription = event.data.object;
      const uid = subscription.metadata?.firebaseUid;

      let userUid = uid;
      if (!userUid) {
        const snap = await db.collection('users')
          .where('stripeCustomerId', '==', subscription.customer)
          .limit(1).get();
        if (!snap.empty) userUid = snap.docs[0].id;
      }

      if (userUid) {
        await db.collection('users').doc(userUid).set(
          { subscriptionStatus: 'expired' },
          { merge: true }
        );
        console.log(`✅ Stripe: expired subscription for uid=${userUid}`);
      }
    }

    return res.status(200).json({ received: true });
  } catch (error) {
    console.error('❌ Stripe webhook processing error:', error);
    return res.status(500).json({ error: error.message });
  }
});

async function _updateStripeSubscription(db, uid, subscription, previousAttributes = {}) {
  const status = subscription.status;
  const periodEndRaw = subscription.current_period_end
    || subscription.items?.data?.[0]?.current_period_end
    || subscription.billing_cycle_anchor;
  const periodEnd = periodEndRaw ? new Date(periodEndRaw * 1000) : null;

  let subscriptionStatus;
  if (status === 'active' || status === 'trialing') {
    subscriptionStatus = 'active';
  } else if (status === 'canceled' || status === 'unpaid' || status === 'incomplete_expired') {
    subscriptionStatus = 'expired';
  } else {
    subscriptionStatus = 'active'; // past_due, incomplete — keep active for grace period
  }

  const updateData = {
    subscriptionStatus,
    stripeSubscriptionId: subscription.id,
  };

  // Subscription is cancelled when cancel_at_period_end=true OR cancel_at is set to a future date.
  // Stripe Customer Portal uses cancel_at (specific date) rather than cancel_at_period_end.
  const isCancelled = subscription.cancel_at_period_end === true || subscription.cancel_at !== null;
  updateData.autoRenewEnabled = !isCancelled;

  if (periodEnd && !isNaN(periodEnd.getTime())) {
    updateData.subscriptionExpiresAt = admin.firestore.Timestamp.fromDate(periodEnd);
  }

  await db.collection('users').doc(uid).set(updateData, { merge: true });

  console.log(`✅ Stripe: updated subscription for uid=${uid}, status=${subscriptionStatus}`);
}

// ═══════════════════════════════════════════════════════════════════
//  RevenueCat Webhook — subscription lifecycle events
// ═══════════════════════════════════════════════════════════════════

/**
 * Maps RevenueCat event types to internal subscription statuses.
 * Called by RevenueCat when a subscription event occurs.
 * Set Webhook URL in RevenueCat dashboard → Integrations → Webhooks.
 * Authorization header must match REVENUECAT_WEBHOOK_SECRET env var.
 */
exports.onRevenueCatWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method not allowed');
  }

  // Verify shared secret
  const secret = process.env.REVENUECAT_WEBHOOK_SECRET;
  if (secret) {
    const authHeader = req.headers['authorization'] || '';
    if (authHeader !== secret) {
      console.warn('⚠️ RevenueCat webhook: invalid authorization header');
      return res.status(401).send('Unauthorized');
    }
  }

  const event = req.body?.event;
  if (!event) {
    return res.status(400).send('Missing event');
  }

  const {
    type,
    app_user_id: appUserId,
    expiration_at_ms: expirationAtMs,
    original_transaction_id: originalTransactionId,
  } = event;

  if (!appUserId) {
    return res.status(400).send('Missing app_user_id');
  }

  const db = admin.firestore();

  // Find user by revenueCatAppUserId field (set when SDK initializes)
  const usersSnap = await db
    .collection('users')
    .where('revenueCatAppUserId', '==', appUserId)
    .limit(1)
    .get();

  // Fall back to treating appUserId as Firebase UID
  let userRef;
  if (!usersSnap.empty) {
    userRef = usersSnap.docs[0].ref;
  } else {
    const directDoc = await db.collection('users').doc(appUserId).get();
    if (directDoc.exists) {
      userRef = directDoc.ref;
    } else {
      console.warn(`⚠️ RevenueCat webhook: no user found for app_user_id=${appUserId}`);
      return res.status(200).send('User not found — ignored');
    }
  }

  const expiresAt = expirationAtMs
    ? admin.firestore.Timestamp.fromMillis(expirationAtMs)
    : null;

  let update = {};

  switch (type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'UNCANCELLATION':
      update = {
        subscriptionStatus: 'active',
        subscriptionExpiresAt: expiresAt,
        autoRenewEnabled: true,
        originalTransactionId: originalTransactionId || null,
      };
      break;

    case 'CANCELLATION':
      // Cancelled but still active until expiry — auto-renew is now off
      update = {
        subscriptionStatus: 'active',
        subscriptionExpiresAt: expiresAt,
        autoRenewEnabled: false,
      };
      break;

    case 'EXPIRATION':
      update = {
        subscriptionStatus: 'expired',
        subscriptionExpiresAt: expiresAt,
      };
      break;

    case 'BILLING_ISSUE':
      // Keep active status but note expiry approaching
      update = {
        subscriptionExpiresAt: expiresAt,
      };
      break;

    default:
      console.log(`ℹ️ RevenueCat webhook: unhandled event type=${type}`);
      return res.status(200).send('Event type not handled');
  }

  await userRef.update(update);
  console.log(`✅ RevenueCat webhook: type=${type} appUserId=${appUserId} status=${update.subscriptionStatus || '(unchanged)'}`);
  return res.status(200).send('OK');
});

// ── Delete Account ────────────────────────────────────────────────────────────
// Disables the Firebase Auth account (blocks login) and marks the Firestore
// user document as deleted. Plant data is intentionally preserved.
exports.deleteAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in.');
  }

  const uid = context.auth.uid;
  const db = admin.firestore();

  try {
    // Mark user document as deleted (keep all data for analytics)
    await db.collection('users').doc(uid).update({
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'deleted',
    });

    // Revoke all active sessions first
    await admin.auth().revokeRefreshTokens(uid);

    // Disable the Firebase Auth account so the user cannot log back in
    await admin.auth().updateUser(uid, { disabled: true });

    console.log(`✅ deleteAccount: uid=${uid} disabled and marked deleted`);
    return { success: true };
  } catch (e) {
    console.error(`❌ deleteAccount error for uid=${uid}:`, e);
    throw new functions.https.HttpsError('internal', 'Failed to delete account.');
  }
});

// ── Email Verification PIN (Registration) ─────────────────────────────────────
// IS_DEV=true  → skip email sending, accept '111111' as bypass (dev/test only)
// IS_DEV=false → real email sending, no bypass (production)

const EMAIL_VERIFICATION_TTL_MS = 15 * 60 * 1000; // 15 minutes

exports.sendEmailVerificationPin = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).json({ success: false, error: 'Method not allowed' });
      }

      const email = normalizeEmail(req.body?.email);
      if (!isValidEmail(email)) {
        return res.status(400).json({ success: false, error: 'Please enter a valid email.' });
      }

      // Check if email is already registered
      try {
        await admin.auth().getUserByEmail(email);
        return res.status(409).json({ success: false, error: 'An account with this email already exists.' });
      } catch (e) {
        if (!e || e.code !== 'auth/user-not-found') throw e;
        // user-not-found is expected — email is available
      }

      const db = admin.firestore();
      const nowMs = Date.now();
      const expiresAtMs = nowMs + EMAIL_VERIFICATION_TTL_MS;
      const pin = String(crypto.randomInt(100000, 1000000));
      const salt = crypto.randomBytes(16).toString('hex');
      const pinHash = hashPin(pin, salt);

      await db.collection('email_verification_pins').doc(email).set({
        emailLower: email,
        pinHash,
        salt,
        attempts: 0,
        createdAtMs: nowMs,
        expiresAtMs,
        expiresAt: admin.firestore.Timestamp.fromMillis(expiresAtMs),
      });

      if (process.env.IS_DEV === 'true') {
        console.log(`[DEV] Email verification PIN for ${email}: ${pin} (use 111111 to bypass)`);
      } else {
        await admin.firestore().collection('mail').add({
          to: email,
          message: {
            subject: 'Your Botanly verification code',
            text: `Your verification code is: ${pin}\n\nThis code expires in 15 minutes.`,
            html: `
              <h2>Verify your email</h2>
              <p>Use this code to complete your registration:</p>
              <p style="font-size:32px;font-weight:700;letter-spacing:6px;">${pin}</p>
              <p>This code expires in 15 minutes.</p>
              <p>If you didn't request this, please ignore this email.</p>
            `.trim(),
          },
        });
      }

      return res.json({ success: true, message: 'Verification code sent.' });
    } catch (error) {
      console.error('sendEmailVerificationPin error:', error);
      return res.status(500).json({ success: false, error: 'Could not send verification code.' });
    }
  });
});

exports.verifyEmailPin = functions.https.onRequest((req, res) => {
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

      if (process.env.IS_DEV === 'true' && pin === '111111') {
        return res.json({ success: true, verified: true });
      }

      const db = admin.firestore();
      const docRef = db.collection('email_verification_pins').doc(email);
      const snap = await docRef.get();

      if (!snap.exists) {
        return res.status(404).json({ success: false, error: 'No verification code found. Please request a new one.' });
      }

      const data = snap.data();
      const nowMs = Date.now();

      if (nowMs > data.expiresAtMs) {
        await docRef.delete();
        return res.status(410).json({ success: false, error: 'Verification code has expired. Please request a new one.' });
      }

      if (data.attempts >= 5) {
        return res.status(429).json({ success: false, error: 'Too many attempts. Please request a new code.' });
      }

      const hash = hashPin(pin, data.salt);
      if (hash !== data.pinHash) {
        await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
        return res.status(400).json({ success: false, error: 'Incorrect code. Please try again.' });
      }

      // Valid — delete the pin record
      await docRef.delete();
      return res.json({ success: true, verified: true });
    } catch (error) {
      console.error('verifyEmailPin error:', error);
      return res.status(500).json({ success: false, error: 'Could not verify code.' });
    }
  });
});

// ═══════════════════════════════════════════════════════════════════
//  aggregateAiUsageDaily — runs daily at 00:05 UTC
//  Aggregates ai_usage records for the previous day into ai_usage_daily/{date}
// ═══════════════════════════════════════════════════════════════════
exports.aggregateAiUsageDaily = functions.pubsub
  .schedule('5 0 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();

    const yesterday = new Date(now);
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    const dateKey = yesterday.toISOString().slice(0, 10);

    const startOfDay = admin.firestore.Timestamp.fromDate(new Date(`${dateKey}T00:00:00.000Z`));
    const endOfDay = admin.firestore.Timestamp.fromDate(new Date(`${dateKey}T23:59:59.999Z`));

    const snap = await db.collection('ai_usage')
      .where('timestamp', '>=', startOfDay)
      .where('timestamp', '<=', endOfDay)
      .get();

    let totalCalls = 0;
    let totalCostUsd = 0;
    let totalTokens = 0;
    const byType = {};
    const byUser = {};

    for (const docSnap of snap.docs) {
      const data = docSnap.data();
      totalCalls += 1;
      totalCostUsd += data.costUsd ?? 0;
      totalTokens += data.totalTokens ?? 0;

      const type = data.type || 'unknown';
      if (!byType[type]) byType[type] = { calls: 0, cost: 0, tokens: 0 };
      byType[type].calls += 1;
      byType[type].cost += data.costUsd ?? 0;
      byType[type].tokens += data.totalTokens ?? 0;

      const uid = data.userId;
      if (uid && uid !== 'system') {
        if (!byUser[uid]) byUser[uid] = { calls: 0, cost: 0 };
        byUser[uid].calls += 1;
        byUser[uid].cost += data.costUsd ?? 0;
      }
    }

    await db.collection('ai_usage_daily').doc(dateKey).set({
      date: dateKey,
      totalCalls,
      totalCostUsd,
      totalTokens,
      byType,
      byUser,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ aggregateAiUsageDaily: ${dateKey} → calls=${totalCalls} cost=$${totalCostUsd.toFixed(4)}`);
    return null;
  });

// ═══════════════════════════════════════════════════════════════════
//  getAiStats — HTTP endpoint for agent/external access
// ═══════════════════════════════════════════════════════════════════
exports.getAiStats = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const token = req.headers['x-admin-token'] || req.query.token;
      const expectedToken = process.env.ADMIN_STATS_TOKEN;

      if (!expectedToken || token !== expectedToken) {
        return res.status(401).json({ error: 'Unauthorized. Set x-admin-token header.' });
      }

      const db = admin.firestore();
      const days = Math.min(90, Math.max(1, parseInt(req.query.days) || 30));

      const cutoff = new Date();
      cutoff.setDate(cutoff.getDate() - days + 1);
      const cutoffStr = cutoff.toISOString().slice(0, 10);

      const dailySnap = await db.collection('ai_usage_daily')
        .where('date', '>=', cutoffStr)
        .orderBy('date', 'asc')
        .get();

      const daily = dailySnap.docs.map((d) => {
        const data = d.data();
        return {
          date: d.id,
          calls: data.totalCalls ?? 0,
          cost: parseFloat((data.totalCostUsd ?? 0).toFixed(4)),
          tokens: data.totalTokens ?? 0,
          byType: data.byType ?? {},
        };
      });

      const periodCost = daily.reduce((s, d) => s + d.cost, 0);
      const periodCalls = daily.reduce((s, d) => s + d.calls, 0);

      return res.json({
        ok: true,
        period: `last ${days} days`,
        periodCostUsd: parseFloat(periodCost.toFixed(4)),
        periodCalls,
        daily,
        generatedAt: new Date().toISOString(),
      });
    } catch (e) {
      console.error('getAiStats error:', e.message);
      return res.status(500).json({ error: e.message });
    }
  });
});

// ── Care task scheduler ─────────────────────────────────────────────────────
//
// Tasks are not generated daily. Each source has its own rhythm (SPEC v3 1.3),
// and — crucially — nothing new is created for a plant while that plant still
// has open tasks. Without that rule a neglected plant accumulates a backlog the
// user can never clear, which is exactly what the "Сегодня" group is meant to
// prevent.

const TASK_FERTILIZE_EVERY_DAYS = 14;
const TASK_RESCAN_EVERY_DAYS = 30;

/** Стакан как база пересчёта дозы — та же, что на экране растения. */
const GLASS_ML = 200;

/** Календарные сутки между двумя моментами. */
function daysBetween(from, to) {
  const a = Date.UTC(from.getFullYear(), from.getMonth(), from.getDate());
  const b = Date.UTC(to.getFullYear(), to.getMonth(), to.getDate());
  return Math.floor((b - a) / 86400000);
}

/**
 * Builds the task documents a plant is due for. Pure apart from `now` so the
 * rules stay testable.
 *
 * `openCategories` holds the categories of the plant's open **scheduled** tasks.
 * SPEC 1.3.3 held everything back while any task was open; that is now
 * per-category, because watering pairs with a health check and a health check
 * people skip must never stop the watering reminder.
 */
function plannedTasksFor(plant, openCategories, now, locale = 'en') {
  const t = taskStrings(locale);
  const out = [];
  const lastFertilised = toDateSafe(plant.lastFertilisedAt);
  const lastScan = toDateSafe(plant.lastHealthCheck);
  const lastScanTask = toDateSafe(plant.lastScanTaskAt);
  const cycleStart = toDateSafe(plant.lastWateredAt) || toDateSafe(plant.lastWatered);

  // Watering is a task on the home deck (SPEC 1.3) even though the plant screen
  // shows it as its hero widget — "no duplicates" applies to the plant's own
  // "what to do" block, which filters watering out client-side.
  const wateringDue = toDateSafe(plant.nextDueAt) || toDateSafe(plant.nextWatering);
  // The client also treats a sticky `shouldWaterNow` from the analyser as "due"
  // (`_canWaterPlant`). Without it the screen locks the health check while the
  // scheduler issues nothing at all.
  const wateringDueNow =
    (wateringDue && wateringDue <= now) || plant.shouldWaterNow === true;

  if (wateringDueNow && !openCategories.has('water')) {
    const ml = Number(plant.wateringAmountMl);
    const interval = Number(plant.wateringIntervalDays || plant.wateringFrequency);
    const kv = [];
    if (Number.isFinite(ml) && ml > 0) {
      kv.push({ k: t.kvVolume, v: `${Math.round(ml)} ${t.unitMl}` });
      kv.push({
        k: t.kvThisIs,
        v: `${(ml / GLASS_ML).toFixed(1).replace('.0', '')} ${t.unitGlasses}`,
      });
    }
    if (Number.isFinite(interval) && interval > 0) {
      kv.push({ k: t.kvCycle, v: t.valEveryNDays(interval) });
    }
    out.push({
      title: t.waterTitle,
      detail:
        Number.isFinite(ml) && ml > 0
          ? t.waterDetail(Math.round(ml))
          : t.waterDetailPlain,
      category: 'water',
      // Numbers travel next to the text so a client can rebuild the whole card
      // in its own language when the user switches the interface.
      params: {
        ml: Number.isFinite(ml) && ml > 0 ? Math.round(ml) : null,
        intervalDays: Number.isFinite(interval) && interval > 0 ? interval : null,
      },
      // The real due date, not "now": a watering three days late has to read as
      // three days late, both in the sort order and in the plant's score.
      dueAt: wateringDue.toISOString(),
      kv,
      body: t.waterBody,
    });
  }

  const needsFertiliser =
    !lastFertilised || daysBetween(lastFertilised, now) >= TASK_FERTILIZE_EVERY_DAYS;
  if (needsFertiliser && !openCategories.has('fertilizer')) {
    out.push({
      title: t.fertTitle,
      detail: t.fertDetail,
      category: 'fertilizer',
      params: {},
      kv: [
        { k: t.kvRhythm, v: t.valFortnightly },
        { k: t.kvDose, v: t.valHalfDose },
      ],
      body: t.fertBody,
    });
  }

  // The health check rides along with watering: it goes out on the watering day
  // whether or not the plant has been watered yet, so the user can water, tap
  // "I have watered" (which unlocks the check) and then run it from the task.
  //
  // Both watermarks are anchored on the watering cycle, not on `now`. Anchoring
  // on `now` would re-issue the task every six hours for as long as the plant
  // stays thirsty — once after every completed check, forever. `lastScanTaskAt`
  // is written when the task is created, so the rule holds no matter *how* the
  // task was closed.
  const scannedThisCycle =
    lastScan && cycleStart && lastScan > cycleStart;
  const issuedThisCycle =
    lastScanTask && cycleStart && lastScanTask > cycleStart;

  const needsRescan =
    !scannedThisCycle &&
    !issuedThisCycle &&
    !openCategories.has('scan') &&
    // Two triggers, one watermark. Letting the ceiling skip `issuedThisCycle`
    // put a plant with an old check straight back into the six-hourly loop the
    // watermark exists to prevent.
    //
    // The ceiling keeps slow-cycle plants honest: a cactus watered every 45 days
    // would otherwise go a month and a half without a look.
    (wateringDueNow ||
      !lastScan ||
      daysBetween(lastScan, now) >= TASK_RESCAN_EVERY_DAYS);

  if (needsRescan) {
    out.push({
      title: t.scanTitle,
      detail: t.scanDetail,
      category: 'scan',
      params: {},
      // Same due date as its watering twin, so the pair ages together and the
      // deck shows them as one cycle rather than two unrelated chores.
      dueAt: wateringDueNow && wateringDue ? wateringDue.toISOString() : undefined,
      kv: [
        { k: t.kvRhythm, v: t.valMonthly },
        { k: t.kvNeeds, v: t.valPhotos },
      ],
      body: t.scanBody,
    });
  }

  return out;
}

// Exported for the unit tests under functions/test.
exports.plannedTasksFor = plannedTasksFor;

exports.scheduleCareTasks = functions.pubsub
  .schedule('every 6 hours')
  .timeZone('Etc/UTC')
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();

    const plantsSnap = await db
      .collection('plants')
      .where('deletedAt', '==', null)
      .limit(500)
      .get();

    let created = 0;
    let skipped = 0;
    /** userId → language code, so each user's document is read once per tick. */
    const localeByUser = new Map();

    for (const doc of plantsSnap.docs) {
      const plant = doc.data() || {};
      if (!plant.userId) continue;

      const openSnap = await db
        .collection('tasks')
        .where('userId', '==', plant.userId)
        .where('plantId', '==', doc.id)
        .where('done', '==', false)
        .get();

      // Only scheduled tasks hold back the rhythm. An analysis recommendation
      // that `_taskCategoryFor` filed under "water" must not silence the
      // watering reminder.
      const openCategories = new Set(
        openSnap.docs
          .map((d) => d.data() || {})
          .filter((t) => t.source === 'schedule')
          .map((t) => t.category)
          .filter(Boolean)
      );

      // One lookup per user, not per plant: a garden of twenty plants would
      // otherwise read the same user document twenty times every tick.
      if (!localeByUser.has(plant.userId)) {
        let code = 'en';
        try {
          const userDoc = await db.collection('users').doc(plant.userId).get();
          const u = userDoc.data() || {};
          code = normaliseLocale(u.locale || u.language);
        } catch (e) {
          console.warn(`⚠️ locale lookup failed for ${plant.userId}: ${e}`);
        }
        localeByUser.set(plant.userId, code);
      }
      const planned = plannedTasksFor(
        plant,
        openCategories,
        now,
        localeByUser.get(plant.userId)
      );
      if (planned.length === 0) {
        skipped++;
        continue;
      }

      const batch = db.batch();
      let issuedScan = false;
      for (const task of planned) {
        if (task.category === 'scan') issuedScan = true;
        const ref = db.collection('tasks').doc();
        batch.set(ref, {
          ...task,
          id: ref.id,
          plantId: doc.id,
          userId: plant.userId,
          source: 'schedule',
          // Most tasks start today; watering carries its own overdue date.
          dueAt: task.dueAt || now.toISOString(),
          postponedAt: null,
          done: false,
          completedAt: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        created++;
      }
      // The watermark that makes the scan rule idempotent: written with the task
      // itself, so a check the user ticked off, skipped or completed properly all
      // look the same to the next tick.
      if (issuedScan) {
        batch.update(doc.ref, { lastScanTaskAt: now.toISOString() });
      }
      await batch.commit();
    }

    console.log(
      `🗓️ scheduleCareTasks: ${created} created, ${skipped} plants already busy ` +
        `(of ${plantsSnap.size})`
    );
    return null;
  });
