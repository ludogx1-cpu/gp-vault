const { admin } = require('./src/services/firebaseService');
async function run() {
  const uid = 'EYgFvnEnvqY9xy5bSCLrVJqeGoy1';
  const db = admin.firestore();
  
  console.log("\n--- Offerwall Transactions by userId ---");
  const offersSnap = await db.collection('offerwall_transactions').where('userId', '==', uid).get();
  offersSnap.forEach(doc => {
    const offer = doc.data();
    console.log(offer.provider || offer.offerwall, "-", offer.amount, "DOGE (Status:", offer.status, "Type:", offer.type, ")");
  });

  console.log("\n--- Offerwall Transactions by uid ---");
  const offersSnap2 = await db.collection('offerwall_transactions').where('uid', '==', uid).get();
  offersSnap2.forEach(doc => {
    const offer = doc.data();
    console.log(offer.provider || offer.offerwall, "-", offer.amount, "DOGE (Status:", offer.status, "Type:", offer.type, ")");
  });
  
  process.exit(0);
}
run();
