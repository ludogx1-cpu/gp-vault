const { admin } = require('./src/services/firebaseService');

async function run() {
  const snapshot = await admin.firestore().collection('debug_logs')
    .orderBy('timestamp', 'desc')
    .limit(500)
    .get();
  
  let maxWithdraw = 0;
  let maxUser = null;
  
  snapshot.forEach(doc => {
    const data = doc.data();
    // Assuming debug_logs contains 'message' and 'data'
    // or maybe the message contains the amount
    if (data.message && (data.message.includes('Withdraw request') || data.message.includes('Send DOGE success'))) {
       console.log(data);
    }
  });
  process.exit(0);
}
run();
