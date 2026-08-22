const cron = require('node-cron');
const { admin } = require('./firebaseService');
const { calculatePendingInterest } = require('../utils/stakingMath');

const runStakingReminderLogic = async () => {
  console.log('Running staking reminder logic...');
  try {
    const db = admin.firestore();
    
    // Query users who have staked balance
    const snapshot = await db.collection('users')
      .where('staked_balance', '>', 0)
      .get();

    if (snapshot.empty) {
      console.log('No users with staked balance found.');
      return;
    }

    const tokens = [];
    for (const userDoc of snapshot.docs) {
      const data = userDoc.data();
      if (data.fcm_token) {
        // Calculate pending interest
        const pendingInterest = calculatePendingInterest(data.staked_balance, data.stake_timestamp);
        if (pendingInterest > 0.01) { // Threshold for notification
          tokens.push(data.fcm_token);
        }
      }
    }

    if (tokens.length > 0) {
      // Chunking if tokens > 500 isn't implemented here, assuming < 500 for simplicity or using sendEachForMulticast which handles up to 500
      const message = {
        notification: {
          title: 'Golden Paw Staking 💰',
          body: 'Your staking interest is ready! Harvest your yield now to keep it compounding for the next 24 hours.'
        },
        tokens: tokens.slice(0, 500) // FCM limit per multicast
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Staking reminder notifications sent to ${response.successCount} users.`);
    }
  } catch (error) {
    console.error('Error running staking cron logic:', error);
  }
};

function startStakingCronService() {
  // Run every day at 8:00 AM UK time
  cron.schedule('0 8 * * *', runStakingReminderLogic, {
    scheduled: true,
    timezone: "Europe/London"
  });

  console.log('Staking Reminder Cron Service initialized (Runs daily at 8 AM UK).');
}

module.exports = { startStakingCronService, runStakingReminderLogic };
