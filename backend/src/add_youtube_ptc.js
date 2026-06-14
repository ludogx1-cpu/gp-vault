const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const newAdRef = admin.firestore().collection('ptc_ads').doc('youtube_promo_1');
    await newAdRef.set({
      title: '🎥 WATCH: Golden Paw Ecosystem!',
      target_url: 'https://www.youtube.com/shorts/_MjLuFCm21Q',
      tier: 'high',
      reward: 0.010,
      duration: 15,
      clicks_total: 999999,
      clicks_remaining: 999999,
      creator_uid: 'admin',
      status: 'active',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log("Added YouTube Promo PTC Ad!");
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}
run();
