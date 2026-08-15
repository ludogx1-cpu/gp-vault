const { admin } = require('./firebaseService');

/**
 * Logs a financial transaction to the ledger.
 * @param {object|null} transaction - The firestore transaction object (if running inside one) or null
 * @param {string} uid - User ID
 * @param {number} amount - Positive for deposit, negative for withdrawal/cost
 * @param {string} type - e.g., 'faucet_claim', 'ptc_reward', 'stake', 'unstake', 'withdrawal', 'referral_bonus'
 * @param {object} metadata - Additional info (e.g., ad_id, transaction_hash)
 */
async function logTransaction(transaction, uid, amount, type, metadata = {}) {
  const ref = admin.firestore().collection('transactions').doc();
  const data = {
    uid,
    amount,
    type,
    metadata,
    timestamp: admin.firestore.FieldValue.serverTimestamp()
  };
  
  if (transaction) {
    transaction.set(ref, data);
  } else {
    await ref.set(data);
  }
}

module.exports = {
  logTransaction
};
