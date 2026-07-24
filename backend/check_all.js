const { admin } = require('./src/services/firebaseService');
async function run() {
  const snapshot = await admin.firestore().collection('users').get();
  snapshot.forEach(doc => {
    console.log(doc.id, "Offerwall:", doc.data().offerwall_balance, "Bank:", doc.data().bank_balance);
  });
  process.exit(0);
}
run();
