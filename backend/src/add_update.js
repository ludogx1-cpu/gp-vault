const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const newUpdateRef = admin.firestore().collection('updates').doc();
    await newUpdateRef.set({
      title: 'TimeWall Payout Update ⏳',
      message: 'TimeWall payouts are temporarily suspended for background checks. You can still earn on TimeWall, and all other features (Faucet, Promo) work perfectly! Enjoy a 2x Pet XP boost this week as an apology.',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("Added new update successfully!");
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}
run();
