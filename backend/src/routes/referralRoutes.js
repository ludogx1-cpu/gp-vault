const express = require('express');
const rateLimit = require('express-rate-limit');
const { verifyFirebaseToken } = require('../services/firebaseService');
const referralService = require('../services/referralService');

const router = express.Router();

const claimLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: { success: false, error: 'Too many attempts. Please try again later.' },
});

router.post('/claim', claimLimiter, verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Please sign in first.' });
    const result = await referralService.claimReferral(req.user, req.body && req.body.code);
    res.json({ success: true, ...result });
  } catch (error) {
    const status = error.statusCode || 500;
    if (status === 500) console.error('Referral claim error:', error);
    res.status(status).json({ success: false, error: status === 500 ? 'Could not link the referral.' : error.message });
  }
});

router.get('/stats', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Please sign in first.' });
    res.json({ success: true, ...(await referralService.getReferralStats(req.user.uid)) });
  } catch (error) {
    console.error('Referral stats error:', error);
    res.status(500).json({ success: false, error: 'Could not load referral stats.' });
  }
});

module.exports = router;
