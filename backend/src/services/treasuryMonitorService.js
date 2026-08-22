const cron = require('node-cron');
const { admin } = require('./firebaseService');

const runTreasuryMonitorLogic = async () => {
  console.log('Running treasury monitor logic...');
  try {
    const db = admin.firestore();
    
    // In a real app we'd fetch the Hot Wallet API balance (e.g. FaucetPay API or dogecoin RPC).
    // For now, this is a placeholder check. If you have an endpoint for the hot wallet, you would call it here.
    const isBalanceLow = false; // Replace with actual hot wallet check if available
    
    if (isBalanceLow) {
      await db.collection('admin_alerts').add({
        type: 'low_treasury_balance',
        message: 'Treasury hot wallet balance is critically low. Please refill to ensure users can withdraw.',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        acknowledged: false
      });
      console.log('Low treasury balance alert written to admin_alerts.');
    }
  } catch (error) {
    console.error('Error running treasury monitor cron logic:', error);
  }
};

function startTreasuryMonitorService() {
  // Run daily at noon
  cron.schedule('0 12 * * *', runTreasuryMonitorLogic);

  console.log('Treasury Monitor Cron Service initialized.');
}

module.exports = { startTreasuryMonitorService, runTreasuryMonitorLogic };
