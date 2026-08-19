const { admin } = require('./firebaseService');
const { calculatePendingInterest } = require('../utils/stakingMath');
const { logTransaction } = require('./ledgerService');
const { logRewardEvent } = require('../utils/rewardAudit');
const { syncUserBalances } = require('../utils/dataConnectSync');

async function stake(user, amount) {
  const amountToStake = Number(amount);
  if (!Number.isFinite(amountToStake) || amountToStake <= 0) {
    throw new Error('Invalid stake amount');
  }

  const userRef = admin.firestore().collection('users').doc(user.uid);
  let newStakedBalance = 0;

  const txResult = await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) throw new Error('User not found');
    
    const data = snapshot.data();
    let currentBalance = Number(data.doge_balance || 0);
    const currentStaked = Number(data.staked_balance || 0);
    const stakeTime = data.stake_timestamp;

    const pendingInterest = calculatePendingInterest(currentStaked, stakeTime);
    currentBalance += pendingInterest; // Add pending interest to available balance before staking

    if (currentBalance < amountToStake) {
      throw new Error('Not enough DOGE in your Available Balance');
    }

    newStakedBalance = currentStaked + amountToStake;

    const updates = {
      doge_balance: currentBalance - amountToStake,
      staked_balance: newStakedBalance,
      stake_timestamp: admin.firestore.FieldValue.serverTimestamp()
    };
    transaction.update(userRef, updates);
    logTransaction(transaction, user.uid, amountToStake, 'stake', {});
    return { data, updates };
  });

  if (txResult) syncUserBalances(user.uid, txResult.data, txResult.updates).catch(console.error);

  return `Successfully staked ${amountToStake} DOGE`;
}

async function unstake(user, amount) {
  const amountToUnstake = Number(amount);
  if (!Number.isFinite(amountToUnstake) || amountToUnstake <= 0) {
    throw new Error('Invalid unstake amount');
  }

  const userRef = admin.firestore().collection('users').doc(user.uid);
  let finalPendingInterest = 0;

  const txResult = await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) throw new Error('User not found');
    
    const data = snapshot.data();
    let currentBalance = Number(data.doge_balance || 0);
    const currentStaked = Number(data.staked_balance || 0);
    const stakeTime = data.stake_timestamp;

    if (currentStaked < amountToUnstake) {
      throw new Error('Not enough Staked DOGE to unstake');
    }

    const pendingInterest = calculatePendingInterest(currentStaked, stakeTime);
    finalPendingInterest = pendingInterest;
    currentBalance += pendingInterest; 

    const updates = {
      doge_balance: currentBalance + amountToUnstake,
      staked_balance: currentStaked - amountToUnstake,
      stake_timestamp: admin.firestore.FieldValue.serverTimestamp()
    };
    transaction.update(userRef, updates);
    logTransaction(transaction, user.uid, amountToUnstake, 'unstake', {});
    if (pendingInterest > 0) {
      logTransaction(transaction, user.uid, pendingInterest, 'stake_harvest', { type: 'auto_harvest' });
    }
    return { data, updates };
  });

  if (txResult) syncUserBalances(user.uid, txResult.data, txResult.updates).catch(console.error);

  if (finalPendingInterest > 0) {
    await logRewardEvent(user.uid, 'staking_yield', finalPendingInterest, { type: 'auto_harvest' });
  }

  return `Successfully unstaked ${amountToUnstake} DOGE`;
}

async function harvest(user) {
  const userRef = admin.firestore().collection('users').doc(user.uid);
  let harvested = 0;

  const txResult = await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) throw new Error('User not found');
    
    const data = snapshot.data();
    let currentBalance = Number(data.doge_balance || 0);
    const currentStaked = Number(data.staked_balance || 0);
    const stakeTime = data.stake_timestamp;

    harvested = calculatePendingInterest(currentStaked, stakeTime);
    if (harvested <= 0) {
      throw new Error('No interest to harvest yet!');
    }

    let history = data.reward_history || [];
    history.unshift({ sector: 'Staking Harvest', amount: harvested, timestamp: Date.now() });
    if (history.length > 15) history = history.slice(0, 15);

    const updates = {
      doge_balance: currentBalance + harvested,
      stake_timestamp: admin.firestore.FieldValue.serverTimestamp(),
      reward_history: history
    };
    transaction.update(userRef, updates);
    logTransaction(transaction, user.uid, harvested, 'stake_harvest', { type: 'manual_harvest' });
    return { data, updates };
  });

  if (txResult) syncUserBalances(user.uid, txResult.data, txResult.updates).catch(console.error);

  await logRewardEvent(user.uid, 'staking_yield', harvested, { type: 'manual_harvest' });

  return harvested;
}

module.exports = {
  stake,
  unstake,
  harvest
};
