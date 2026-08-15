const { admin } = require('./src/services/firebaseService');
async function run() {
  const snap = await admin.firestore().collection('debug_logs').get();
  let totalAmount = 0;
  snap.forEach(doc => {
    const data = doc.data();
    if (data.message && data.message.toLowerCase().includes('withdraw')) {
      console.log('withdraw log:', data.message);
    }
    if (data.message && data.message.toLowerCase().includes('fail')) {
      console.log('fail log:', data.message);
    }
  });
  console.log('Done searching debug_logs');
  process.exit(0);
}
run();
