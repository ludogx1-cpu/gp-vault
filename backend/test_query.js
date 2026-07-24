const { admin } = require('./src/services/firebaseService');
async function run() {
  const snapshot = await admin.firestore().collection('offerwall_transactions').limit(1).get();
  if (!snapshot.empty) {
    console.log(snapshot.docs[0].data());
  } else {
    console.log("No transactions");
  }
  process.exit(0);
}
run();
