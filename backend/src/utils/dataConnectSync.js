const { updateUserBalances, updatePetStats } = require('../dataconnect-admin-generated');

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
      dogeBalance: Number(updates.doge_balance ?? data.doge_balance ?? 0),
      stakedBalance: Number(updates.staked_balance ?? data.staked_balance ?? 0),
      bankBalance: Number(updates.bank_balance ?? data.bank_balance ?? 0),
      offerwallBalance: Number(updates.offerwall_balance ?? data.offerwall_balance ?? 0),
      adsBalance: Number(updates.ads_balance ?? data.ads_balance ?? 0),
      xp: Number(updates.xp ?? updates.pet_xp ?? data.xp ?? data.pet_xp ?? 0),
      totalClaims: Number(updates.total_claims ?? data.total_claims ?? 0),
      faucetClaims: Number(updates.total_faucet_claims ?? data.total_faucet_claims ?? 0),
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
      petHunger: Number(updates.pet_hunger ?? data.pet_hunger ?? 100),
      petHappiness: Number(updates.pet_happiness ?? data.pet_happiness ?? 100),
      petEnergy: Number(updates.pet_energy ?? data.pet_energy ?? 100)
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
