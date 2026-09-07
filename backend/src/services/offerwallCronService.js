const cron = require('node-cron');
const { admin } = require('./firebaseService');
const { syncUserBalances } = require('../utils/dataConnectSync');
const { logRewardEvent } = require('../utils/rewardAudit');

async function releasePendingOffers() {
  const db = admin.firestore();
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  // Preserve the seven-day hold without adding an index prerequisite.
  const snapshot = await db.collection('offerwall_transactions')
    .where('status', '==', 'pending').get();
  for (const candidate of snapshot.docs) {
    try {
      const result = await db.runTransaction(async (transaction) => {
        // Recheck status in the same transaction as the balance credit.
        const offerDoc = await transaction.get(candidate.ref);
        if (!offerDoc.exists) return null;
        const offer = offerDoc.data();
        if (offer.status !== 'pending' || !offer.timestamp ||
            offer.timestamp.toDate() > sevenDaysAgo) return null;
        const amount = Number(offer.amount);
        if (!Number.isFinite(amount)) throw new Error('Invalid offer amount');
        if (amount <= 0) {
          // Preserve existing handling; chargeback policy is a separate concern.
          transaction.update(candidate.ref, { status: 'released' });
          return null;
        }
        const userRef = db.collection('users').doc(offer.userId);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return null;
        const data = userDoc.data();
        const updates = {
          pending_offer_balance: Math.max(0, Number(data.pending_offer_balance || 0) - amount),
          offerwall_balance: Number(data.offerwall_balance || 0) + amount,
          reward_history: [{ sector: 'Offerwalls (Released)', amount, timestamp: Date.now() },
            ...(data.reward_history || [])].slice(0, 15),
          total_earned: admin.firestore.FieldValue.increment(amount),
        };
        transaction.update(userRef, updates);
        transaction.update(candidate.ref, { status: 'released' });
        return { uid: offer.userId, data, updates, amount };
      });
      if (result) {
        await syncUserBalances(result.uid, result.data, result.updates);
        await logRewardEvent(result.uid, 'offerwall_completion', result.amount,
          { status: 'released', transactionId: candidate.id });
      }
    } catch (error) {
      console.error(`[OfferwallCron] Could not release ${candidate.id}:`, error.message);
    }
  }
}

function startOfferwallCronService() {
  cron.schedule('0 * * * *', () => {
    releasePendingOffers().catch(error => console.error('[OfferwallCron]', error));
  });
  console.log('Offerwall Cron Service scheduled.');
}
module.exports = { startOfferwallCronService, releasePendingOffers };
