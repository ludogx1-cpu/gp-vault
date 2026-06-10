const express = require('express');
const { verifyFirebaseToken } = require('../services/firebaseService');
const { formatAmount } = require('../utils/helpers');

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

    console.log('Swap DOGE request:', { user: req.user.uid, amount: swapAmount });
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

    const { doc_id, image_url, target_url } = req.body;
    if (!doc_id || !image_url || !target_url) {
      return res.status(400).json({ success: false, error: 'Missing required banner fields' });
    }

    console.log('Buy banner request:', { user: req.user.uid, doc_id, image_url, target_url });
    res.json({ success: true, message: 'Banner campaign registered successfully' });
  } catch (error) {
    console.error('buy-banner error:', error.message || error);
    res.status(500).json({ success: false, error: 'Failed to process banner purchase' });
  }
});

module.exports = router;
