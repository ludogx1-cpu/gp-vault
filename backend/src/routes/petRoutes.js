const express = require('express');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');

const { calculateDecay, getGrowthStage, getAgeMultiplier, MAX_STAT, calculatePetBonusPercent } = require('../utils/petMechanics');
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
const METERS_PER_MILE = 1609.34;
const WALK_REWARD_PER_MILE = 0.001;

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
          pet_hunger: 50,
          pet_happiness: 50,
          pet_energy: 100,
          pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
          pet_total_distance_walked: 0,
          pet_investments: []
        };
        transaction.update(userRef, initData);
        petStats = {
          hunger: 50,
          happiness: 50,
          energy: 100,
          stage: 'puppy',
          total_distance: 0,
          locked_returns: 0,
          matured_returns: 0
        };
      } else {
        const decayed = calculateDecay(data);
        
        if (decayed.hoursPassed > 30 * 24) {
          // Reset pet completely due to 1-month inactivity
          const initData = {
            pet_birth_date: admin.firestore.FieldValue.serverTimestamp(),
            pet_hunger: 50,
            pet_happiness: 50,
            pet_energy: 100,
            pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
            pet_total_distance_walked: 0,
            pet_investments: [],
            pet_owned_accessories: [],
            pet_equipped_accessories: [],
            pet_owned_tricks: [],
            active_trick_buffs: []
          };
          transaction.update(userRef, initData);
          petStats = {
            hunger: 50,
            happiness: 50,
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
            owned_tricks: []
          };
          // Return immediately with new stats
          return;
        }

        // Update DB with decayed stats
        transaction.update(userRef, {
          pet_hunger: decayed.hunger,
          pet_happiness: decayed.happiness,
          pet_energy: decayed.energy,
          pet_last_interaction: admin.firestore.FieldValue.serverTimestamp()
        });

        let pendingPoos = 0;
        if (data.pet_last_poo_time) {
          const hoursSincePoo = (Date.now() - data.pet_last_poo_time.toDate().getTime()) / (1000 * 60 * 60);
          pendingPoos = Math.min(12, Math.floor(hoursSincePoo / 2)); // 1 poo per 2 hours, max 12
        } else {
          // If no last poo time, initialize it
          transaction.update(userRef, { pet_last_poo_time: admin.firestore.FieldValue.serverTimestamp() });
        }

        petStats = {
          hunger: decayed.hunger,
          happiness: decayed.happiness,
          energy: decayed.energy,
          stage: getGrowthStage(data.pet_birth_date),
          age_multiplier: getAgeMultiplier(data.pet_birth_date),
          total_distance: data.pet_total_distance_walked || 0,
          pending_poos: pendingPoos,
          locked_returns: locked,
          matured_returns: matured,
          last_boop_time: data.pet_last_boop_time ? data.pet_last_boop_time.toDate().getTime() : 0,
          last_feed_time: data.pet_last_feed_time ? data.pet_last_feed_time.toDate().getTime() : 0,
          last_play_time: data.pet_last_play_time ? data.pet_last_play_time.toDate().getTime() : 0,
          last_sleep_time: data.pet_last_sleep_time ? data.pet_last_sleep_time.toDate().getTime() : 0,
          name: data.pet_name || 'Golden Paw Shiba',
          owned_accessories: data.pet_owned_accessories || [],
          equipped_accessories: data.pet_equipped_accessories || [],
          owned_tricks: data.pet_owned_tricks || []
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
      if (data.pet_last_feed_time && (Date.now() - data.pet_last_feed_time.toDate().getTime()) < 3 * 60 * 60 * 1000) {
        throw new Error('You can only feed your pet once every 3 hours!');
      }

      const { matured, remainingInvestments } = processInvestments(userRef, data, transaction);
      const currentDoge = Number(data.doge_balance || 0) + matured;

      if (currentDoge < FEED_COST_DOGE) throw new Error(`Insufficient DOGE. Costs ${FEED_COST_DOGE} DOGE to feed.`);

      const petBonus = calculatePetBonusPercent(decayed, data);
      const investmentAmount = (FEED_COST_DOGE * 2) * (1 + (petBonus / 100));
      const newHunger = Math.min(MAX_STAT, decayed.hunger + FEED_HUNGER_RECOVERY);
      remainingInvestments.push({ amount: investmentAmount, unlock_time: Date.now() + 24 * 60 * 60 * 1000 });

      transaction.update(userRef, {
        doge_balance: currentDoge - FEED_COST_DOGE,
        pet_hunger: newHunger,
        pet_happiness: decayed.happiness,
        pet_energy: decayed.energy,
        pet_investments: remainingInvestments,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_feed_time: admin.firestore.FieldValue.serverTimestamp()
      });

      newStats = { hunger: newHunger, happiness: decayed.happiness, energy: decayed.energy, cost: FEED_COST_DOGE };
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
      if (decayed.energy < PLAY_ENERGY_COST) throw new Error('Pet is too tired to play. Let it sleep!');
      if (decayed.happiness >= MAX_STAT) throw new Error('Pet is already at max happiness!');
      if (data.pet_last_play_time && (Date.now() - data.pet_last_play_time.toDate().getTime()) < 3 * 60 * 60 * 1000) {
        throw new Error('You can only play with your pet once every 3 hours!');
      }

      const { matured, remainingInvestments } = processInvestments(userRef, data, transaction);
      const currentDoge = Number(data.doge_balance || 0) + matured;

      if (currentDoge < PLAY_COST_DOGE) throw new Error(`Insufficient DOGE. Costs ${PLAY_COST_DOGE} DOGE to play.`);

      const petBonus = calculatePetBonusPercent(decayed, data);
      const investmentAmount = (PLAY_COST_DOGE * 2) * (1 + (petBonus / 100));
      const newHappiness = Math.min(MAX_STAT, decayed.happiness + PLAY_HAPPINESS_RECOVERY);
      const newEnergy = decayed.energy - PLAY_ENERGY_COST;
      remainingInvestments.push({ amount: investmentAmount, unlock_time: Date.now() + 24 * 60 * 60 * 1000 });

      transaction.update(userRef, {
        doge_balance: currentDoge - PLAY_COST_DOGE,
        pet_hunger: decayed.hunger,
        pet_happiness: newHappiness,
        pet_energy: newEnergy,
        pet_investments: remainingInvestments,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_play_time: admin.firestore.FieldValue.serverTimestamp()
      });

      newStats = { hunger: decayed.hunger, happiness: newHappiness, energy: newEnergy };
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
      if (data.pet_last_sleep_time && (Date.now() - data.pet_last_sleep_time.toDate().getTime()) < 3 * 60 * 60 * 1000) {
        throw new Error('Your pet can only sleep once every 3 hours!');
      }

      const { matured, remainingInvestments } = processInvestments(userRef, data, transaction);
      const currentDoge = Number(data.doge_balance || 0) + matured;

      if (currentDoge < SLEEP_COST_DOGE) throw new Error(`Insufficient DOGE. Costs ${SLEEP_COST_DOGE} DOGE to sleep.`);

      const petBonus = calculatePetBonusPercent(decayed, data);
      const investmentAmount = (SLEEP_COST_DOGE * 2) * (1 + (petBonus / 100));
      const newEnergy = Math.min(MAX_STAT, decayed.energy + SLEEP_ENERGY_RECOVERY);
      remainingInvestments.push({ amount: investmentAmount, unlock_time: Date.now() + 24 * 60 * 60 * 1000 });

      transaction.update(userRef, {
        doge_balance: currentDoge - SLEEP_COST_DOGE,
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_energy: newEnergy,
        pet_investments: remainingInvestments,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_sleep_time: admin.firestore.FieldValue.serverTimestamp()
      });

      newStats = { hunger: decayed.hunger, happiness: decayed.happiness, energy: newEnergy };
    });

    res.json({ success: true, message: 'Pet took a nap!', stats: newStats });
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

    const maxReasonableMetersPerMinute = 150; // About 9 km/h max walking/jogging speed
    // Ideally we would verify timestamp since last sync to prevent spoofing
    // For simplicity, we just cap per request assuming frontend sends reasonable chunks
    const validMeters = Math.min(distance_meters, 500); 

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let result = null;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const decayed = calculateDecay(data);
      
      const energyCost = (validMeters / 100) * WALK_ENERGY_COST_PER_100M;
      if (decayed.energy < energyCost) {
        throw new Error('Pet is too tired to walk that far!');
      }

      const ageMult = getAgeMultiplier(data.pet_birth_date);
      const baseReward = (validMeters / METERS_PER_MILE) * WALK_REWARD_PER_MILE;
      const dogeReward = baseReward * ageMult;
      
      const newDogeBal = Number(data.doge_balance || 0) + dogeReward;
      const newTotalDist = Number(data.pet_total_distance_walked || 0) + validMeters;
      const newEnergy = decayed.energy - energyCost;

      transaction.update(userRef, {
        doge_balance: newDogeBal,
        pet_energy: newEnergy,
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_total_distance_walked: newTotalDist,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp()
      });

      result = { reward: dogeReward, distance: validMeters, total_distance: newTotalDist, energy: newEnergy };
    });

    res.json({ success: true, message: 'Walk synced', ...result });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/pet-clean-poo', verifyFirebaseToken, async (req, res) => {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let reward = 0.0005;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const lastPooTime = data.pet_last_poo_time;
      if (!lastPooTime) throw new Error('No poos to clean right now!');

      const msPassed = Date.now() - lastPooTime.toDate().getTime();
      const hoursPassed = msPassed / (1000 * 60 * 60);
      
      if (hoursPassed < 2) {
        throw new Error('No poos to clean right now! Wait a bit.');
      }

      // Calculate how many poos they had pending before cleaning one
      const pendingPoos = Math.min(12, Math.floor(hoursPassed / 2));
      if (pendingPoos <= 0) throw new Error('No poos to clean!');

      const newDogeBal = Number(data.doge_balance || 0) + reward;

      // Advance the timer by exactly 2 hours (1 poo worth), but don't exceed current time
      // If they had 12 poos (max), we shouldn't keep the "overflow" time. We just deduct 2 hours from current time if they are at max.
      let newLastPooTimeMs = lastPooTime.toDate().getTime() + (2 * 60 * 60 * 1000);
      
      if (pendingPoos === 12) {
         // If they were capped, their timer is essentially "Now - 24 hours". 
         // Deducting 1 poo means they should have 11 left (Now - 22 hours).
         newLastPooTimeMs = Date.now() - (11 * 2 * 60 * 60 * 1000);
      }

      transaction.update(userRef, {
        doge_balance: newDogeBal,
        pet_last_poo_time: admin.firestore.Timestamp.fromMillis(newLastPooTimeMs)
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
    let reward = 0.002;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      if (data.pet_last_boop_time) {
        const msPassed = Date.now() - data.pet_last_boop_time.toDate().getTime();
        if (msPassed < 15 * 60 * 1000) {
          throw new Error('Pet is not ready for a boop right now. Wait a bit!');
        }
      }

      const newDogeBal = Number(data.doge_balance || 0) + reward;

      transaction.update(userRef, {
        doge_balance: newDogeBal,
        pet_last_boop_time: admin.firestore.FieldValue.serverTimestamp()
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

const TRICK_PRICES_USDT = {
  'Spin': 1.0,
  'Jump': 2.0,
  'Roll Over': 3.0,
  'Backflip': 5.0,
  'Moonwalk': 10.0
};

router.post('/pet-buy-accessory', verifyFirebaseToken, async (req, res) => {
  try {
    const { accessoryId } = req.body;
    if (!ACCESSORY_PRICES_USDT[accessoryId]) throw new Error('Invalid accessory');

    const usdtCost = ACCESSORY_PRICES_USDT[accessoryId];

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      if (!data.pet_birth_date) throw new Error('Pet not initialized');
      if (getGrowthStage(data.pet_birth_date) === 'egg') throw new Error('Pets in the egg stage cannot use the shop.');

      const currentAdsBalance = Number(data.ads_balance || 0);

      if (currentAdsBalance < usdtCost) throw new Error(`Insufficient Ad Credit. Costs $${usdtCost.toFixed(2)} USDT.`);

      const owned = data.pet_owned_accessories || [];
      if (owned.includes(accessoryId)) throw new Error('You already own this accessory!');

      owned.push(accessoryId);

      transaction.update(userRef, {
        ads_balance: currentAdsBalance - usdtCost,
        pet_owned_accessories: owned
      });
    });

    res.json({ success: true, message: `Accessory purchased for $${usdtCost.toFixed(2)} USDT!` });
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
      if (getGrowthStage(data.pet_birth_date) === 'egg') throw new Error('Pets in the egg stage cannot use the shop.');

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
    const { trickName } = req.body;
    if (!TRICK_PRICES_USDT[trickName]) throw new Error('Invalid trick');

    const usdtCost = TRICK_PRICES_USDT[trickName];

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      if (!data.pet_birth_date) throw new Error('Pet not initialized');
      if (getGrowthStage(data.pet_birth_date) === 'egg') throw new Error('Pets in the egg stage cannot learn tricks.');

      const currentAdsBalance = Number(data.ads_balance || 0);

      if (currentAdsBalance < usdtCost) throw new Error(`Insufficient Ad Credit. Costs $${usdtCost.toFixed(2)} USDT.`);

      const owned = data.pet_owned_tricks || [];
      if (owned.includes(trickName)) throw new Error('You already own this trick!');

      owned.push(trickName);

      transaction.update(userRef, {
        ads_balance: currentAdsBalance - usdtCost,
        pet_owned_tricks: owned
      });
    });

    res.json({ success: true, message: `Trick purchased for $${usdtCost.toFixed(2)} USDT!` });
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
      if (getGrowthStage(data.pet_birth_date) === 'egg') throw new Error('Pets in the egg stage cannot perform tricks.');

      const owned = data.pet_owned_tricks || [];
      if (!owned.includes(trickName)) throw new Error('You do not own this trick!');

      const decayed = calculateDecay(data);
      if (decayed.energy < 5) throw new Error('Pet is too tired for tricks!');

      const newHappiness = Math.min(MAX_STAT, decayed.happiness + 5);
      const newEnergy = decayed.energy - 5;

      let activeBuffs = data.active_trick_buffs || [];
      if (!activeBuffs.includes(trickName)) {
        activeBuffs.push(trickName);
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

module.exports = router;
