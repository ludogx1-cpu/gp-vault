const { admin } = require('./src/services/firebaseService');
async function run() {
  const db = admin.firestore();
  const userRef = db.collection('users').doc('P8iffVqbUgetAVA4MdHVZ1CfvUv1');
  const userSnapshot = await userRef.get();
  const data = userSnapshot.data();
  console.log("Old Bank Balance:", data.bank_balance);
  const newBalance = Number(data.bank_balance || 0) + 9;
  await userRef.update({ bank_balance: newBalance });
  console.log("New Bank Balance:", newBalance);
  process.exit(0);
}
run();
