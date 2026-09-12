const express = require('express');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');

const { calculateDecay, getGrowthStage, getAgeMultiplier, MAX_STAT, calculatePetBonusPercent, getNextStageXP } = require('../utils/petMechanics');
const { getDogePrice } = require('../services/priceService');

const router = express.Router();

const FEED_COST_DOGE = 0.0001;
const PLAY_COST_DOGE = 0.0001;
const SLEEP_COST_DOGE = 0.0001;
const FEED_HUNGER_RECOVERY = 30;
const PLAY_ENERGY_COST = 15;
const PLAY_HAPPINESS_RECOVERY = 25;
const SLEEP_ENERGY_RECOVERY = 40;
const WALK_ENERGY_COST_PER_100M = 5;
const WALK_REWARD_PER_100M = 0.0005;

const petService = require('../services/petService');


function splitUpdates(updates) {
  const petUpdates = {};
  const userUpdates = {};
  for (const key in updates) {
    if (key.startsWith('pet_') || key === 'active_trick_buffs' || key === 'fetch_click_count' || key === 'weekly_time_above_40') {
      petUpdates[key] = updates[key];
    } else {
      userUpdates[key] = updates[key];
    }
  }
  return { userUpdates, petUpdates };
}
router.post('/pet-status', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petStatus(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-feed', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petFeed(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-play', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petPlay(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-sleep', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petSleep(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-stroke', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petStroke(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-walk-sync', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petWalkSync(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-clean-poo', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petCleanPoo(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-boop', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petBoop(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-rename', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petRename(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-admin-age-up', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petAdminAgeUp(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;


router.post('/pet-buy-accessory', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petBuyAccessory(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-equip-accessory', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petEquipAccessory(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-buy-trick', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petBuyTrick(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-trick', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petTrick(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-buy-consumable', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petBuyConsumable(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-use-consumable', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petUseConsumable(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-buy-ball', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petBuyBall(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-equip-ball', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petEquipBall(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

router.post('/pet-fetch', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    const result = await petService.petFetch(req);
    res.json(result);
  } catch (error) {
    res.status(400).json({ success: false, error: error.message || error });
  }
});
;

module.exports = router;

