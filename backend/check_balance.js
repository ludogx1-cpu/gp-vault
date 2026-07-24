const { admin } = require('./src/services/firebaseService');

async function checkUserBalances() {
  const db = admin.firestore();
  try {
    const userSnapshot = await db.collection('users').doc('pvFYdxQcvlcWtEtQrHXi272Fk2z1').get();
    console.log("User Data:");
    console.log("DOGE Balance (Vault):", userSnapshot.data().doge_balance);
    console.log("Offerwall Balance:", userSnapshot.data().offerwall_balance);
    console.log("Pending Offerwall Balance:", userSnapshot.data().pending_offer_balance);
    console.log("Bank Balance:", userSnapshot.data().bank_balance);
  } catch(e) {
    console.error(e);
  }
  process.exit(0);
}
checkUserBalances();
