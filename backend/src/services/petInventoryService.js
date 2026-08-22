
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
  petRename,
  petAdminAgeUp,
  petBuyAccessory,
  petEquipAccessory,
  petBuyTrick,
  petTrick,
  petBuyConsumable,
  petUseConsumable,
  petBuyBall,
  petEquipBall,
  petFetch
};

async function petRename(req) {
  try {
    const { newName } = req.body;
    if (!newName || newName.length > 20) {
      throw new Error('Name must be 1-20 characters long.');
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    await userRef.set({
      pet_name: newName
    }, { merge: true });

    return {  success: true, message: 'Pet renamed successfully!'  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petAdminAgeUp(req) {
  try {
    // Basic admin check (could use custom claims, but hardcoding email is consistent with the frontend for now)
    const userRecord = await admin.auth().getUser(req.user.uid);
    if (userRecord.email !== 'ludogx1@gmail.com') {
      throw new Error('Admin only');
    }

    const { days = 30 } = req.body;
    const daysNumber = Number(days);

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    
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

      // Subtract days from birth date to age it up (or negative to age down)
      const oldBirthTime = data.pet_birth_date.toDate().getTime();
      const newBirthTime = oldBirthTime - (daysNumber * 24 * 60 * 60 * 1000);
      
      const updates = {
        pet_birth_date: admin.firestore.Timestamp.fromMillis(newBirthTime)
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
    });

    return {  success: true, message: `Aged by ${daysNumber} days!`  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petBuyAccessory(req) {
  try {
    const { accessoryId, currency = 'usdt' } = req.body;
    
    if (currency === 'usdt' && !ACCESSORY_PRICES_USDT[accessoryId]) throw new Error('Invalid accessory');
    if (currency === 'doge' && !ACCESSORY_PRICES_DOGE[accessoryId]) throw new Error('Invalid accessory');

    const cost = currency === 'usdt' ? ACCESSORY_PRICES_USDT[accessoryId] : ACCESSORY_PRICES_DOGE[accessoryId];

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    
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
      if (getGrowthStage(data) === 'baby') throw new Error('Pets in the baby stage cannot use the shop.');

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

      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
        if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
        if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
    });

    const msg = currency === 'usdt' ? `Accessory purchased for $${cost.toFixed(2)} USDT!` : `Accessory purchased for ${cost.toFixed(2)} DOGE!`;
    return {  success: true, message: msg  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petEquipAccessory(req) {
  try {
    const { accessoryId, equip } = req.body; // equip boolean
    const userRef = admin.firestore().collection('users').doc(req.user.uid);

    
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
      if (getGrowthStage(data) === 'baby') throw new Error('Pets in the baby stage cannot use the shop.');

      const owned = data.pet_owned_accessories || [];
      if (equip && !owned.includes(accessoryId)) throw new Error('You do not own this accessory.');

      let equipped = data.pet_equipped_accessories || [];
      if (equip && !equipped.includes(accessoryId)) {
        equipped.push(accessoryId);
      } else if (!equip && equipped.includes(accessoryId)) {
        equipped = equipped.filter(i => i !== accessoryId);
      }

      const updates = {
        pet_equipped_accessories: equipped
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
    });

    return {  success: true, message: 'Accessory updated!'  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petBuyTrick(req) {
  try {
    const { trickName, currency = 'usdt' } = req.body;
    
    if (currency === 'usdt' && !TRICK_PRICES_USDT[trickName]) throw new Error('Invalid trick');
    if (currency === 'doge' && !TRICK_PRICES_DOGE[trickName]) throw new Error('Invalid trick');

    const cost = currency === 'usdt' ? TRICK_PRICES_USDT[trickName] : TRICK_PRICES_DOGE[trickName];

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    
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
      if (getGrowthStage(data) === 'baby') throw new Error('Pets in the baby stage cannot learn tricks.');

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

      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
        if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
        if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
    });

    const msg = currency === 'usdt' ? `Trick purchased for $${cost.toFixed(2)} USDT!` : `Trick purchased for ${cost.toFixed(2)} DOGE!`;
    return {  success: true, message: msg  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petTrick(req) {
  try {
    const { trickName } = req.body;
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
      if (getGrowthStage(data) === 'baby') throw new Error('Pets in the baby stage cannot perform tricks.');

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

      const updates = {
        pet_happiness: newHappiness,
        pet_energy: newEnergy,
        weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        active_trick_buffs: activeBuffs
      };
      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });

      newStats = { hunger: decayed.hunger, happiness: newHappiness, energy: newEnergy };
    });

    return {  success: true, message: 'Trick performed!', stats: newStats  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petBuyConsumable(req) {
  try {
    const { itemId, currency = 'usdt' } = req.body;
    
    if (currency === 'usdt' && CONSUMABLE_PRICES_USDT[itemId] === undefined) throw new Error('Invalid consumable');
    if (currency === 'doge' && CONSUMABLE_PRICES_DOGE[itemId] === undefined) throw new Error('Invalid consumable');

    const cost = currency === 'usdt' ? CONSUMABLE_PRICES_USDT[itemId] : CONSUMABLE_PRICES_DOGE[itemId];

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    
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

      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
        if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
        if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
    });

    const msg = currency === 'usdt' ? `Item purchased for $${cost.toFixed(2)} USDT!` : `Item purchased for ${cost.toFixed(2)} DOGE!`;
    return {  success: true, message: msg  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petUseConsumable(req) {
  try {
    const { itemId } = req.body;
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;
    let message = '';

    
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

      const owned = data.pet_owned_consumables || {};
      if (!owned[itemId] || owned[itemId] <= 0) throw new Error('You do not own this item!');

      const decayed = calculateDecay(data);
      let updates = {
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_energy: decayed.energy,
        weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
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

      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
        if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
        if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
      newStats = { 
        hunger: updates.pet_hunger || decayed.hunger, 
        happiness: updates.pet_happiness || decayed.happiness, 
        energy: updates.pet_energy || decayed.energy 
      };
    });

    return {  success: true, message, stats: newStats  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petBuyBall(req) {
  try {
    const { color, currency } = req.body;
    if (!color || !currency) throw new Error('Missing parameters');

    const prices = {
      'red': 0.25, 'orange': 0.75, 'yellow': 1.25,
      'green': 1.75, 'blue': 2.25, 'indigo': 2.75, 'violet': 3.25
    };
    if (!prices[color]) throw new Error('Invalid ball color');

    const usdtPrice = prices[color];
    const dogePrice = usdtPrice * 8.0;

    const userRef = admin.firestore().collection('users').doc(req.user.uid);

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');
      const data = snapshot.data();
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);

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

      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
        if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
        if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
    });

    return {  success: true, message: 'Ball purchased!'  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petEquipBall(req) {
  try {
    const { color } = req.body;
    const userRef = admin.firestore().collection('users').doc(req.user.uid);

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');
      const data = snapshot.data();
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);
      const ownedBalls = data.pet_owned_balls || ['white'];

      if (!ownedBalls.includes(color)) throw new Error('You do not own this ball!');
      transaction.set(petRef, { pet_equipped_ball: color }, { merge: true });
    });

    return {  success: true, message: 'Ball equipped!'  };
  } catch (error) {
    throw new Error(error.message);
  }
}


async function petFetch(req) {
  try {
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let newStats = null;
    let currentClicks = 0;

    
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {
      const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw new Error('User not found');
      const data = snapshot.data();
      const petSnapshot = await transaction.get(petRef);
      const petData = petSnapshot.data() || {};
      Object.assign(data, petData);

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
      let newHappiness = Math.min(MAX_STAT, decayed.happiness + 20); // Fetch gives +20 happiness
      
      currentClicks = (data.fetch_click_count || 0) + 1;

      let updates = {
        pet_energy: newEnergy,
        pet_hunger: newHunger,
        pet_happiness: newHappiness,
        pet_xp: (data.pet_xp || 0) + xpReward,
        pet_last_fetch_time: admin.firestore.FieldValue.serverTimestamp(),
        fetch_click_count: currentClicks,
        weekly_time_above_40: Number(data.weekly_time_above_40 || 0) + (typeof decayed !== 'undefined' ? decayed.hoursAbove40 : 0),
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp()
      };

      if (dogeReward > 0) {
        updates.doge_balance = Number(data.doge_balance || 0) + dogeReward;
        let history = data.reward_history || [];
        history.unshift({ sector: 'Pet Care (Fetch)', amount: dogeReward, timestamp: Date.now() });
        if (history.length > 15) history = history.slice(0, 15);
        updates.reward_history = history;
      }

      Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);
        if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
        if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
      newStats = { hunger: decayed.hunger, happiness: newHappiness, energy: newEnergy };
    });

    return {  
      success: true, 
      message: 'Good fetch!', 
      stats: newStats, 
      clicks: currentClicks 
     };
  } catch (error) {
    throw new Error(error.message);
  }
}


