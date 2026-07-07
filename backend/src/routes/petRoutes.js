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

function processInvestments(userRef, data, transaction) {
  const currentInvestments = data.pet_investments || [];
  const now = Date.now();
  let matureAmount = 0;
  const remainingInvestments = [];
  let lockedAmount = 0;

  currentInvestments.forEach(inv => {
    if (now >= inv.unlock_time) {
      matureAmount += inv.amount;
    } else {
      remainingInvestments.push(inv);
      lockedAmount += inv.amount;
    }
  });

  const updates = {};
  if (currentInvestments.length !== remainingInvestments.length) {
    updates.pet_investments = remainingInvestments;
  }
  if (matureAmount > 0) {
    updates.doge_balance = Number(data.doge_balance || 0) + matureAmount;
  }
  
  if (Object.keys(updates).length > 0) {
    transaction.update(userRef, updates);
  }

  return { matured: matureAmount, locked: lockedAmount, remainingInvestments };
}

function ensureXP(data) {
  if (data.pet_xp !== undefined) return Number(data.pet_xp);
  if (!data.pet_birth_date) return 0;
  const daysOld = (Date.now() - data.pet_birth_date.toDate().getTime()) / (1000 * 60 * 60 * 24);
  if (daysOld < 2) return 0;
  if (daysOld < 7) return 100;
  if (daysOld < 14) return 300;
  if (daysOld < 30) return 700;
  if (daysOld < 90) return 1500;
  if (daysOld < 180) return 3000;
  if (daysOld < 365) return 6000;
  return 10000;
}

function calculateXPGain(data, baseXP) {
  if (data.xp_boost_expires_at && data.xp_boost_expires_at.toDate().getTime() > Date.now()) {
    return Math.floor(baseXP * 1.5);
  }
  return baseXP;
}

router.post('/pet-status', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    
    let petStats = null;
    let maturedThisTime = 0;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');

      const data = snapshot.data() || {};
      
      const { matured, locked } = processInvestments(userRef, data, transaction);
      maturedThisTime = matured;
      
      // Initialize pet if doesn't exist
      if (!data.pet_birth_date) {
        const initData = {
          pet_birth_date: admin.firestore.FieldValue.serverTimestamp(),
          pet_xp: 0,
          pet_hunger: 50,
          pet_happiness: 50,
          pet_attention: 50,
          pet_energy: 100,
          pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
          pet_total_distance_walked: 0,
          pet_investments: []
        };
        transaction.update(userRef, initData);
        petStats = {
          hunger: 50,
          happiness: 50,
          attention: 50,
          energy: 100,
          stage: 'puppy',
          xp: 0,
          next_stage_xp: getNextStageXP('puppy'),
          total_distance: 0,
          locked_returns: 0,
          matured_returns: 0,
          sleeping_until: 0
        };
      } else {
        const decayed = calculateDecay(data);
        
        if (decayed.hoursPassed > 30 * 24) {
          // Reset pet completely due to 1-month inactivity
          const initData = {
            pet_birth_date: admin.firestore.FieldValue.serverTimestamp(),
            pet_hunger: 50,
            pet_happiness: 50,
            pet_attention: 50,
            pet_energy: 100,
            pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
            pet_total_distance_walked: 0,
            pet_investments: [],
            pet_owned_accessories: [],
            pet_equipped_accessories: [],
            pet_owned_tricks: [],
            active_trick_buffs: [],
            pet_owned_balls: ['white'],
            pet_equipped_ball: 'white',
            fetch_click_count: 0
          };
          transaction.update(userRef, initData);
          petStats = {
            hunger: 50,
            happiness: 50,
            attention: 50,
            energy: 100,
            stage: 'puppy',
            total_distance: 0,
            locked_returns: 0,
            matured_returns: 0,
            pending_poos: 0,
            age_multiplier: 1.0,
            name: data.pet_name || 'Golden Paw Shiba',
            owned_accessories: [],
            equipped_accessories: [],
            owned_tricks: [],
            owned_consumables: {},
            sick: false,
            xp_boost_active: false,
            owned_balls: ['white'],
            equipped_ball: 'white',
            fetch_click_count: 0,
            sleeping_until: 0
          };
          // Return immediately with new stats
          return;
        }

        // Clean up expired trick buffs
        let activeBuffs = data.active_trick_buffs || [];
        const now = Date.now();
        const validBuffs = activeBuffs.filter(b => typeof b === 'object' && b.expiresAt >= now);

        const currentXP = ensureXP(data);
        const stage = getGrowthStage({ ...data, pet_xp: currentXP });

        // Sickness Tracking
        let isSick = data.pet_sick || false;
        let sickSince = data.pet_sick_since ? data.pet_sick_since.toDate().getTime() : null;

        if (decayed.hunger === 0 || decayed.happiness === 0 || decayed.energy === 0) {
          if (!sickSince) {
            sickSince = now;
          } else if (!isSick && (now - sickSince >= 72 * 60 * 60 * 1000)) {
            isSick = true;
          }
        } else {
          // Stats are not 0
          if (sickSince && !isSick) {
            sickSince = null; // Stats recovered before 24h passed
          }
        }

        const updatePayload = {
          pet_xp: currentXP,
          pet_hunger: decayed.hunger,
          pet_happiness: decayed.happiness,
          pet_attention: decayed.attention,
          pet_energy: decayed.energy,
          active_trick_buffs: validBuffs,
          pet_last_interaction: admin.firestore.FieldValue.serverTimestamp()
        };

        if (sickSince !== null && !data.pet_sick_since) {
           updatePayload.pet_sick_since = admin.firestore.Timestamp.fromMillis(sickSince);
        } else if (sickSince === null && data.pet_sick_since) {
           updatePayload.pet_sick_since = null;
        }
        if (isSick !== data.pet_sick) {
           updatePayload.pet_sick = isSick;
        }

        if (data.pending_sleep_reward && data.pet_sleeping_until && data.pet_sleeping_until.toDate().getTime() <= now) {
          updatePayload.pending_sleep_reward = admin.firestore.FieldValue.delete();
          updatePayload.doge_balance = Number(data.doge_balance || 0) + 0.0001;
        }

        // Update DB with decayed stats and clean buffs
        transaction.update(userRef, updatePayload);

        let pendingPoos = 0;
        if (data.pet_last_poo_time) {
          const currentHour = Math.floor(Date.now() / 3600000);
          const lastPooHour = Math.floor(data.pet_last_poo_time.toDate().getTime() / 3600000);
          pendingPoos = Math.max(0, Math.min(4, currentHour - lastPooHour)); // 1 poo on the hour, max 4
        } else {
          // If no last poo time, initialize it
          transaction.update(userRef, { pet_last_poo_time: admin.firestore.FieldValue.serverTimestamp() });
        }

        petStats = {
          hunger: decayed.hunger,
          happiness: decayed.happiness,
          attention: decayed.attention,
          energy: decayed.energy,
          stage: stage,
          xp: currentXP,
          next_stage_xp: getNextStageXP(stage),
          age_multiplier: getAgeMultiplier({ ...data, pet_xp: currentXP }),
          total_distance: data.pet_total_distance_walked || 0,
          pending_poos: pendingPoos,
          locked_returns: locked,
          matured_returns: matured,
          last_boop_time: data.pet_last_boop_time ? data.pet_last_boop_time.toDate().getTime() : 0,
          last_feed_time: data.pet_last_feed_time ? data.pet_last_feed_time.toDate().getTime() : 0,
          last_play_time: data.pet_last_play_time ? data.pet_last_play_time.toDate().getTime() : 0,
          last_sleep_time: data.pet_last_sleep_time ? data.pet_last_sleep_time.toDate().getTime() : 0,
          last_walk_time: data.pet_last_walk_sync ? data.pet_last_walk_sync.toDate().getTime() : 0,
          name: data.pet_name || 'Golden Paw Shiba',
          owned_accessories: data.pet_owned_accessories || [],
          equipped_accessories: data.pet_equipped_accessories || [],
          owned_tricks: data.pet_owned_tricks || [],
          owned_consumables: data.pet_owned_consumables || {},
          sick: isSick,
          xp_boost_active: data.xp_boost_expires_at ? data.xp_boost_expires_at.toDate().getTime() > Date.now() : false,
          owned_balls: data.pet_owned_balls || ['white'],
          equipped_ball: data.pet_equipped_ball || 'white',
          fetch_click_count: data.fetch_click_count || 0,
          sleeping_until: data.pet_sleeping_until ? data.pet_sleeping_until.toDate().getTime() : 0
        };
      }
    });

    res.json({ success: true, pet: petStats });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/pet-feed', verifyFirebaseToken, async (req, res) => {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const decayed = calculateDecay(data);
      if (decayed.hunger >= MAX_STAT) throw new Error('Pet is already full!');
      if (data.pet_last_feed_time && (Date.now() - data.pet_last_feed_time.toDate().getTime()) < 5 * 60 * 60 * 1000) {
        throw new Error('You can only feed your pet once every 5 hours!');
      }

      const { matured, remainingInvestments } = processInvestments(userRef, data, transaction);
      const currentDoge = Number(data.doge_balance || 0) + matured;

      if (currentDoge < FEED_COST_DOGE) throw new Error(`Insufficient DOGE. Costs ${FEED_COST_DOGE} DOGE to feed.`);

      const petBonus = calculatePetBonusPercent(decayed, data);
      const investmentAmount = (FEED_COST_DOGE * 2) * (1 + (petBonus / 100));
      const newHunger = MAX_STAT;
      remainingInvestments.push({ amount: investmentAmount, unlock_time: Date.now() + 24 * 60 * 60 * 1000 });

      const currentXP = ensureXP(data);
      const newXP = currentXP + calculateXPGain(data, 20);

      transaction.update(userRef, {
        doge_balance: currentDoge - FEED_COST_DOGE,
        pet_xp: newXP,
        pet_hunger: newHunger,
        pet_happiness: decayed.happiness,
        pet_energy: decayed.energy,
        pet_investments: remainingInvestments,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_feed_time: admin.firestore.FieldValue.serverTimestamp()
      });

      newStats = { hunger: newHunger, happiness: decayed.happiness, energy: decayed.energy, cost: FEED_COST_DOGE, xp: newXP };
    });

    res.json({ success: true, message: 'Fed the pet!', stats: newStats });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-play', verifyFirebaseToken, async (req, res) => {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const decayed = calculateDecay(data);
      if (decayed.happiness >= MAX_STAT) throw new Error('Pet is already at max happiness!');
      if (data.pet_last_play_time && (Date.now() - data.pet_last_play_time.toDate().getTime()) < 5 * 60 * 60 * 1000) {
        throw new Error('You can only play with your pet once every 5 hours!');
      }

      const { matured, remainingInvestments } = processInvestments(userRef, data, transaction);
      const currentDoge = Number(data.doge_balance || 0) + matured;

      if (currentDoge < PLAY_COST_DOGE) throw new Error(`Insufficient DOGE. Costs ${PLAY_COST_DOGE} DOGE to play.`);

      const petBonus = calculatePetBonusPercent(decayed, data);
      const investmentAmount = (PLAY_COST_DOGE * 2) * (1 + (petBonus / 100));
      const newHappiness = MAX_STAT;
      remainingInvestments.push({ amount: investmentAmount, unlock_time: Date.now() + 24 * 60 * 60 * 1000 });

      const currentXP = ensureXP(data);
      const newXP = currentXP + calculateXPGain(data, 20);

      transaction.update(userRef, {
        doge_balance: currentDoge - PLAY_COST_DOGE,
        pet_xp: newXP,
        pet_hunger: decayed.hunger,
        pet_happiness: newHappiness,
        pet_energy: decayed.energy,
        pet_investments: remainingInvestments,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_play_time: admin.firestore.FieldValue.serverTimestamp()
      });

      newStats = { hunger: decayed.hunger, happiness: newHappiness, energy: decayed.energy, xp: newXP };
    });

    res.json({ success: true, message: 'Played with pet!', stats: newStats });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-sleep', verifyFirebaseToken, async (req, res) => {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const decayed = calculateDecay(data);
      if (decayed.energy >= MAX_STAT) throw new Error('Pet is not tired.');
      if (data.pet_sleeping_until && data.pet_sleeping_until.toDate().getTime() > Date.now()) {
        throw new Error('Pet is already sleeping!');
      }

      const { matured, remainingInvestments } = processInvestments(userRef, data, transaction);
      const currentDoge = Number(data.doge_balance || 0) + matured;

      const newEnergy = Math.min(MAX_STAT, decayed.energy + 50);

      const currentXP = ensureXP(data);
      const newXP = currentXP + calculateXPGain(data, 20);

      transaction.update(userRef, {
        doge_balance: currentDoge,
        pet_xp: newXP,
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_attention: decayed.attention,
        pet_energy: newEnergy,
        pet_investments: remainingInvestments,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_sleep_time: admin.firestore.FieldValue.serverTimestamp(),
        pet_sleeping_until: admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
        pending_sleep_reward: true
      });

      newStats = { hunger: decayed.hunger, happiness: decayed.happiness, attention: decayed.attention, energy: newEnergy, xp: newXP };
    });

    res.json({ success: true, message: 'Pet took a nap! Zzz...', stats: newStats });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-stroke', verifyFirebaseToken, async (req, res) => {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      if (data.pet_sleeping_until && data.pet_sleeping_until.toDate().getTime() > Date.now()) {
        throw new Error('Shh... The pet is sleeping!');
      }

      const decayed = calculateDecay(data);
      if (decayed.attention >= MAX_STAT) throw new Error('Pet has full attention already!');

      const newAttention = Math.min(MAX_STAT, decayed.attention + 20);
      const currentXP = ensureXP(data);
      const newXP = currentXP + calculateXPGain(data, 5);

      transaction.update(userRef, {
        pet_xp: newXP,
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_attention: newAttention,
        pet_energy: decayed.energy,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp()
      });

      newStats = { hunger: decayed.hunger, happiness: decayed.happiness, attention: newAttention, energy: decayed.energy, xp: newXP };
    });

    res.json({ success: true, message: 'You stroked the pet!', stats: newStats });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-walk-sync', verifyFirebaseToken, async (req, res) => {
  try {
    const { distance_meters } = req.body;
    if (!distance_meters || distance_meters <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid distance' });
    }

    const maxValidMeters = 1000;
    const validMeters = Math.min(distance_meters, maxValidMeters); 

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let result = null;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');
      if (data.pet_sick) throw new Error('Your pet is too sick to go for a walk! Buy medicine from the shop.');

      // Exploit protection
      const now = Date.now();
      const lastSync = data.pet_last_walk_sync ? data.pet_last_walk_sync.toDate().getTime() : 0;
      const timeSinceLastSync = now - lastSync;
      
      // Require 3-hour cooldown between walks
      const COOLDOWN_MS = 3 * 60 * 60 * 1000;
      if (timeSinceLastSync < COOLDOWN_MS) {
        throw new Error('Your pet is resting. You can only go for a walk once every 3 hours!');
      }

      const validMeters = Math.min(distance_meters, 1000);

      const decayed = calculateDecay(data);
      
      const energyCost = (validMeters / 100) * WALK_ENERGY_COST_PER_100M;
      if (decayed.energy < energyCost) {
        throw new Error('Pet is too tired to walk that far!');
      }

      const currentXP = ensureXP(data);
      const ageMult = getAgeMultiplier({ ...data, pet_xp: currentXP });
      const baseReward = (validMeters / 100) * WALK_REWARD_PER_100M;
      const dogeReward = baseReward * ageMult;
      
      const newDogeBal = Number(data.doge_balance || 0) + dogeReward;
      const newTotalDist = Number(data.pet_total_distance_walked || 0) + validMeters;
      const newEnergy = decayed.energy - energyCost;
      const xpGained = calculateXPGain(data, Math.floor(validMeters / 10));
      const newXP = currentXP + xpGained;

      transaction.update(userRef, {
        doge_balance: newDogeBal,
        pet_xp: newXP,
        pet_energy: newEnergy,
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_total_distance_walked: newTotalDist,
        pet_last_walk_sync: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp()
      });

      result = { reward: dogeReward, distance: validMeters, total_distance: newTotalDist, energy: newEnergy, xp: newXP, xp_gained: xpGained };
    });

    res.json({ success: true, message: 'Walk synced', ...result });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-clean-poo', verifyFirebaseToken, async (req, res) => {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let reward = 0.00025;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const lastPooTime = data.pet_last_poo_time;
      if (!lastPooTime) throw new Error('No poos to clean right now!');

      const currentHour = Math.floor(Date.now() / 3600000);
      const lastPooHour = Math.floor(lastPooTime.toDate().getTime() / 3600000);
      let pendingPoos = currentHour - lastPooHour;
      
      if (pendingPoos <= 0) {
        throw new Error('No poos to clean right now! Wait a bit.');
      }

      pendingPoos = Math.min(4, pendingPoos);
      let effectiveLastPooHour = pendingPoos === 4 ? (currentHour - 4) : lastPooHour;
      
      // Advance by 1 hour boundary
      let newLastPooHour = effectiveLastPooHour + 1;
      let newLastPooTimeMs = newLastPooHour * 3600000;

      const newDogeBal = Number(data.doge_balance || 0) + reward;

      let history = data.reward_history || [];
      history.unshift({ sector: 'Pet Care (Poo)', amount: reward, timestamp: Date.now() });
      if (history.length > 15) history = history.slice(0, 15);

      const currentXP = ensureXP(data);
      const newXP = currentXP + calculateXPGain(data, 10);

      transaction.update(userRef, {
        doge_balance: newDogeBal,
        pet_xp: newXP,
        pet_last_poo_time: admin.firestore.Timestamp.fromMillis(newLastPooTimeMs),
        reward_history: history
      });
    });

    res.json({ success: true, message: 'Cleaned up poo!', reward });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-boop', verifyFirebaseToken, async (req, res) => {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let reward = 0.004;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      if (data.pet_last_boop_time) {
        const currentHalfHour = Math.floor(Date.now() / 1800000);
        const lastBoopHalfHour = Math.floor(data.pet_last_boop_time.toDate().getTime() / 1800000);
        if (currentHalfHour <= lastBoopHalfHour) {
          throw new Error('Pet is not ready for a boop right now. Wait a bit!');
        }
      }

      const newDogeBal = Number(data.doge_balance || 0) + reward;

      let history = data.reward_history || [];
      history.unshift({ sector: 'Pet Care (Boop)', amount: reward, timestamp: Date.now() });
      if (history.length > 15) history = history.slice(0, 15);

      const currentXP = ensureXP(data);
      const newXP = currentXP + calculateXPGain(data, 5);

      transaction.update(userRef, {
        doge_balance: newDogeBal,
        pet_xp: newXP,
        pet_last_boop_time: admin.firestore.FieldValue.serverTimestamp(),
        reward_history: history
      });
    });

    res.json({ success: true, message: 'Boop! You found a reward!', reward });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-rename', verifyFirebaseToken, async (req, res) => {
  try {
    const { newName } = req.body;
    if (!newName || newName.length > 20) {
      throw new Error('Name must be 1-20 characters long.');
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    await userRef.update({
      pet_name: newName
    });

    res.json({ success: true, message: 'Pet renamed successfully!' });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-admin-age-up', verifyFirebaseToken, async (req, res) => {
  try {
    // Basic admin check (could use custom claims, but hardcoding email is consistent with the frontend for now)
    const userRecord = await admin.auth().getUser(req.user.uid);
    if (userRecord.email !== 'ludogx1@gmail.com') {
      return res.status(403).json({ success: false, error: 'Admin only' });
    }

    const { days = 30 } = req.body;
    const daysNumber = Number(days);

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      // Subtract days from birth date to age it up (or negative to age down)
      const oldBirthTime = data.pet_birth_date.toDate().getTime();
      const newBirthTime = oldBirthTime - (daysNumber * 24 * 60 * 60 * 1000);
      
      transaction.update(userRef, {
        pet_birth_date: admin.firestore.Timestamp.fromMillis(newBirthTime)
      });
    });

    res.json({ success: true, message: `Aged by ${daysNumber} days!` });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

const ACCESSORY_PRICES_USDT = {
  'top_hat': 1.0,
  'sunglasses': 2.0,
  'gold_chain': 3.0,
  'diamond_watch': 5.0,
  'crown': 10.0,
  'coat_basic': 1.5,
  'coat_rain': 2.5,
  'coat_winter': 4.0,
  'coat_luxury': 7.5
};

const ACCESSORY_PRICES_DOGE = {
  'top_hat': 8.0,
  'sunglasses': 16.0,
  'gold_chain': 24.0,
  'diamond_watch': 40.0,
  'crown': 80.0,
  'coat_basic': 12.0,
  'coat_rain': 20.0,
  'coat_winter': 32.0,
  'coat_luxury': 60.0
};

const TRICK_PRICES_USDT = {
  'Spin': 1.0,
  'Jump': 2.0,
  'Roll Over': 3.0,
  'Backflip': 5.0,
  'Moonwalk': 10.0
};

const TRICK_PRICES_DOGE = {
  'Spin': 8.0,
  'Jump': 16.0,
  'Roll Over': 24.0,
  'Backflip': 40.0,
  'Moonwalk': 80.0
};

const CONSUMABLE_PRICES_USDT = {
  'medicine': 0.0,
  'basic_kibble': 0.01
};

const CONSUMABLE_PRICES_DOGE = {
  'medicine': 0.0,
  'basic_kibble': 0.08
};

router.post('/pet-buy-accessory', verifyFirebaseToken, async (req, res) => {
  try {
    const { accessoryId, currency = 'usdt' } = req.body;
    
    if (currency === 'usdt' && !ACCESSORY_PRICES_USDT[accessoryId]) throw new Error('Invalid accessory');
    if (currency === 'doge' && !ACCESSORY_PRICES_DOGE[accessoryId]) throw new Error('Invalid accessory');

    const cost = currency === 'usdt' ? ACCESSORY_PRICES_USDT[accessoryId] : ACCESSORY_PRICES_DOGE[accessoryId];

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      if (!data.pet_birth_date) throw new Error('Pet not initialized');
      if (getGrowthStage(data) === 'egg') throw new Error('Pets in the egg stage cannot use the shop.');

      if (currency === 'usdt') {
        const currentAdsBalance = Number(data.ads_balance || 0);
        if (currentAdsBalance < cost) throw new Error(`Insufficient Ad Credit. Costs $${cost.toFixed(2)} USDT.`);
      } else if (currency === 'doge') {
        const currentDogeBalance = Number(data.doge_balance || 0);
        if (currentDogeBalance < cost) throw new Error(`Insufficient Balance. Costs ${cost.toFixed(2)} DOGE.`);
      }

      const owned = data.pet_owned_accessories || [];
      if (owned.includes(accessoryId)) throw new Error('You already own this accessory!');

      owned.push(accessoryId);

      const updates = {
        pet_owned_accessories: owned
      };

      if (currency === 'usdt') {
        updates.ads_balance = Number(data.ads_balance || 0) - cost;
      } else {
        updates.doge_balance = Number(data.doge_balance || 0) - cost;
      }

      transaction.update(userRef, updates);
    });

    const msg = currency === 'usdt' ? `Accessory purchased for $${cost.toFixed(2)} USDT!` : `Accessory purchased for ${cost.toFixed(2)} DOGE!`;
    res.json({ success: true, message: msg });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-equip-accessory', verifyFirebaseToken, async (req, res) => {
  try {
    const { accessoryId, equip } = req.body; // equip boolean
    const userRef = admin.firestore().collection('users').doc(req.user.uid);

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      if (!data.pet_birth_date) throw new Error('Pet not initialized');
      if (getGrowthStage(data) === 'egg') throw new Error('Pets in the egg stage cannot use the shop.');

      const owned = data.pet_owned_accessories || [];
      if (equip && !owned.includes(accessoryId)) throw new Error('You do not own this accessory.');

      let equipped = data.pet_equipped_accessories || [];
      if (equip && !equipped.includes(accessoryId)) {
        equipped.push(accessoryId);
      } else if (!equip && equipped.includes(accessoryId)) {
        equipped = equipped.filter(i => i !== accessoryId);
      }

      transaction.update(userRef, {
        pet_equipped_accessories: equipped
      });
    });

    res.json({ success: true, message: 'Accessory updated!' });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-buy-trick', verifyFirebaseToken, async (req, res) => {
  try {
    const { trickName, currency = 'usdt' } = req.body;
    
    if (currency === 'usdt' && !TRICK_PRICES_USDT[trickName]) throw new Error('Invalid trick');
    if (currency === 'doge' && !TRICK_PRICES_DOGE[trickName]) throw new Error('Invalid trick');

    const cost = currency === 'usdt' ? TRICK_PRICES_USDT[trickName] : TRICK_PRICES_DOGE[trickName];

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      if (!data.pet_birth_date) throw new Error('Pet not initialized');
      if (getGrowthStage(data) === 'egg') throw new Error('Pets in the egg stage cannot learn tricks.');

      if (currency === 'usdt') {
        const currentAdsBalance = Number(data.ads_balance || 0);
        if (currentAdsBalance < cost) throw new Error(`Insufficient Ad Credit. Costs $${cost.toFixed(2)} USDT.`);
      } else if (currency === 'doge') {
        const currentDogeBalance = Number(data.doge_balance || 0);
        if (currentDogeBalance < cost) throw new Error(`Insufficient Balance. Costs ${cost.toFixed(2)} DOGE.`);
      }

      const owned = data.pet_owned_tricks || [];
      if (owned.includes(trickName)) throw new Error('You already own this trick!');

      owned.push(trickName);

      const updates = {
        pet_owned_tricks: owned
      };

      if (currency === 'usdt') {
        updates.ads_balance = Number(data.ads_balance || 0) - cost;
      } else {
        updates.doge_balance = Number(data.doge_balance || 0) - cost;
      }

      transaction.update(userRef, updates);
    });

    const msg = currency === 'usdt' ? `Trick purchased for $${cost.toFixed(2)} USDT!` : `Trick purchased for ${cost.toFixed(2)} DOGE!`;
    res.json({ success: true, message: msg });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-trick', verifyFirebaseToken, async (req, res) => {
  try {
    const { trickName } = req.body;
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');
      if (getGrowthStage(data) === 'egg') throw new Error('Pets in the egg stage cannot perform tricks.');

      const owned = data.pet_owned_tricks || [];
      if (!owned.includes(trickName)) throw new Error('You do not own this trick!');

      const decayed = calculateDecay(data);
      if (decayed.energy < 5) throw new Error('Pet is too tired for tricks!');

      const newHappiness = Math.min(MAX_STAT, decayed.happiness + 5);
      const newEnergy = decayed.energy - 5;

      let activeBuffs = data.active_trick_buffs || [];
      activeBuffs = activeBuffs.filter(b => typeof b === 'object' && b.expiresAt >= Date.now());

      const existing = activeBuffs.find(b => b.name === trickName);
      if (existing) {
        existing.expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes
      } else {
        activeBuffs.push({ name: trickName, expiresAt: Date.now() + 5 * 60 * 1000 });
      }

      transaction.update(userRef, {
        pet_happiness: newHappiness,
        pet_energy: newEnergy,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        active_trick_buffs: activeBuffs
      });

      newStats = { hunger: decayed.hunger, happiness: newHappiness, energy: newEnergy };
    });

    res.json({ success: true, message: 'Trick performed!', stats: newStats });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-buy-consumable', verifyFirebaseToken, async (req, res) => {
  try {
    const { itemId, currency = 'usdt' } = req.body;
    
    if (currency === 'usdt' && CONSUMABLE_PRICES_USDT[itemId] === undefined) throw new Error('Invalid consumable');
    if (currency === 'doge' && CONSUMABLE_PRICES_DOGE[itemId] === undefined) throw new Error('Invalid consumable');

    const cost = currency === 'usdt' ? CONSUMABLE_PRICES_USDT[itemId] : CONSUMABLE_PRICES_DOGE[itemId];

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      if (currency === 'usdt') {
        const currentAdsBalance = Number(data.ads_balance || 0);
        if (currentAdsBalance < cost) throw new Error(`Insufficient Ad Credit. Costs $${cost.toFixed(2)} USDT.`);
      } else if (currency === 'doge') {
        const currentDogeBalance = Number(data.doge_balance || 0);
        if (currentDogeBalance < cost) throw new Error(`Insufficient Balance. Costs ${cost.toFixed(2)} DOGE.`);
      }

      const owned = data.pet_owned_consumables || {};
      owned[itemId] = (owned[itemId] || 0) + 1;

      const updates = {
        pet_owned_consumables: owned
      };

      if (currency === 'usdt') {
        updates.ads_balance = Number(data.ads_balance || 0) - cost;
      } else {
        updates.doge_balance = Number(data.doge_balance || 0) - cost;
      }

      transaction.update(userRef, updates);
    });

    const msg = currency === 'usdt' ? `Item purchased for $${cost.toFixed(2)} USDT!` : `Item purchased for ${cost.toFixed(2)} DOGE!`;
    res.json({ success: true, message: msg });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-use-consumable', verifyFirebaseToken, async (req, res) => {
  try {
    const { itemId } = req.body;
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;
    let message = '';

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const owned = data.pet_owned_consumables || {};
      if (!owned[itemId] || owned[itemId] <= 0) throw new Error('You do not own this item!');

      const decayed = calculateDecay(data);
      let updates = {
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_energy: decayed.energy,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp()
      };

      const now = Date.now();

      if (itemId === 'medicine') {
        if (!data.pet_sick) throw new Error('Your pet is not sick!');
        updates.pet_sick = false;
        updates.pet_sick_since = null;
        updates.doge_balance = Number(data.doge_balance || 0) + 0.0001;
        message = 'Your pet is cured! You earned 0.0001 DOGE.';
      } else if (itemId === 'basic_kibble') {
        if (decayed.hunger >= MAX_STAT) throw new Error('Pet is already full!');
        updates.pet_hunger = Math.min(MAX_STAT, decayed.hunger + 30);
        message = 'Restored 30 Hunger!';
      } else if (itemId === 'premium_steak') {
        updates.pet_hunger = MAX_STAT;
        updates.xp_boost_expires_at = admin.firestore.Timestamp.fromMillis(now + 2 * 60 * 60 * 1000);
        message = 'Restored Hunger to full and gained +50% XP boost for 2 hours!';
      } else if (itemId === 'energy_drink') {
        const lastDrink = data.last_energy_drink_time ? data.last_energy_drink_time.toDate().getTime() : 0;
        if (now - lastDrink < 24 * 60 * 60 * 1000) {
          throw new Error('You can only use an Energy Drink once per day!');
        }
        updates.pet_energy = MAX_STAT;
        updates.last_energy_drink_time = admin.firestore.FieldValue.serverTimestamp();
        updates.pet_last_walk_sync = null; // Reset walk cooldown
        message = 'Energy is maxed and Walk Cooldown has been reset!';
      } else {
        throw new Error('Unknown item');
      }

      owned[itemId] -= 1;
      updates.pet_owned_consumables = owned;

      transaction.update(userRef, updates);
      newStats = { 
        hunger: updates.pet_hunger || decayed.hunger, 
        happiness: updates.pet_happiness || decayed.happiness, 
        energy: updates.pet_energy || decayed.energy 
      };
    });

    res.json({ success: true, message, stats: newStats });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-buy-ball', verifyFirebaseToken, async (req, res) => {
  try {
    const { color, currency } = req.body;
    if (!color || !currency) return res.status(400).json({ success: false, error: 'Missing parameters' });

    const prices = {
      'red': 0.25, 'orange': 0.75, 'yellow': 1.25,
      'green': 1.75, 'blue': 2.25, 'indigo': 2.75, 'violet': 3.25
    };
    if (!prices[color]) return res.status(400).json({ success: false, error: 'Invalid ball color' });

    const usdtPrice = prices[color];
    const dogePrice = usdtPrice * 8.0;

    const userRef = admin.firestore().collection('users').doc(req.user.uid);

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');
      const data = snapshot.data();

      const ownedBalls = data.pet_owned_balls || ['white'];
      if (ownedBalls.includes(color)) throw new Error('You already own this ball!');

      let updates = {};

      if (currency === 'doge') {
        const balance = Number(data.doge_balance || 0);
        if (balance < dogePrice) throw new Error('Insufficient DOGE balance');
        updates.doge_balance = balance - dogePrice;
      } else if (currency === 'usdt') {
        const balance = Number(data.ad_credit_balance || 0);
        if (balance < usdtPrice) throw new Error('Insufficient USDT (Ad Credit) balance');
        updates.ad_credit_balance = balance - usdtPrice;
      } else {
        throw new Error('Invalid currency');
      }

      ownedBalls.push(color);
      updates.pet_owned_balls = ownedBalls;

      transaction.update(userRef, updates);
    });

    res.json({ success: true, message: 'Ball purchased!' });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-equip-ball', verifyFirebaseToken, async (req, res) => {
  try {
    const { color } = req.body;
    const userRef = admin.firestore().collection('users').doc(req.user.uid);

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');
      const data = snapshot.data();
      const ownedBalls = data.pet_owned_balls || ['white'];

      if (!ownedBalls.includes(color)) throw new Error('You do not own this ball!');
      transaction.update(userRef, { pet_equipped_ball: color });
    });

    res.json({ success: true, message: 'Ball equipped!' });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-fetch', verifyFirebaseToken, async (req, res) => {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;
    let currentClicks = 0;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');
      const data = snapshot.data();

      const now = Date.now();
      const lastFetch = data.pet_last_fetch_time ? data.pet_last_fetch_time.toDate().getTime() : 0;
      if (now - lastFetch < 20000) {
        throw new Error('Pet is tired from the last fetch! Wait a bit.');
      }

      if (data.pet_sick) {
        throw new Error('Pet is sick and cannot play fetch!');
      }

      const ballColor = data.pet_equipped_ball || 'white';
      const rewards = {
        'white': 0, 'red': 0.0001, 'orange': 0.0002, 'yellow': 0.0003,
        'green': 0.0004, 'blue': 0.0005, 'indigo': 0.0006, 'violet': 0.0007
      };
      
      const xpRewards = {
        'white': 1, 'red': 1, 'orange': 2, 'yellow': 3,
        'green': 4, 'blue': 5, 'indigo': 6, 'violet': 7
      };
      
      const dogeReward = rewards[ballColor] || 0;
      const baseXP = xpRewards[ballColor] || 0;
      const xpReward = calculateXPGain(data, baseXP);

      const decayed = calculateDecay(data);
      let newEnergy = Math.max(0, decayed.energy - 5); // Fetch costs 5 energy
      let newHunger = Math.max(0, decayed.hunger - 5); // Fetch costs 5 hunger
      let newHappiness = Math.min(MAX_STAT, decayed.happiness + 10); // Fetch gives +10 happiness
      
      currentClicks = (data.fetch_click_count || 0) + 1;

      let updates = {
        pet_energy: newEnergy,
        pet_hunger: newHunger,
        pet_happiness: newHappiness,
        pet_xp: (data.pet_xp || 0) + xpReward,
        pet_last_fetch_time: admin.firestore.FieldValue.serverTimestamp(),
        fetch_click_count: currentClicks,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp()
      };

      if (dogeReward > 0) {
        updates.doge_balance = Number(data.doge_balance || 0) + dogeReward;
      }

      transaction.update(userRef, updates);
      newStats = { hunger: decayed.hunger, happiness: newHappiness, energy: newEnergy };
    });

    res.json({ 
      success: true, 
      message: 'Good fetch!', 
      stats: newStats, 
      clicks: currentClicks 
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;

