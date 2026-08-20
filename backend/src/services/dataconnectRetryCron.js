const cron = require('node-cron');
const { admin } = require('./firebaseService');
const { updateUserBalances, updatePetStats } = require('../dataconnect-admin-generated');

async function retryFailedDataConnectSyncs() {
  console.log('[DataConnectRetryCron] Checking for failed syncs...');
  try {
    const db = admin.firestore();
    const snapshot = await db.collection('failed_dataconnect_syncs')
      .where('status', '==', 'pending')
      .limit(100)
      .get();

    if (snapshot.empty) {
      console.log('[DataConnectRetryCron] No failed syncs found.');
      return;
    }

    console.log(`[DataConnectRetryCron] Found ${snapshot.size} failed syncs to retry.`);

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const { uid, mutationType, payload, retryCount } = data;

      try {
        if (mutationType === 'UpdateUserBalances') {
          await updateUserBalances(payload);
        } else if (mutationType === 'UpdatePetStats') {
          await updatePetStats(payload);
        } else {
          throw new Error(`Unknown mutationType: ${mutationType}`);
        }

        // Success! Delete the DLQ document
        await doc.ref.delete();
        console.log(`[DataConnectRetryCron] Successfully recovered sync for user ${uid} (${mutationType})`);
      } catch (retryError) {
        console.error(`[DataConnectRetryCron] Retry failed for user ${uid} (${mutationType}):`, retryError.message);
        
        const nextRetryCount = (retryCount || 0) + 1;
        // If it failed 5 times, mark it as failed permanently
        if (nextRetryCount >= 5) {
          await doc.ref.update({
            retryCount: nextRetryCount,
            status: 'failed',
            lastError: retryError.message,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          console.warn(`[DataConnectRetryCron] Sync for user ${uid} permanently failed after 5 retries.`);
        } else {
          await doc.ref.update({
            retryCount: nextRetryCount,
            lastError: retryError.message,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }
    }
  } catch (error) {
    console.error('[DataConnectRetryCron] Critical error in retry service:', error);
  }
}

function startDataconnectRetryCronService() {
  // Run every 15 minutes
  cron.schedule('*/15 * * * *', () => {
    retryFailedDataConnectSyncs();
  });
  console.log('Data Connect Retry Cron Service scheduled.');
}

module.exports = {
  startDataconnectRetryCronService,
  retryFailedDataConnectSyncs
};
