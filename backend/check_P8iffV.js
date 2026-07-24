const { admin } = require('./src/services/firebaseService');
async function run() {
  const userSnapshot = await admin.firestore().collection('users').doc('P8iffVqbUgetAVA4MdHVZ1CfvUv1').get();
  console.log("User Data for P8iffV:");
  console.log("DOGE Balance (Vault):", userSnapshot.data().doge_balance);
  console.log("Offerwall Balance:", userSnapshot.data().offerwall_balance);
  console.log("Pending Offerwall Balance:", userSnapshot.data().pending_offer_balance);
  console.log("Bank Balance:", userSnapshot.data().bank_balance);
  process.exit(0);
}
run();
