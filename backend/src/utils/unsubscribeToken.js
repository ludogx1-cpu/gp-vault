const crypto = require('crypto');

const BACKEND_URL = process.env.PUBLIC_BACKEND_URL || 'https://golden-paw-vault.onrender.com';

// A server-only secret. Set UNSUBSCRIBE_SECRET on Render to use a dedicated
// one; otherwise the Firebase service account's private key is used.
function getSecret() {
  if (process.env.UNSUBSCRIBE_SECRET) return process.env.UNSUBSCRIBE_SECRET;
  if (process.env.FIREBASE_PRIVATE_KEY) return process.env.FIREBASE_PRIVATE_KEY;
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON).private_key || null;
    } catch (_) {
      return null;
    }
  }
  return null;
}

function unsubscribeToken(uid) {
  const secret = getSecret();
  if (!secret || !uid) return null;
  return crypto.createHmac('sha256', secret).update(`unsubscribe:${uid}`).digest('base64url').slice(0, 32);
}

function isValidUnsubscribeToken(uid, token) {
  const expected = unsubscribeToken(uid);
  if (!expected || typeof token !== 'string' || token.length !== expected.length) return false;
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(token));
}

/** Link to put in marketing emails; only the signed link unsubscribes. */
function unsubscribeUrl(uid) {
  const token = unsubscribeToken(uid);
  return token ? `${BACKEND_URL}/unsubscribe/${encodeURIComponent(uid)}/${token}` : null;
}

module.exports = { unsubscribeToken, isValidUnsubscribeToken, unsubscribeUrl };
