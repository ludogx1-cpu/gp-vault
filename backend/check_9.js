const { admin } = require('./src/services/firebaseService');
async function run() {
  const snapshot = await admin.firestore().collection('offerwall_transactions').where('amount', '==', 9).get();
  snapshot.forEach(doc => {
    console.log(doc.id, doc.data());
  });
  const snapshot2 = await admin.firestore().collection('users').get();
  snapshot2.forEach(doc => {
    const data = doc.data();
    if (data.reward_history) {
      data.reward_history.forEach(h => {
        if (h.amount == 9 || h.amount == -9 || h.amount >= 9) {
           console.log("User:", doc.id, h);
        }
      });
    }
  });
  process.exit(0);
}
run();
