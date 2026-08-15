const { admin } = require('./src/services/firebaseService');
async function run() {
  const snap = await admin.firestore().collection('debug_logs').orderBy('timestamp', 'desc').limit(100).get();
  snap.forEach(d => console.log(d.data()));
  process.exit(0);
}
run();
