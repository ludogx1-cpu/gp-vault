const { admin } = require('./src/services/firebaseService');

async function runMigration() {
  console.log("Starting migration to add status: 'pending' to offerwall_transactions...");
  const db = admin.firestore();
  try {
    const snapshot = await db.collection('offerwall_transactions').get();
    const batch = db.batch();
    let count = 0;

    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.status === undefined) {
        let newStatus = 'pending';
        // For TimeWall, if type is not credit/chargeback, it shouldn't be pending, 
        // but looking at offerwallRoutes, we only really care about releasing the credits
        if (data.type && data.type !== 'credit' && data.type !== 'chargeback') {
          newStatus = data.type; // 'hold' or 'hold_cancelled'
        }
        batch.update(doc.ref, { status: newStatus });
        count++;
      }
    });

    if (count > 0) {
      await batch.commit();
      console.log(`Successfully migrated ${count} transactions.`);
    } else {
      console.log("No transactions needed migration.");
    }
  } catch (error) {
    console.error("Migration failed:", error);
  }
  process.exit(0);
}

runMigration();
