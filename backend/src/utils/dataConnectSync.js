const { updateUserBalances, updatePetStats } = require('../dataconnect-admin-generated');

function resolveNumber(updateValue, currentValue, defaultValue = 0) {
  if (updateValue && typeof updateValue === 'object' && Number.isFinite(Number(updateValue.operand))) {
    return Number(currentValue ?? defaultValue) + Number(updateValue.operand);
  }

  const resolved = updateValue ?? currentValue ?? defaultValue;
  const numeric = Number(resolved);
  return Number.isFinite(numeric) ? numeric : defaultValue;
}

/**
 * Syncs user balances to Data Connect.
 * @param {string} uid User ID
 * @param {object} data Current user data from Firestore (before updates)
 * @param {object} updates Updates being applied to Firestore
 */
async function syncUserBalances(uid, data, updates) {
  try {
    await updateUserBalances({
      id: uid,
      dogeBalance: resolveNumber(updates.doge_balance, data.doge_balance),
      stakedBalance: resolveNumber(updates.staked_balance, data.staked_balance),
      bankBalance: resolveNumber(updates.bank_balance, data.bank_balance),
      offerwallBalance: resolveNumber(updates.offerwall_balance, data.offerwall_balance),
      adsBalance: resolveNumber(updates.ads_balance, data.ads_balance),
      xp: resolveNumber(updates.xp ?? updates.pet_xp, data.xp ?? data.pet_xp),
      totalClaims: resolveNumber(updates.total_claims, data.total_claims),
      faucetClaims: resolveNumber(updates.total_faucet_claims, data.total_faucet_claims),
      lastClaimTime: (updates.last_claim_time ?? data.last_claim_time)?.toDate?.()?.toISOString() || null
    });
    console.log(`[Dual-Write] Data Connect balances updated successfully for user ${uid}`);
  } catch (error) {
    console.error(`[Dual-Write] Failed to write balances to Data Connect for user ${uid}:`, error);
  }
}

/**
 * Syncs pet stats to Data Connect.
 * @param {string} uid User ID
 * @param {object} data Current user data from Firestore (before updates)
 * @param {object} updates Updates being applied to Firestore
 */
async function syncPetStats(uid, data, updates) {
  try {
    await updatePetStats({
      id: uid,
      petHunger: resolveNumber(updates.pet_hunger, data.pet_hunger, 100),
      petHappiness: resolveNumber(updates.pet_happiness, data.pet_happiness, 100),
      petEnergy: resolveNumber(updates.pet_energy, data.pet_energy, 100)
    });
    console.log(`[Dual-Write] Data Connect pet stats updated successfully for user ${uid}`);
  } catch (error) {
    console.error(`[Dual-Write] Failed to write pet stats to Data Connect for user ${uid}:`, error);
  }
}

module.exports = {
  syncUserBalances,
  syncPetStats
};
