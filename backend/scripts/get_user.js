const { admin } = require('./src/services/firebaseService');
async function run() {
  const doc = await admin.firestore().collection('users').doc('P8iffVqbUgetAVA4MdHVZ1CfvUv1').get();
  console.log(doc.data());
  process.exit(0);
}
run();
