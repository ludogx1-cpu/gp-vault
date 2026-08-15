const { admin } = require('./src/services/firebaseService');
async function run() {
  // Get all users
  const usersSnap = await admin.firestore().collection('users').get();
  
  // Get all successful withdrawals
  const withdrawSnap = await admin.firestore().collection('withdrawals').get();
  const successfulUids = new Set();
  const successfulTimestamps = new Set();
  withdrawSnap.forEach(d => {
    successfulUids.add(d.data().uid);
    // Maybe store timestamp to match?
  });

  let failedAmountTotal = 0;
  
  usersSnap.forEach(userDoc => {
    const user = userDoc.data();
    if (user.last_withdrawal) {
      // Check if there's a matching withdrawal in 'withdrawals'
      let found = false;
      withdrawSnap.forEach(wDoc => {
        const w = wDoc.data();
        if (w.uid === userDoc.id) {
          // If the timestamps are within 2 minutes
          const diff = Math.abs(w.timestamp.seconds - user.last_withdrawal.seconds);
          if (diff < 120) {
             found = true;
          }
        }
      });
      
      if (!found) {
        console.log("User tried to withdraw but failed:", userDoc.id, "email:", user.email);
        console.log("Current doge_balance:", user.doge_balance, "bank_balance:", user.bank_balance);
        console.log("Last withdrawal attempt time:", user.last_withdrawal.toDate());
      }
    }
  });
  
  process.exit(0);
}
run();
