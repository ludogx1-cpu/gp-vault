const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const ptcRef = admin.firestore().collection('ptc_ads');
    const snapshot = await ptcRef.get();
    let count = 0;
    
    const batch = admin.firestore().batch();
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const targetUrl = (data.target_url || '').toLowerCase();
      
      if (targetUrl.includes('coinpayu') || targetUrl.includes('satman')) {
        console.log(`Updating ad ${doc.id} (URL: ${data.target_url}) to 0.008`);
        batch.update(doc.ref, { reward: 0.008 });
        count++;
      }
    });

    if (count > 0) {
      await batch.commit();
      console.log(`Successfully updated ${count} PTC ads!`);
    } else {
      console.log("No coinpayu or satman ads found.");
    }
    
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}
run();
