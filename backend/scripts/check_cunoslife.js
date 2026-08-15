const { admin } = require('./src/services/firebaseService');
async function run() {
  const uid = 'EYgFvnEnvqY9xy5bSCLrVJqeGoy1';
  const db = admin.firestore();
  
  // Get User doc
  const userDoc = await db.collection('users').doc(uid).get();
  if (userDoc.exists) {
    const data = userDoc.data();
    console.log("Total Earned:", data.total_earned);
    console.log("Bank Balance:", data.bank_balance);
    
    // Summarize reward_history
    const history = data.reward_history || [];
    let totalOfferwall = 0;
    let otherSectors = {};
    
    history.forEach(h => {
      if (h.sector.includes('Offerwall')) {
        totalOfferwall += h.amount;
      }
      otherSectors[h.sector] = (otherSectors[h.sector] || 0) + h.amount;
    });
    console.log("Reward History Sector Breakdown:", otherSectors);
  }

  // Get Offerwall Transactions
  console.log("\n--- Offerwall Transactions ---");
  const offersSnap = await db.collection('offerwall_transactions').where('uid', '==', uid).get();
  offersSnap.forEach(doc => {
    const offer = doc.data();
    console.log(offer.offerwall, "-", offer.amount, "DOGE (Status:", offer.status, "Type:", offer.type, "Campaign:", offer.campaign_name, ")");
  });

  process.exit(0);
}
run();
