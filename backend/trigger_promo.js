const { admin } = require('./src/services/firebaseService');
const { startPromoCronService } = require('./src/services/promoCronService');

async function trigger() {
  console.log("Forcing a daily promo generation...");
  const db = admin.firestore();
  const wordsList = [
    "doge", "moon", "rocket", "crypto", "blockchain",
    "wallet", "shiba", "paw", "golden", "vault",
    "coin", "token", "mining", "faucet", "reward",
    "bonus", "steak", "hodl", "wagmi", "airdrop"
  ];
  const randomWord = wordsList[Math.floor(Math.random() * wordsList.length)];
  const randomNumber = Math.floor(Math.random() * 99) + 1;
  const todayCode = `${randomWord}${randomNumber}`;
  console.log(`Setting manual promo code for testing: ${todayCode}`);

  await db.collection('system_settings').doc('promo').set({
    code: todayCode,
    timestamp: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  console.log("Successfully set promo code. Sending notification...");
  const message = {
    notification: {
      title: 'Daily Promo Code!',
      body: `Today's secret word is ${todayCode}. Enter it now to roll for up to 0.10 DOGE!`
    },
    topic: 'promo_updates'
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent promo notification:', response);
  } catch (error) {
    console.error("No subscribers yet, but code is set!");
  }
  process.exit(0);
}
trigger();
