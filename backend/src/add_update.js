const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const newUpdateRef = admin.firestore().collection('updates').doc();
    await newUpdateRef.set({
      title: 'TimeWall Integration is LIVE! 🚀',
      message: 'Huge news! We have successfully integrated TimeWall into the Offerwall Hub. You can now earn DOGE faster than ever by completing tasks, clicking PTC ads, and playing games through the TimeWall network. Plus, we added quick links for instant access!',
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
