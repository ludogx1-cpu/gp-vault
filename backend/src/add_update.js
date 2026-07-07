const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const newUpdateRef = admin.firestore().collection('updates').doc();
    await newUpdateRef.set({
      title: 'v1.6 - Massive Dogeogotcha Update!',
      message: '🎾 Physics-based Fetch: Throw the ball by dragging it! Costs 5% Hunger & Energy.\n✋ Stroking: Wiggle your cursor over your pet to fill its Attention bar!\n💤 Sleep Update: 10-minute nap gives +50% Energy and rewards 0.0001 DOGE.\n💊 Medicine is now FREE.\n🛒 Shop items are permanently cheaper!\n📜 Reward History now tracks Faucet Bonus, Staking, and Chat Rain!',
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
