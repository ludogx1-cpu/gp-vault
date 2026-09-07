const { test } = require('node:test');
const assert = require('node:assert/strict');

// No credentials or production access: this script requires an emulator.
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) {
  throw new Error('A local FIRESTORE_EMULATOR_HOST is required');
}
const project = 'demo-golden-paw';
const base = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
function token(uid) {
  const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    iss: `https://securetoken.google.com/${project}`, aud: project, sub: uid, user_id: uid,
    iat: Math.floor(Date.now() / 1000), exp: Math.floor(Date.now() / 1000) + 3600,
    firebase: { sign_in_provider: 'custom' },
  })}.`;
}
function value(entry) {
  if (entry === null) return { nullValue: null };
  if (typeof entry === 'boolean') return { booleanValue: entry };
  if (typeof entry === 'number') return { doubleValue: entry };
  if (Array.isArray(entry)) return { arrayValue: { values: entry.map(value) } };
  return { stringValue: entry };
}
async function write(path, fields, auth, mask = []) {
  const query = new URLSearchParams();
  mask.forEach(key => query.append('updateMask.fieldPaths', key));
  const result = await fetch(`${base}/${path}?${query}`, {
    method: 'PATCH', headers: { Authorization: `Bearer ${auth}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(fields).map(([key, entry]) => [key, value(entry)])) }),
  });
  return { status: result.status, body: await result.text() };
}
async function expectStatus(promise, expected) {
  const result = await promise;
  assert.equal(result.status, expected, result.body);
}

test('rules protect rewards while preserving real client profile and admin flows', async () => {
  const uid = `review-${Date.now()}`;
  const auth = token(uid);
  await expectStatus(write(`users/${uid}`, { email: 'test@example.com', joined_date: new Date().toISOString() }, auth), 200);
  await expectStatus(write(`users/${uid}`, { setupComplete: true, profile_setup_skipped: true }, auth,
    ['setupComplete', 'profile_setup_skipped']), 200);
  await expectStatus(write(`users/${uid}`, { fcm_token: 'example-token' }, auth, ['fcm_token']), 200);
  await expectStatus(write(`users/${uid}`, {}, auth, ['fcm_token']), 200);
  await expectStatus(write(`users/${uid}`, { setupComplete: 'yes' }, auth, ['setupComplete']), 403);
  await expectStatus(write(`users/${uid}`, { display_name: 'x'.repeat(101) }, auth, ['display_name']), 403);
  for (const field of ['doge_balance', 'pending_offer_balance', 'last_bonus_sponsor_claim',
    'last_ecosystem_video_claim', 'last_direct_faucet_claim', 'pending_withdrawal', 'active_trick_buffs', 'role']) {
    await expectStatus(write(`users/${uid}`, { [field]: 100 }, auth, [field]), 403);
    await expectStatus(write(`users/${uid}`, { [field]: 100 }, 'owner', [field]), 200);
    await expectStatus(write(`users/${uid}`, {}, auth, [field]), 403);
  }
  await expectStatus(write(`users/${uid}-other`, { email: 'other@example.com' }, auth), 403);
  await expectStatus(write(`chat_messages/${uid}`, { text: 'forged message' }, auth), 403);
  await expectStatus(write(`chat_messages/${uid}`, { text: 'server message' }, 'owner'), 200);
  await expectStatus(write(`chat_messages/${uid}`, { text: 'edited message' }, auth), 403);
  const deletion = await fetch(`${base}/chat_messages/${uid}`, { method: 'DELETE', headers: { Authorization: `Bearer ${auth}` } });
  assert.equal(deletion.status, 403);
  await expectStatus(write(`users/${uid}`, { role: 'admin' }, 'owner', ['role']), 200);
  await expectStatus(write(`users/${uid}`, {
    pet_owned_accessories: ['top_hat'], pet_owned_tricks: ['Spin'], active_trick_buffs: ['Spin'],
  }, auth, ['pet_owned_accessories', 'pet_owned_tricks', 'active_trick_buffs']), 200);
  await expectStatus(write(`users/${uid}`, { doge_balance: 999 }, auth, ['doge_balance']), 403);
});
