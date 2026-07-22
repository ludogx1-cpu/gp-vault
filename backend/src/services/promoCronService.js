const cron = require('node-cron');
const { admin } = require('./firebaseService');

const wordsList = [
  "doge", "moon", "rocket", "crypto", "blockchain",
  "wallet", "shiba", "paw", "golden", "vault",
  "coin", "token", "mining", "faucet", "reward",
  "bonus", "steak", "hodl", "wagmi", "airdrop"
];

function startPromoCronService() {
  // Run every day at 6:00 AM UK time
  cron.schedule('0 6 * * *', async () => {
    console.log('Running daily promo cron job at 6:00 AM UK time...');
    try {
      const db = admin.firestore();
      
      // Select random word
      const randomWord = wordsList[Math.floor(Math.random() * wordsList.length)];
      // Append a random number (e.g. doge24) to make it unique each day
      const randomNumber = Math.floor(Math.random() * 99) + 1;
      const todayCode = `${randomWord}${randomNumber}`;
      
      console.log(`Setting new daily promo code: ${todayCode}`);

      // Update Firestore
      await db.collection('system_settings').doc('promo').set({
        code: todayCode,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Send Push Notification
      const message = {
        notification: {
          title: 'Daily Promo Code!',
          body: `Today's secret word is ${todayCode}. Enter it now to roll for up to 0.10 DOGE!`
        },
        topic: 'promo_updates'
      };

      const response = await admin.messaging().send(message);
      console.log('Successfully sent promo notification:', response);

    } catch (error) {
      console.error('Error running daily promo cron job:', error);
    }
  }, {
    timezone: 'Europe/London'
  });
  
  console.log('Daily Promo Cron Service initialized (Runs at 06:00 AM UK time).');
}

module.exports = { startPromoCronService };
