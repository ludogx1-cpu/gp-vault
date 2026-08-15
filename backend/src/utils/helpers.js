function normalizeHttpUrl(input) {
  if (typeof input !== 'string' || !input.trim()) return null;
  try {
    const parsed = new URL(input.trim());
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      return null;
    }
    return parsed.toString();
  } catch {
    return null;
  }
}

function getBannerCost(slot, pool) {
  const normalizedSlot = String(slot || '').trim().toLowerCase();
  const normalizedPool = String(pool || '').trim().toLowerCase();

  const adSlotCosts = {
    global_banner: 7.0,
  };

  const sponsorSlotCosts = {
    'top banner 1': 4.0,
  };

  if (!pool) {
    return adSlotCosts[normalizedSlot] ?? sponsorSlotCosts[normalizedSlot] ?? null;
  }

  if (normalizedPool === 'ads') {
    return adSlotCosts[normalizedSlot] ?? null;
  }

  if (normalizedPool === 'sponsor_placeholder') {
    return sponsorSlotCosts[normalizedSlot] ?? null;
  }

  return null;
}

function getPtcConfig(tier, clicks) {
  const tierConfigs = {
    1: { reward: 0.0005, duration: 10, pricePerClick: 0.0025 },
    2: { reward: 0.001, duration: 20, pricePerClick: 0.0050 },
    3: { reward: 0.0015, duration: 30, pricePerClick: 0.0075 },
    4: { reward: 0.003, duration: 60, pricePerClick: 0.0150 },
  };

  const parsedTier = Number(tier);
  const parsedClicks = Number(clicks);
  if (!Number.isInteger(parsedTier) || !Number.isInteger(parsedClicks)) return null;
  if (parsedClicks < 100 || parsedClicks > 10000 || parsedClicks % 100 !== 0) return null;

  const cfg = tierConfigs[parsedTier];
  if (!cfg) return null;

  const totalCost = Number((cfg.pricePerClick * parsedClicks).toFixed(8));
  return { ...cfg, totalCost };
}

function verifyIpnSignature(payload = {}) {
  const secret = process.env.FAUCETPAY_IPN_SECRET;
  if (!secret) {
    return { ok: true, mode: 'disabled' };
  }
  const provided = payload.security_code;
  if (provided === secret) {
    return { ok: true, mode: 'security_code' };
  }
  return { ok: false, mode: 'security_code' };
}

function parseUsdNumber(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

function formatAmount(amount) {
  return Number(Number(amount).toFixed(8)).toString();
}

async function verifyCaptchaToken(token, provider) {
  // If we are explicitly in development mode, we bypass captcha
  if (process.env.NODE_ENV === 'development') {
    console.warn('CAPTCHA verification bypassed (development mode)');
    return true; 
  }

  try {
    let secret = '';
    let url = '';

    const normalizedProvider = String(provider || '').toLowerCase();

    if (normalizedProvider === 'hcaptcha') {
      url = 'https://hcaptcha.com/siteverify';
      secret = process.env.HCAPTCHA_SECRET;
    } else if (normalizedProvider === 'turnstile') {
      url = 'https://challenges.cloudflare.com/turnstile/v0/siteverify';
      secret = process.env.TURNSTILE_SECRET_KEY || process.env.TURNSTILE_SECRET;
    } else {
      console.error(`Unknown captcha provider: ${provider}`);
      return false;
    }

    if (!secret) {
      console.error(`CAPTCHA verification failed (Missing secret key for ${provider})`);
      return false; // Fail closed if secret is missing for security
    }

    const params = new URLSearchParams({
      secret: secret,
      response: token,
    });

    const response = await fetch(url, {
      method: 'POST',
      body: params,
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });

    const data = await response.json();
    return data.success === true;
  } catch (error) {
    console.error('Captcha verification error:', error);
    return false;
  }
}

function getStreakUpdates(data) {
  const now = new Date();
  const todayStr = now.toISOString().split('T')[0];
  
  let streak_count = Number(data.streak_count || 0);
  let last_streak_date = data.last_streak_date || ''; 
  
  let updates = {};
  
  if (last_streak_date === todayStr) {
    return updates;
  }
  
  if (!last_streak_date) {
    updates.streak_count = 1;
    updates.last_streak_date = todayStr;
    return updates;
  }

  const yesterday = new Date(now);
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const yesterdayStr = yesterday.toISOString().split('T')[0];

  if (last_streak_date === yesterdayStr) {
    updates.streak_count = streak_count + 1;
    updates.last_streak_date = todayStr;
  } else {
    updates.streak_count = 1;
    updates.last_streak_date = todayStr;
  }
  
  return updates;
}

module.exports = {
  normalizeHttpUrl,
  getBannerCost,
  getPtcConfig,
  verifyIpnSignature,
  parseUsdNumber,
  formatAmount,
  verifyCaptchaToken,
  getStreakUpdates,
};
