const { admin } = require('./src/services/firebaseService');

async function run() {
  const db = admin.firestore();
  
  // 1. Migrate balance to doge_balance for all affected users
  console.log("Migrating stranded promo balances...");
  const usersSnapshot = await db.collection('users').where('balance', '>', 0).get();
  const batch = db.batch();
  let count = 0;
  
  for (const doc of usersSnapshot.docs) {
    const data = doc.data();
    const strandedBalance = Number(data.balance || 0);
    if (strandedBalance > 0) {
      const currentDoge = Number(data.doge_balance || 0);
      let history = data.reward_history || [];
      
      history.unshift({
        sector: 'Promo Bug Fix Compensation',
        amount: strandedBalance,
        timestamp: Date.now()
      });
      if (history.length > 15) history = history.slice(0, 15);
      
      batch.update(doc.ref, {
        doge_balance: currentDoge + strandedBalance,
        balance: admin.firestore.FieldValue.delete(), // Remove the bugged field
        reward_history: history
      });
      console.log(`Compensating user ${doc.id} with ${strandedBalance} DOGE`);
      count++;
    }
  }
  
  if (count > 0) {
    await batch.commit();
    console.log(`Migrated stranded balances for ${count} users.`);
  } else {
    console.log("No users found with stranded balances.");
  }
  
  // 2. Post update to the board
  console.log("Posting update to the board...");
  await db.collection('updates').add({
    title: 'Bug Fix: Promo Code Rewards',
    content: `Hello everyone! We discovered a minor bug where Dogecoin won from daily promo codes was not properly being added to your main Doge balance. 

We have just fixed this issue! If you claimed promo codes recently and didn't see your balance go up, we have automatically credited the missing Doge directly into your account (you'll see it as "Promo Bug Fix Compensation" in your history).

Thank you for playing, and we apologize for the inconvenience!`,
    timestamp: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log("Update posted!");
  
  process.exit(0);
}

run();
