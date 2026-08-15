const express = require('express');
const { verifyFirebaseToken } = require('../services/firebaseService');
const stakingService = require('../services/stakingService');

const router = express.Router();

router.post('/stake', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    
    const message = await stakingService.stake(req.user, req.body.amount);
    res.json({ success: true, message });
  } catch (error) {
    console.error('Stake error:', error.message);
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/unstake', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    
    const message = await stakingService.unstake(req.user, req.body.amount);
    res.json({ success: true, message });
  } catch (error) {
    console.error('Unstake error:', error.message);
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/harvest', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    
    const harvestedAmount = await stakingService.harvest(req.user);
    res.json({ success: true, message: 'Successfully Harvested Interest!', harvestedAmount });
  } catch (error) {
    console.error('Harvest error:', error.message);
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;
