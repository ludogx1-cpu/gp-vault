const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const newUpdateRef = admin.firestore().collection('updates').doc();
    await newUpdateRef.set({
      title: 'v1.4 - Chat & Faucet Updates',
      message: 'Added a Community Chat with a Swear Jar!\nWithdrawal minimum updated to 1 DOGE.\nA-Ads visibility improved.',
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
