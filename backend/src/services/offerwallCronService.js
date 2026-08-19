const cron = require('node-cron');
const { admin } = require('./firebaseService');
const { syncUserBalances } = require('../utils/dataConnectSync');

async function releasePendingOffers() {
  console.log('[OfferwallCron] Starting check for mature pending offers...');
  try {
    const db = admin.firestore();
    
    // 7 days ago
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const timestampThreshold = admin.firestore.Timestamp.fromDate(sevenDaysAgo);

    const snapshot = await db.collection('offerwall_transactions')
      .where('status', '==', 'pending')
      .get();

    if (snapshot.empty) {
      console.log('[OfferwallCron] No pending offers found.');
      return;
    }

    // Filter by timestamp in memory to avoid needing a composite index
    const matureDocs = snapshot.docs.filter(doc => {
      const ts = doc.data().timestamp;
      if (!ts) return false;
      return ts.toDate() <= sevenDaysAgo;
    });

    if (matureDocs.length === 0) {
      console.log('[OfferwallCron] No mature pending offers found.');
      return;
    }

    console.log(`[OfferwallCron] Found ${matureDocs.length} mature offers to release.`);

    // Group transactions by user to minimize user doc writes
    const userUpdates = {};
    const transactionDocs = [];

    matureDocs.forEach(doc => {
      const data = doc.data();
      const userId = data.userId;
      const amount = Number(data.amount || 0);

      if (amount > 0) {
        if (!userUpdates[userId]) {
          userUpdates[userId] = 0;
        }
        userUpdates[userId] += amount;
        transactionDocs.push({ id: doc.id, ref: doc.ref });
      } else {
         // Even if amount is 0 or negative (shouldn't happen for pending), mark it released
         transactionDocs.push({ id: doc.id, ref: doc.ref });
      }
    });

    // Process each user sequentially to avoid transaction contention
    for (const userId of Object.keys(userUpdates)) {
      const totalAmountToRelease = userUpdates[userId];
      const userRef = db.collection('users').doc(userId);

      const txResult = await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return; // Skip if user deleted

        const userData = userDoc.data();
        const currentPending = Number(userData.pending_offer_balance || 0);
        const currentOfferwall = Number(userData.offerwall_balance || 0);

        // Ensure we don't drop pending balance below 0 due to some manual edits
        const newPending = Math.max(0, currentPending - totalAmountToRelease);
        const newOfferwall = currentOfferwall + totalAmountToRelease;

        let history = userData.reward_history || [];
        history.unshift({ 
          sector: 'Offerwalls (Released)', 
          amount: totalAmountToRelease, 
          timestamp: Date.now() 
        });
        if (history.length > 15) history = history.slice(0, 15);

        const updates = {
          pending_offer_balance: newPending,
          offerwall_balance: newOfferwall,
          reward_history: history,
          total_earned: admin.firestore.FieldValue.increment(totalAmountToRelease)
        };
        transaction.update(userRef, updates);
        return { data: userData, updates };
      });
      if (txResult && txResult.data) {
        syncUserBalances(userId, txResult.data, txResult.updates).catch(console.error);
      }
      console.log(`[OfferwallCron] Released ${totalAmountToRelease} DOGE for user ${userId}.`);
      
      const { logRewardEvent } = require('../utils/rewardAudit');
      await logRewardEvent(userId, 'offerwall_completion', totalAmountToRelease, { status: 'released' });
    }

    // Mark transactions as released in batches
    const batch = db.batch();
    let batchCount = 0;
    for (const tx of transactionDocs) {
      batch.update(tx.ref, { status: 'released' });
      batchCount++;
      if (batchCount >= 500) {
        await batch.commit();
        batchCount = 0;
      }
    }
    if (batchCount > 0) {
      await batch.commit();
    }

    console.log('[OfferwallCron] Finished releasing mature pending offers.');
  } catch (error) {
    console.error('[OfferwallCron] Error releasing offers:', error);
  }
}

function startOfferwallCronService() {
  // Run every hour at minute 0
  cron.schedule('0 * * * *', () => {
    releasePendingOffers();
  });
  console.log('Offerwall Cron Service scheduled.');
}

module.exports = {
  startOfferwallCronService,
  releasePendingOffers
};
