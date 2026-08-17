function summarizeRewardLedger(entries = []) {
  const normalizedEntries = Array.isArray(entries) ? entries : [];

  let totalEarned = 0;
  let totalSpent = 0;
  let totalNet = 0;
  let largestSingleReward = 0;

  for (const entry of normalizedEntries) {
    const amount = Number(entry?.amount ?? 0);
    if (!Number.isFinite(amount)) continue;

    if (amount > 0) {
      totalEarned += amount;
      if (amount > largestSingleReward) largestSingleReward = amount;
    } else if (amount < 0) {
      totalSpent += Math.abs(amount);
    }

    totalNet += amount;
  }

  return {
    count: normalizedEntries.length,
    totalEarned,
    totalSpent,
    totalNet,
    largestSingleReward,
    averageReward: normalizedEntries.length > 0
      ? (totalEarned / normalizedEntries.filter((entry) => Number(entry?.amount ?? 0) > 0).length)
      : 0,
  };
}

function detectRewardAnomalies(entries = [], options = {}) {
  const thresholdMultiplier = Number(options.maxMultiplier ?? 3);
  const normalizedEntries = Array.isArray(entries) ? entries : [];
  const positiveEntries = normalizedEntries
    .map((entry) => Number(entry?.amount ?? 0))
    .filter((amount) => Number.isFinite(amount) && amount > 0);

  if (positiveEntries.length === 0) {
    return { suspicious: false, reason: 'No positive rewards recorded.' };
  }

  const average = positiveEntries.reduce((sum, value) => sum + value, 0) / positiveEntries.length;
  const highest = Math.max(...positiveEntries);

  if (average > 0 && highest > average * thresholdMultiplier) {
    return {
      suspicious: true,
      reason: 'A reward is significantly higher than the recent average.',
      average,
      highest,
      multiplier: highest / average,
    };
  }

  return {
    suspicious: false,
    reason: 'Reward distribution looks within expected range.',
    average,
    highest,
    multiplier: average > 0 ? highest / average : 0,
  };
}

module.exports = {
  summarizeRewardLedger,
  detectRewardAnomalies,
};
