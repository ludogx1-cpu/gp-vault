const { admin } = require('./src/services/firebaseService');

async function run() {
  const snapshot = await admin.firestore().collection('debug_logs').get();
  
  let maxAmount = 0;
  let maxAmountUser = null;
  
  snapshot.forEach(doc => {
    const data = doc.data();
    try {
      if (data.message && data.message.includes('Withdraw request')) {
        const payloadStr = data.message.split('Withdraw request: ')[1];
        if (payloadStr) {
           const payload = JSON.parse(payloadStr);
           if (payload.amount > maxAmount) {
             maxAmount = payload.amount;
             maxAmountUser = payload.authUser?.email || payload.address;
           }
        }
      }
      if (data.message && data.message.includes('Bank withdraw request')) {
        const payloadStr = data.message.split('Bank withdraw request: ')[1];
        if (payloadStr) {
           const payload = JSON.parse(payloadStr);
           if (payload.amount > maxAmount) {
             maxAmount = payload.amount;
             maxAmountUser = payload.authUser?.email || payload.address;
           }
        }
      }
    } catch(e) {}
  });

  console.log('Max withdrawal amount:', maxAmount, 'User:', maxAmountUser);
  process.exit(0);
}
run();
