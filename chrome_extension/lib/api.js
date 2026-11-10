import { API_BASE, FAUCET_COOLDOWN_MS } from './config.js';
import { getIdToken } from './auth.js';

async function post(path, body = {}) {
  const token = await getIdToken();
  let res;
  try {
    res = await fetch(`${API_BASE}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(60_000),
    });
  } catch {
    // Render free instances sleep; the first request after a nap can time out.
    throw new Error('The server is waking up. Try again in a few seconds.');
  }
  let data = {};
  try {
    data = await res.json();
  } catch {
    // non-JSON error page
  }
  if (!res.ok || data.success === false) {
    const err = new Error(data.error || data.message || `Request failed (${res.status})`);
    err.status = res.status;
    throw err;
  }
  return data;
}

export const getPet = () => post('/pet-status').then((d) => d.pet || d.stats || d);
export const petAction = (action) => post(`/pet-${action}`);

export const claimToVault = (captcha) =>
  post('/claim-vault', { captcha_token: captcha.token, captcha_provider: captcha.provider });

export const claimToFaucetPay = (address, captcha) =>
  post('/send-doge', {
    user_address: address,
    captcha_token: captcha.token,
    captcha_provider: captcha.provider,
    source: 'chrome-extension',
  });

// The backend reports cooldowns only as text: "Please wait 3 minutes..." or "Try again in 120 seconds."
export function cooldownFromError(message = '') {
  const secs = message.match(/(\d+)\s*second/i);
  if (secs) return Number(secs[1]) * 1000;
  const mins = message.match(/(\d+)\s*minute/i);
  if (mins) return Math.min(Number(mins[1]) * 60_000, FAUCET_COOLDOWN_MS);
  return 0;
}
