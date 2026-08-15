const express = require('express');
const { verifyFirebaseToken } = require('../services/firebaseService');
const faucetService = require('../services/faucetService');
const rateLimit = require('express-rate-limit');
const router = express.Router();

const faucetLimiter = rateLimit({
  windowMs: 60 * 1000, 
  max: 20,
  message: { success: false, error: 'Too many requests, please try again later.' }
});

router.post('/send-doge', faucetLimiter, verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required for faucet claim' });
    const { address: bodyAddress, user_address, captcha_token, captcha_provider, source } = req.body;
    const address = bodyAddress || user_address;
    
    const result = await faucetService.sendDoge(req.user, address, captcha_token, captcha_provider, source);
    res.json({ success: true, ...result });
  } catch (error) {
    console.error('send-doge error:', error.message);
    res.status(500).json({ success: false, error: error.message || 'Failed to send DOGE' });
  }
});

router.post('/claim-vault', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required for vault claim' });
    
    const result = await faucetService.claimVault(req.user);
    res.json({ success: true, message: 'Vault claim verified. Your reward has been recorded.', ...result });
  } catch (error) {
    console.error('claim-vault error:', error.message);
    res.status(error.statusCode || 500).json({ success: false, error: error.message || 'Failed to claim vault' });
  }
});

router.post('/withdraw', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required for withdrawal' });
    
    const result = await faucetService.withdraw(req.user, req.body.user_address, req.body.amount);
    res.json({ success: true, ...result });
  } catch (error) {
    console.error('withdraw error:', error.message);
    res.status(500).json({ success: false, error: error.message || 'Failed to process withdrawal' });
  }
});

router.post('/bank/withdraw', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required for bank withdrawal' });
    
    const result = await faucetService.bankWithdraw(req.user, req.body.user_address, req.body.amount);
    res.json({ success: true, ...result });
  } catch (error) {
    console.error('bank withdraw error:', error.message);
    res.status(403).json({ success: false, error: error.message || 'Failed to process bank withdrawal' });
  }
});

router.post('/bank/transfer', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    
    const message = await faucetService.bankTransfer(req.user, req.body.source, req.body.amount);
    res.json({ success: true, message });
  } catch (error) {
    console.error('bank transfer error:', error.message);
    res.status(500).json({ success: false, error: error.message || 'Failed to process internal transfer' });
  }
});

router.post('/claim-bonus-sponsor', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required for sponsor bonus claim' });
    
    const result = await faucetService.claimBonusSponsor(req.user, req.body.captcha_token, req.body.captcha_provider);
    res.json({ success: true, message: 'Sponsor bonus claim processed successfully', ...result });
  } catch (error) {
    console.error('claim-bonus-sponsor error:', error.message);
    res.status(error.statusCode || 500).json({ success: false, error: error.message || 'Failed to process sponsor bonus claim' });
  }
});

router.post('/claim-ecosystem-video', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required for ecosystem video claim' });
    
    const result = await faucetService.claimEcosystemVideo(req.user, req.body.captcha_token, req.body.captcha_provider);
    res.json({ success: true, message: 'Ecosystem video claim processed successfully', ...result });
  } catch (error) {
    console.error('claim-ecosystem-video error:', error.message);
    res.status(error.statusCode || 500).json({ success: false, error: error.message || 'Failed to process ecosystem video claim' });
  }
});

module.exports = router;
