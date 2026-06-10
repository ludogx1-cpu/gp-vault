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
    1: { reward: 0.0002, duration: 10, pricePerClick: 0.005 },
    2: { reward: 0.0004, duration: 20, pricePerClick: 0.01 },
    3: { reward: 0.0006, duration: 30, pricePerClick: 0.015 },
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

module.exports = {
  normalizeHttpUrl,
  getBannerCost,
  getPtcConfig,
  verifyIpnSignature,
  parseUsdNumber,
  formatAmount,
};
