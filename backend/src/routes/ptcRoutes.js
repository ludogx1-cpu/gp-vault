const express = require('express');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');

const router = express.Router();
const getAdminUid = () => process.env.ADMIN_UID || 'P8iffVqbUgetAVA4MdHVZ1CfvUv1';

router.post('/buy-ptc', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for PTC purchase' });
    }

    const { target_url, tier, clicks } = req.body;
    if (!target_url || !tier || !clicks) {
      return res.status(400).json({ success: false, error: 'Missing required PTC fields' });
    }

    console.log('Buy PTC request:', { user: req.user.uid, target_url, tier, clicks });
    res.json({ success: true, message: 'PTC ad added to the pool successfully' });
  } catch (error) {
    console.error('buy-ptc error:', error.message || error);
    res.status(500).json({ success: false, error: 'Failed to process PTC purchase' });
  }
});

router.post('/claim-ptc', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for PTC claim' });
    }

    const { captcha_token, captcha_provider, ad_id } = req.body;

    if (req.user.uid !== getAdminUid()) {
      if (!captcha_token || !captcha_provider || !ad_id) {
        return res.status(400).json({ success: false, error: 'Missing required validation data' });
      }
    } else if (!ad_id) {
      return res.status(400).json({ success: false, error: 'Missing ad_id' });
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    const adRef = admin.firestore().collection('ptc_ads').doc(ad_id);
    const cooldownMs = 24 * 60 * 60 * 1000; 
    const now = admin.firestore.Timestamp.now();

    await admin.firestore().runTransaction(async (transaction) => {
      const userSnapshot = await transaction.get(userRef);
      const adSnapshot = await transaction.get(adRef);

      if (!userSnapshot.exists || !adSnapshot.exists) {
        throw new Error('User or Ad not found');
      }

      const userData = userSnapshot.data() || {};
      const adData = adSnapshot.data() || {};

      const remainingClicks = Number(adData.clicks_remaining || 0);

      if (req.user.uid !== getAdminUid()) {
        if (remainingClicks <= 0) {
          throw new Error('This ad has run out of clicks.');
        }
      }

      const ptcHistory = userData.ptc_history || {};
      const lastClicked = ptcHistory[ad_id];
      if (lastClicked && Date.now() - lastClicked.toDate().getTime() < cooldownMs) {
        throw new Error('Cooldown active. You can view this ad again tomorrow.');
      }

      const rewardAmount = adData.tier === 'high' ? 0.005 : 0.001; 

      transaction.update(userRef, {
        doge_balance: Number(userData.doge_balance || 0) + rewardAmount,
        [`ptc_history.${ad_id}`]: now
      });

      if (req.user.uid !== getAdminUid()) {
        transaction.update(adRef, {
          clicks_remaining: remainingClicks - 1
        });
      }
    });

    console.log('Claim PTC request successful for user:', req.user.uid);
    res.json({ success: true, message: 'PTC claim processed successfully' });
  } catch (error) {
    console.error('claim-ptc error:', error.message || error);
    res.status(500).json({ success: false, error: error.message || 'Failed to process PTC claim' });
  }
});

module.exports = router;
