const { admin } = require('./src/services/firebaseService');
async function run() {
  const snap = await admin.firestore().collection('withdrawals').orderBy('timestamp', 'desc').limit(20).get();
  snap.forEach(d => console.log(d.data()));
  process.exit(0);
}
run();
