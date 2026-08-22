
const { calculateDecay, getGrowthStage, getAgeMultiplier, getNextStageXP, MAX_STAT, calculatePetBonusPercent } = require('../utils/petMechanics');
const { getDogePrice } = require('./priceService');
const { syncUserBalances, syncPetStats } = require('../utils/dataConnectSync');

const FEED_COST_DOGE = 0.0001;
const PLAY_COST_DOGE = 0.0001;
const SLEEP_COST_DOGE = 0.0001;
const FEED_HUNGER_RECOVERY = 30;
const PLAY_ENERGY_COST = 15;
const PLAY_HAPPINESS_RECOVERY = 25;
const SLEEP_ENERGY_RECOVERY = 40;
const WALK_ENERGY_COST_PER_100M = 5;
const WALK_REWARD_PER_100M = 0.0005;

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

const { admin } = require('./firebaseService');




function ensureXP(data) {
  let xp = data.pet_xp !== undefined ? Number(data.pet_xp) : 0;
  if (!data.pet_birth_date) return xp;
  
  const daysOld = (Date.now() - data.pet_birth_date.toDate().getTime()) / (1000 * 60 * 60 * 24);
  let ageXP = 0;
  if (daysOld >= 365) ageXP = 6000;
  else if (daysOld >= 180) ageXP = 3000;
  else if (daysOld >= 90) ageXP = 1500;
  else if (daysOld >= 30) ageXP = 700;
  else if (daysOld >= 14) ageXP = 300;
  else if (daysOld >= 7) ageXP = 100;
  
  return Math.max(xp, ageXP);
}

function calculateXPGain(data, baseXP) {
  if (data.xp_boost_expires_at && data.xp_boost_expires_at.toDate().getTime() > Date.now()) {
    return Math.floor(baseXP * 1.5);
  }
  return baseXP;
}



module.exports = {
  petStatus,
  petFeed,
  petPlay,
  petSleep,
  petStroke,
  petWalkSync,
  petCleanPoo,
  petBoop
};

async function petStatus(req) {
  try {
    

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    
    let petStats = null;

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');

      const data = snapshot.data() || {};
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);
      
      // Initialize pet if doesn't exist
      if (!data.pet_birth_date) {
        const initData = {
          pet_birth_date: admin.firestore.FieldValue.serverTimestamp(),
          pet_xp: 0,
          pet_hunger: 50,
          pet_happiness: 50,
          pet_attention: 50,
          pet_energy: 100,
          weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
          pet_total_distance_walked: 0
        };
        Object.assign(dualWriteUpdates, initData);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(initData);
        if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
        if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
        petStats = {
          hunger: 50,
          happiness: 50,
          attention: 50,
          energy: 100,
          stage: 'puppy',
          xp: 0,
          next_stage_xp: getNextStageXP('puppy'),
          total_distance: 0,
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
            weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
            pet_total_distance_walked: 0,
            pet_owned_accessories: [],
            pet_equipped_accessories: [],
            pet_owned_tricks: [],
            active_trick_buffs: [],
            pet_owned_balls: ['white'],
            pet_equipped_ball: 'white',
            fetch_click_count: 0
          };
          Object.assign(dualWriteUpdates, initData);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(initData);
        if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
        if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
          petStats = {
            hunger: 50,
            happiness: 50,
            attention: 50,
            energy: 100,
            stage: 'puppy',
            total_distance: 0,
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
          weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
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
        Object.assign(dualWriteUpdates, updatePayload);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updatePayload);
        if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
        if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });

        let pendingPoos = 0;
        if (data.pet_last_poo_time) {
          const currentHour = Math.floor(Date.now() / 3600000);
          const lastPooHour = Math.floor(data.pet_last_poo_time.toDate().getTime() / 3600000);
          pendingPoos = Math.max(0, Math.min(4, currentHour - lastPooHour)); // 1 poo on the hour, max 4
        } else {
          // If no last poo time, initialize it
          const updates = { pet_last_poo_time: admin.firestore.FieldValue.serverTimestamp() };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
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

    return {  success: true, pet: petStats  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petFeed(req) {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const decayed = calculateDecay(data);
      if (decayed.hunger >= MAX_STAT) throw new Error('Pet is already full!');
      if (data.pet_last_feed_time && (Date.now() - data.pet_last_feed_time.toDate().getTime()) < 1 * 60 * 60 * 1000) {
        throw new Error('You can only feed your pet once every 1 hour!');
      }

      const currentDoge = Number(data.doge_balance || 0);

      if (currentDoge < FEED_COST_DOGE) throw new Error(`Insufficient DOGE. Costs ${FEED_COST_DOGE} DOGE to feed.`);

      const newHunger = MAX_STAT;

      const currentXP = ensureXP(data);
      const xpGained = calculateXPGain(data, 20);
      const newXP = currentXP + xpGained;

      const updates = {
        doge_balance: currentDoge - FEED_COST_DOGE,
        pet_xp: newXP,
        pet_hunger: newHunger,
        pet_happiness: decayed.happiness,
        pet_energy: decayed.energy,
        weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_feed_time: admin.firestore.FieldValue.serverTimestamp()
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });

      newStats = { hunger: newHunger, happiness: decayed.happiness, energy: decayed.energy, cost: FEED_COST_DOGE, xp: newXP };
    });

    return {  success: true, message: 'Fed the pet!', stats: newStats  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petPlay(req) {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const decayed = calculateDecay(data);
      if (decayed.happiness >= MAX_STAT) throw new Error('Pet is already at max happiness!');
      if (data.pet_last_play_time && (Date.now() - data.pet_last_play_time.toDate().getTime()) < 5 * 60 * 60 * 1000) {
        throw new Error('You can only play with your pet once every 5 hours!');
      }

      const currentDoge = Number(data.doge_balance || 0);

      if (currentDoge < PLAY_COST_DOGE) throw new Error(`Insufficient DOGE. Costs ${PLAY_COST_DOGE} DOGE to play.`);

      const newHappiness = MAX_STAT;

      const currentXP = ensureXP(data);
      const xpGained = calculateXPGain(data, 20);
      const newXP = currentXP + xpGained;

      const updates = {
        doge_balance: currentDoge - PLAY_COST_DOGE,
        pet_xp: newXP,
        pet_hunger: decayed.hunger,
        pet_happiness: newHappiness,
        pet_energy: decayed.energy,
        weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_play_time: admin.firestore.FieldValue.serverTimestamp()
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });

      newStats = { hunger: decayed.hunger, happiness: newHappiness, energy: decayed.energy, xp: newXP };
    });

    return {  success: true, message: 'Played with pet!', stats: newStats  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petSleep(req) {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      const decayed = calculateDecay(data);
      if (decayed.energy >= MAX_STAT) throw new Error('Pet is not tired.');
      if (data.pet_sleeping_until && data.pet_sleeping_until.toDate().getTime() > Date.now()) {
        throw new Error('Pet is already sleeping!');
      }

      const currentDoge = Number(data.doge_balance || 0);

      const newEnergy = Math.min(MAX_STAT, decayed.energy + 50);

      const currentXP = ensureXP(data);
      const xpGained = calculateXPGain(data, 20);
      const newXP = currentXP + xpGained;

      const updates = {
        doge_balance: currentDoge,
        pet_xp: newXP,
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_attention: decayed.attention,
        pet_energy: newEnergy,
        weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        pet_last_sleep_time: admin.firestore.FieldValue.serverTimestamp(),
        pet_sleeping_until: admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
        pending_sleep_reward: true
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });

      newStats = { hunger: decayed.hunger, happiness: decayed.happiness, attention: decayed.attention, energy: newEnergy, xp: newXP };
    });

    return {  success: true, message: 'Pet took a nap! Zzz...', stats: newStats  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petStroke(req) {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);

      if (!data.pet_birth_date) throw new Error('Pet not initialized');

      if (data.pet_sleeping_until && data.pet_sleeping_until.toDate().getTime() > Date.now()) {
        throw new Error('Shh... The pet is sleeping!');
      }

      const decayed = calculateDecay(data);
      if (decayed.attention >= MAX_STAT) throw new Error('Pet has full attention already!');

      const newAttention = Math.min(MAX_STAT, decayed.attention + 20);
      const currentXP = ensureXP(data);
      const xpGained = calculateXPGain(data, 5);
      const newXP = currentXP + xpGained;

      const updates = {
        pet_xp: newXP,
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_attention: newAttention,
        pet_energy: decayed.energy,
        weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp()
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });

      newStats = { hunger: decayed.hunger, happiness: decayed.happiness, attention: newAttention, energy: decayed.energy, xp: newXP };
    });

    return {  success: true, message: 'You stroked the pet!', stats: newStats  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petWalkSync(req) {
  try {
    const { distance_meters } = req.body;
    if (!distance_meters || distance_meters <= 0) {
      throw new Error('Invalid distance');
    }

    const maxValidMeters = 1000;
    const validMeters = Math.min(distance_meters, maxValidMeters); 

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let result = null;

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);

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

      let history = data.reward_history || [];
      history.unshift({ sector: 'Pet Care (Walk)', amount: dogeReward, timestamp: Date.now() });
      if (history.length > 15) history = history.slice(0, 15);

      const updates = {
        doge_balance: newDogeBal,
        pet_xp: newXP,
        pet_energy: newEnergy,
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_total_distance_walked: newTotalDist,
        pet_last_walk_sync: admin.firestore.FieldValue.serverTimestamp(),
        weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        reward_history: history
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });


      result = { reward: dogeReward, distance: validMeters, total_distance: newTotalDist, energy: newEnergy, xp: newXP, xp_gained: xpGained };
    });

    return {  success: true, message: 'Walk synced', ...result  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petCleanPoo(req) {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let reward = 0.00025;

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);

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
      const xpGained = calculateXPGain(data, 10);
      const newXP = currentXP + xpGained;

      const updates = {
        doge_balance: newDogeBal,
        pet_xp: newXP,
        pet_last_poo_time: admin.firestore.Timestamp.fromMillis(newLastPooTimeMs),
        reward_history: history
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
    });

    return {  success: true, message: 'Cleaned up poo!', reward  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petBoop(req) {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let reward = 0.004;

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      const data = snapshot.data() || {};
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);

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
      const xpGained = calculateXPGain(data, 5);
      const newXP = currentXP + xpGained;

      const updates = {
        doge_balance: newDogeBal,
        pet_xp: newXP,
        pet_last_boop_time: admin.firestore.FieldValue.serverTimestamp(),
        reward_history: history
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
    });

    return {  success: true, message: 'Boop! You found a reward!', reward  };
  } catch (error) {
    throw new Error(error.message);
  }
}


