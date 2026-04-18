/**
 * Enqueues scheduled_test_pushes for every distinct userId in fcm_tokens (prod).
 * Requires: gcloud auth print-access-token
 *
 * Usage: node scripts/enqueue_scheduled_test_all_users.js [delayMinutes]
 */

const { execSync } = require('child_process');
const https = require('https');
const urlMod = require('url');

const PROJECT = 'plant-care-94574';
const DELAY_MIN = Math.max(
  1,
  Math.min(1440, parseInt(process.argv[2] || '5', 10) || 5)
);
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

function getToken() {
  return execSync('gcloud auth print-access-token', { encoding: 'utf8' }).trim();
}

function tsFields(iso) {
  return { timestampValue: iso };
}

function str(s) {
  return { stringValue: String(s) };
}

function requestJson(method, urlPath, bodyObj) {
  return new Promise((resolve, reject) => {
    const token = getToken();
    const body = bodyObj ? JSON.stringify(bodyObj) : null;
    const full = urlPath.startsWith('http') ? urlPath : `${BASE}/${urlPath}`;
    const u = urlMod.parse(full);
    const opts = {
      hostname: u.hostname,
      path: (u.pathname || '') + (u.search || ''),
      method,
      headers: {
        Authorization: `Bearer ${token}`,
      },
    };
    if (body) {
      opts.headers['Content-Type'] = 'application/json';
      opts.headers['Content-Length'] = Buffer.byteLength(body);
    }
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', (c) => {
        data += c;
      });
      res.on('end', () => {
        let json;
        try {
          json = JSON.parse(data);
        } catch (e) {
          json = { raw: data };
        }
        if (res.statusCode < 200 || res.statusCode >= 300) {
          reject(new Error(`${res.statusCode} ${data}`));
        } else {
          resolve(json);
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

async function listAllFcmTokenUserIds() {
  const userIds = new Set();
  let pageToken = '';
  for (;;) {
    const q = pageToken
      ? `fcm_tokens?pageSize=300&pageToken=${encodeURIComponent(pageToken)}`
      : 'fcm_tokens?pageSize=300';
    const data = await requestJson('GET', q);
    for (const doc of data.documents || []) {
      const uid =
        doc.fields &&
        doc.fields.userId &&
        doc.fields.userId.stringValue;
      if (uid) userIds.add(uid);
    }
    pageToken = data.nextPageToken || '';
    if (!pageToken) break;
  }
  return Array.from(userIds);
}

async function createScheduledPush(userId, sendAtIso) {
  const url = `${BASE}/scheduled_test_pushes`;
  const body = {
    fields: {
      userId: str(userId),
      sendAt: tsFields(sendAtIso),
      status: str('pending'),
      title: str('Plant Care — тест'),
      body: str(
        `Массовый тест FCM через ${DELAY_MIN} мин. Если видишь это — доставка работает.`
      ),
      createdAt: tsFields(new Date().toISOString()),
    },
  };
  return requestJson('POST', url, body);
}

async function main() {
  const token = getToken();
  if (!token) throw new Error('No gcloud token. Run: gcloud auth login');

  console.log(`Listing fcm_tokens in ${PROJECT}...`);
  const userIds = await listAllFcmTokenUserIds();
  console.log(`Found ${userIds.length} distinct userId(s).`);

  const sendAt = new Date(Date.now() + DELAY_MIN * 60 * 1000);
  const sendAtIso = sendAt.toISOString();
  console.log(`Enqueueing sends at (UTC) ~ ${sendAtIso} (${DELAY_MIN} min from now)`);

  let ok = 0;
  for (const uid of userIds) {
    try {
      await createScheduledPush(uid, sendAtIso);
      ok += 1;
      process.stdout.write('.');
    } catch (e) {
      console.error(`\nFail uid=${uid}:`, e.message);
    }
  }
  console.log(`\nDone. Enqueued: ${ok}/${userIds.length}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
