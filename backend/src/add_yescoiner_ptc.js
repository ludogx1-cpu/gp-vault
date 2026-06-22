const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const newAdRef = admin.firestore().collection('ptc_ads').doc('yescoiner_promo_1');
    await newAdRef.set({
      title: '🪙 JOIN: YesCoiner - Instant Crypto!',
      target_url: 'https://yescoiner.com/?ref=1681170',
      tier: 'standard',
      reward: 0.008,
      duration: 10,
      clicks_total: 999999,
      clicks_remaining: 999999,
      creator_uid: 'admin',
      status: 'active',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("Added YesCoiner PTC Ad!");
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}
run();
