const { admin } = require('./src/services/firebaseService');
async function run() {
  const userSnapshot = await admin.firestore().collection('users').doc('P8iffVqbUgetAVA4MdHVZ1CfvUv1').get();
  console.log(userSnapshot.data().reward_history);
  process.exit(0);
}
run();
