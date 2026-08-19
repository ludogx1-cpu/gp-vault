const express = require('express');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');
const { formatAmount } = require('../utils/helpers');
const { syncUserBalances } = require('../utils/dataConnectSync');

const router = express.Router();

router.post('/swap-doge', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for swap' });
    }

    const { amount } = req.body;
    const swapAmount = Number(amount);
    if (!Number.isFinite(swapAmount) || swapAmount <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid swap amount' });
    }

    const { getDogePrice } = require('../services/priceService');
    const priceResult = await getDogePrice();
    const dogeUsdPrice = priceResult.price;
    const usdtValue = swapAmount * dogeUsdPrice;
    const finalUsdtCredit = usdtValue * 0.99; // 1% fee

    const userRef = admin.firestore().collection('users').doc(req.user.uid);

    const txResult = await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');

      const data = snapshot.data();
      const currentDogeBalance = Number(data.doge_balance || 0);

      if (currentDogeBalance < swapAmount) {
        throw new Error('Insufficient DOGE balance to swap');
      }

      const updates = {
        doge_balance: currentDogeBalance - swapAmount,
        ads_balance: Number(data.ads_balance || 0) + finalUsdtCredit
      };
      transaction.update(userRef, updates);
      return { data, updates };
    });

    if (txResult && txResult.data) {
      syncUserBalances(req.user.uid, txResult.data, txResult.updates).catch(console.error);
    }

    console.log('Swap DOGE request:', { user: req.user.uid, amount: swapAmount, credited: finalUsdtCredit });
    res.json({ success: true, message: 'Swap completed successfully', swappedAmount: formatAmount(swapAmount) });
  } catch (error) {
    console.error('swap-doge error:', error.message || error);
    res.status(500).json({ success: false, error: 'Failed to process DOGE swap' });
  }
});

router.post('/buy-banner', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for banner purchase' });
    }

    const { doc_id, image_url, target_url, pool } = req.body;
    if (!doc_id || !image_url || !target_url) {
      return res.status(400).json({ success: false, error: 'Missing required banner fields' });
    }

    const { getBannerCost } = require('../utils/helpers');
    const cost = getBannerCost(doc_id, pool);
    
    if (cost === null) {
      return res.status(400).json({ success: false, error: 'Invalid banner slot' });
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    const newBannerRef = admin.firestore().collection('banners').doc();

    const txResult = await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');

      const data = snapshot.data();
      const currentAdsBalance = Number(data.ads_balance || 0);

      if (currentAdsBalance < cost) {
        throw new Error(`Insufficient Ad Balance. Need $${cost} USDT`);
      }

      const updates = {
        ads_balance: currentAdsBalance - cost
      };
      transaction.update(userRef, updates);

      transaction.set(newBannerRef, {
        slot: doc_id,
        image_url,
        target_url,
        creator_uid: req.user.uid,
        status: 'active',
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });
      return { data, updates };
    });

    if (txResult && txResult.data) {
      syncUserBalances(req.user.uid, txResult.data, txResult.updates).catch(console.error);
    }

    console.log('Buy banner request successful:', { user: req.user.uid, doc_id, image_url, target_url, cost });
    res.json({ success: true, message: 'Banner campaign registered successfully' });
  } catch (error) {
    console.error('buy-banner error:', error.message || error);
    res.status(500).json({ success: false, error: 'Failed to process banner purchase' });
  }
});

module.exports = router;
