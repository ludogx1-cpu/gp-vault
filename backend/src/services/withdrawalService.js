const { admin } = require('./firebaseService');
const { faucetPaySend } = require('./faucetPayService');
const { formatAmount } = require('../utils/helpers');
const { syncUserBalances } = require('../utils/dataConnectSync');

// This service is exclusively for Vault withdrawals. Bank/offerwall payments
// remain disabled in faucetService.bankWithdraw.
async function withdraw(user, address, amount) {
  if (!user.email_verified) throw new Error('Email verification required to withdraw.');
  if (typeof address !== 'string' || !address.trim()) throw new Error('Missing destination address');
  const sendAmount = Number(amount);
  if (!Number.isFinite(sendAmount) || sendAmount < 1) throw new Error('Minimum withdrawal is 1 DOGE');
  // Keep existing decimal storage, but debit exactly the amount sent to the processor.
  if (Number(formatAmount(sendAmount)) !== sendAmount) throw new Error('Use at most 8 decimal places.');
  const db = admin.firestore();
  const userRef = db.collection('users').doc(user.uid);
  const requestRef = db.collection('withdrawal_requests').doc();
  const txResult = await db.runTransaction(async transaction => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) throw new Error('User profile not found');
    const data = snapshot.data();
    if (data.pending_withdrawal) throw new Error(`A withdrawal is awaiting confirmation. Reference: ${data.pending_withdrawal}`);
    if (data.last_withdrawal && Date.now() - data.last_withdrawal.toDate().getTime() < 60000) {
      throw new Error('Please wait a minute between withdrawals.');
    }
    if (Number(data.doge_balance || 0) < sendAmount) throw new Error('Insufficient balance for this withdrawal.');
    const updates = {
      doge_balance: Number(data.doge_balance || 0) - sendAmount,
      last_withdrawal: admin.firestore.Timestamp.now(),
      pending_withdrawal: requestRef.id,
    };
    transaction.update(userRef, updates);
    transaction.set(requestRef, {
      uid: user.uid, email: user.email || '', address: address.trim(), amount: sendAmount,
      status: 'pending', timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { data, updates };
  });
  await syncUserBalances(user.uid, txResult.data, txResult.updates);
  let response;
  try {
    response = await faucetPaySend(address.trim(), formatAmount(sendAmount));
  } catch (error) {
    if (error.paymentDefinitelyNotSent === true) {
      await settleWithdrawal(requestRef.id, 'refunded');
      throw new Error(`Payment was rejected. Your funds have been refunded. Reference: ${requestRef.id}`);
    }
    // A network timeout is not evidence that payment failed. Retain the debit
    // and durable reference for reconciliation; never send automatically again.
    await requestRef.update({ status: 'unknown' }).catch(console.error);
    throw new Error(`Payment confirmation is delayed. Do not retry; contact support with reference: ${requestRef.id}`);
  }
  try {
    // Persist processor evidence first, so a later database failure is recoverable.
    await requestRef.update({ status: 'paid', faucetPayResponse: response });
    await settleWithdrawal(requestRef.id, 'succeeded', response);
  } catch (error) {
    console.error(`Withdrawal ${requestRef.id} was paid but requires reconciliation:`, error.message);
    throw new Error(`Payment was sent but account confirmation is delayed. Contact support with reference: ${requestRef.id}`);
  }
  return { address: address.trim(), amount: formatAmount(sendAmount), faucetPayResponse: response,
    withdrawalId: requestRef.id, authUser: user };
}

// Idempotent settlement, also usable by a trusted operator after checking
// processor records. Never call with a guessed outcome for an unknown payment.
async function settleWithdrawal(id, outcome, response = null) {
  if (!['refunded', 'succeeded'].includes(outcome)) throw new Error('Invalid settlement outcome');
  const db = admin.firestore();
  const ref = db.collection('withdrawal_requests').doc(id);
  const result = await db.runTransaction(async transaction => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) throw new Error('Withdrawal not found');
    const request = snapshot.data();
    if (request.status === outcome) return null;
    if (['refunded', 'succeeded'].includes(request.status) ||
        (request.status === 'paid' && outcome === 'refunded')) throw new Error('Conflicting settlement');
    const userRef = db.collection('users').doc(request.uid);
    const user = await transaction.get(userRef);
    if (!user.exists) throw new Error('User not found');
    const data = user.data();
    const updates = {};
    if (data.pending_withdrawal === id) updates.pending_withdrawal = admin.firestore.FieldValue.delete();
    if (outcome === 'refunded') updates.doge_balance = Number(data.doge_balance || 0) + request.amount;
    else {
      updates.total_withdrawn = admin.firestore.FieldValue.increment(request.amount);
      transaction.set(db.collection('withdrawals').doc(id), {
        uid: request.uid, email: request.email, amount: request.amount, address: request.address,
        source: 'vault', timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.set(db.collection('transactions').doc(`withdrawal_${id}`), {
        uid: request.uid, amount: -request.amount, type: 'withdrawal',
        metadata: { address: request.address, faucetPayResponse: response || request.faucetPayResponse || {} },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    transaction.update(userRef, updates);
    transaction.update(ref, { status: outcome, settledAt: admin.firestore.FieldValue.serverTimestamp() });
    return { uid: request.uid, data, updates };
  });
  if (result) await syncUserBalances(result.uid, result.data, result.updates);
}

module.exports = { withdraw, settleWithdrawal };
