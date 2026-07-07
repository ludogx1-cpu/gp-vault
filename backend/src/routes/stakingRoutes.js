const express = require('express');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');

const router = express.Router();

const APY = 0.085;
const SECONDS_PER_YEAR = 31536000;

function calculatePendingInterest(stakedBalance, stakeTimestamp) {
  if (!stakedBalance || stakedBalance <= 0 || !stakeTimestamp) return 0.0;
  const now = Date.now();
  const stakeTimeMs = stakeTimestamp.toDate().getTime();
  const secondsPassed = Math.floor((now - stakeTimeMs) / 1000);
  if (secondsPassed <= 0) return 0.0;
  
  return stakedBalance * (APY / SECONDS_PER_YEAR) * secondsPassed;
}

router.post('/stake', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    
    const { amount } = req.body;
    const amountToStake = Number(amount);
    if (!Number.isFinite(amountToStake) || amountToStake <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid stake amount' });
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStakedBalance = 0;

    await admin.firestore().runTransaction(async (transaction) => {
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

      transaction.update(userRef, {
        doge_balance: currentBalance - amountToStake,
        staked_balance: newStakedBalance,
        stake_timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    res.json({ success: true, message: `Successfully staked ${amountToStake} DOGE` });
  } catch (error) {
    console.error('Stake error:', error.message);
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/unstake', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    
    const { amount } = req.body;
    const amountToUnstake = Number(amount);
    if (!Number.isFinite(amountToUnstake) || amountToUnstake <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid unstake amount' });
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);

    await admin.firestore().runTransaction(async (transaction) => {
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
      currentBalance += pendingInterest; 

      transaction.update(userRef, {
        doge_balance: currentBalance + amountToUnstake,
        staked_balance: currentStaked - amountToUnstake,
        stake_timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    res.json({ success: true, message: `Successfully unstaked ${amountToUnstake} DOGE` });
  } catch (error) {
    console.error('Unstake error:', error.message);
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/harvest', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let harvested = 0;

    await admin.firestore().runTransaction(async (transaction) => {
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

      transaction.update(userRef, {
        doge_balance: currentBalance + harvested,
        stake_timestamp: admin.firestore.FieldValue.serverTimestamp(),
        reward_history: history
      });
    });

    res.json({ success: true, message: 'Successfully Harvested Interest!', harvestedAmount: harvested });
  } catch (error) {
    console.error('Harvest error:', error.message);
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;
