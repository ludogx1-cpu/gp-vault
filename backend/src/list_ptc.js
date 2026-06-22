const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const ptcRef = admin.firestore().collection('ptc_ads');
    const snapshot = await ptcRef.get();
    
    console.log("All PTC ads in database:");
    snapshot.forEach(doc => {
      const data = doc.data();
      console.log(`- ID: ${doc.id}, Title: ${data.title}, URL: ${data.target_url}, Reward: ${data.reward}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}
run();
