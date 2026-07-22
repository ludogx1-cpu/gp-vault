const express = require('express');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');

const router = express.Router();

function getPromoReward(rolledNumber) {
  if (rolledNumber >= 900) return 0.10;
  if (rolledNumber >= 800) return 0.09;
  if (rolledNumber >= 700) return 0.08;
  if (rolledNumber >= 600) return 0.07;
  if (rolledNumber >= 500) return 0.06;
  if (rolledNumber >= 400) return 0.05;
  if (rolledNumber >= 300) return 0.04;
  if (rolledNumber >= 200) return 0.03;
  if (rolledNumber >= 100) return 0.02;
  return 0.01;
}

// Endpoint to claim daily promo code
router.post('/claim-promo', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    const { code } = req.body;
    if (!code || typeof code !== 'string') {
      return res.status(400).json({ success: false, error: 'Invalid promo code' });
    }

    const uid = req.user.uid;
    const db = admin.firestore();

    // Get current active promo code
    const settingsDoc = await db.collection('system_settings').doc('promo').get();
    if (!settingsDoc.exists) {
      return res.status(400).json({ success: false, error: 'No active promo code found' });
    }

    const activePromo = settingsDoc.data();
    if (code.trim().toLowerCase() !== activePromo.code.toLowerCase()) {
      return res.status(400).json({ success: false, error: 'Incorrect promo code' });
    }

    // Check if user already claimed this specific code
    const userRef = db.collection('users').doc(uid);
    
    // We use a transaction to safely read/write the balance
    const result = await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      const userData = userDoc.data();
      if (userData.last_claimed_promo === activePromo.code) {
        throw new Error('You have already claimed this promo code!');
      }

      // Roll random number (1 to 999)
      const rolledNumber = Math.floor(Math.random() * 999) + 1;
      const reward = getPromoReward(rolledNumber);

      const currentBalance = userData.balance || 0;
      const newBalance = currentBalance + reward;
      
      const currentXp = userData.xp || 0;
      const newXp = currentXp + 50; // Add some XP as bonus

      transaction.update(userRef, {
        balance: newBalance,
        xp: newXp,
        last_claimed_promo: activePromo.code
      });

      return { rolledNumber, reward, xpReward: 50 };
    });

    res.json({
      success: true,
      rolledNumber: result.rolledNumber,
      rewardAmount: result.reward,
      xpReward: result.xpReward
    });
  } catch (error) {
    console.error('Promo claim error:', error);
    res.status(400).json({ success: false, error: error.message || 'Failed to claim promo code' });
  }
});

// Endpoint to subscribe FCM token to promo_updates topic
router.post('/subscribe-promo-topic', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, error: 'FCM token required' });
    }

    await admin.messaging().subscribeToTopic(token, 'promo_updates');
    
    res.json({ success: true, message: 'Subscribed to promo_updates topic' });
  } catch (error) {
    console.error('Subscribe topic error:', error);
    res.status(500).json({ success: false, error: 'Failed to subscribe to topic' });
  }
});

// Endpoint to subscribe FCM token to pet_reminders topic
router.post('/subscribe-pet-topic', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, error: 'FCM token required' });
    }

    await admin.messaging().subscribeToTopic(token, 'pet_reminders');
    
    res.json({ success: true, message: 'Subscribed to pet_reminders topic' });
  } catch (error) {
    console.error('Subscribe pet topic error:', error);
    res.status(500).json({ success: false, error: 'Failed to subscribe to pet_reminders topic' });
  }
});

module.exports = router;

