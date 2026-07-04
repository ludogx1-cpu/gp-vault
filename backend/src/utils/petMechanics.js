const DECAY_RATE_PER_HOUR = 5.0;
const MAX_STAT = 100;

function calculateDecay(userData) {
  const now = Date.now();
  const lastInteraction = userData.pet_last_interaction ? userData.pet_last_interaction.toDate().getTime() : now;
  const hoursPassed = (now - lastInteraction) / (1000 * 60 * 60);

  const stage = getGrowthStage(userData);

  let hungerDecayRate = DECAY_RATE_PER_HOUR;
  let happinessDecayRate = DECAY_RATE_PER_HOUR;
  let energyDecayRate = DECAY_RATE_PER_HOUR;

  if (stage === 'baby' || stage === 'toddler' || stage === 'puppy') {
    energyDecayRate = 8.0;
    happinessDecayRate = 8.0;
    hungerDecayRate = 3.0;
  } else if (stage === 'child' || stage === 'teen') {
    energyDecayRate = 6.0;
    happinessDecayRate = 6.0;
    hungerDecayRate = 5.0;
  } else if (stage === 'young_adult' || stage === 'adult') {
    energyDecayRate = 4.0;
    happinessDecayRate = 4.0;
    hungerDecayRate = 8.0;
  }

  const hungerDecay = hoursPassed * hungerDecayRate;
  const happinessDecay = hoursPassed * happinessDecayRate;
  const energyDecay = hoursPassed * energyDecayRate;

  let hunger = Number(userData.pet_hunger ?? 50);
  let happiness = Number(userData.pet_happiness ?? 50);
  let energy = Number(userData.pet_energy ?? 50);

  hunger = Math.max(0, hunger - hungerDecay);
  happiness = Math.max(0, happiness - happinessDecay);
  energy = Math.max(0, energy - energyDecay);

  return { hunger, happiness, energy, hoursPassed };
}

function getGrowthStage(birthDate) {
  if (!birthDate) return 'egg';
  const daysOld = (Date.now() - birthDate.toDate().getTime()) / (1000 * 60 * 60 * 24);
  if (daysOld < 2) return 'egg';
  if (daysOld < 7) return 'baby';
  if (daysOld < 14) return 'toddler';
  if (daysOld < 30) return 'puppy';
  if (daysOld < 90) return 'child';
  if (daysOld < 180) return 'teen';
  if (daysOld < 365) return 'young_adult';
  return 'adult';
}

function calculatePetBonusPercent(decayedStats, userData) {
  if (userData.pet_sick) return 0;
  // If stats average > 80%, give +10% bonus
  // If average > 50%, give +5%
  // If average < 20%, give 0%
  const avg = (decayedStats.hunger + decayedStats.happiness + decayedStats.energy) / 3;
  let baseBonus = 0;
  if (avg >= 80) baseBonus = 10;
  else if (avg >= 50) baseBonus = 5;

  return baseBonus; // Only base stats apply to the faucet now
}

function calculateShopBonusPercent(userData) {
  if (userData.pet_sick) return 0;
  const accessoryBonuses = {
    'top_hat': 10,
    'sunglasses': 20,
    'gold_chain': 30,
    'diamond_watch': 50,
    'crown': 100,
    'coat_basic': 15,
    'coat_rain': 25,
    'coat_winter': 40,
    'coat_luxury': 75
  };

  let shopBonus = 0;
  const equippedAccessories = userData.pet_equipped_accessories || [];
  for (const acc of equippedAccessories) {
    if (accessoryBonuses[acc]) shopBonus += accessoryBonuses[acc];
  }
  return shopBonus;
}

function calculateTrickBonusPercent(userData) {
  if (userData.pet_sick) return 0;
  const trickBonuses = {
    'Spin': 10,
    'Jump': 20,
    'Roll Over': 30,
    'Backflip': 50,
    'Moonwalk': 100
  };

  let trickBonus = 0;
  const activeTricks = userData.active_trick_buffs || [];
  const now = Date.now();
  for (const trickObj of activeTricks) {
    if (typeof trickObj === 'string') continue; // Ignore legacy strings
    if (trickObj.expiresAt < now) continue;
    if (trickBonuses[trickObj.name]) trickBonus += trickBonuses[trickObj.name];
  }
  return trickBonus;
}

const XP_THRESHOLDS = {
  egg: 0,
  baby: 100,
  toddler: 300,
  puppy: 700,
  child: 1500,
  teen: 3000,
  young_adult: 6000,
  adult: 10000
};

// Legacy fallback logic
function getGrowthStageByDate(birthDate) {
  if (!birthDate) return 'egg';
  const daysOld = (Date.now() - birthDate.toDate().getTime()) / (1000 * 60 * 60 * 24);
  if (daysOld < 2) return 'egg';
  if (daysOld < 7) return 'baby';
  if (daysOld < 14) return 'toddler';
  if (daysOld < 30) return 'puppy';
  if (daysOld < 90) return 'child';
  if (daysOld < 180) return 'teen';
  if (daysOld < 365) return 'young_adult';
  return 'adult';
}

function getGrowthStage(userData) {
  if (userData.pet_xp !== undefined) {
    const xp = userData.pet_xp;
    if (xp >= XP_THRESHOLDS.adult) return 'adult';
    if (xp >= XP_THRESHOLDS.young_adult) return 'young_adult';
    if (xp >= XP_THRESHOLDS.teen) return 'teen';
    if (xp >= XP_THRESHOLDS.child) return 'child';
    if (xp >= XP_THRESHOLDS.puppy) return 'puppy';
    if (xp >= XP_THRESHOLDS.toddler) return 'toddler';
    if (xp >= XP_THRESHOLDS.baby) return 'baby';
    return 'egg';
  } else {
    return getGrowthStageByDate(userData.pet_birth_date);
  }
}

function getNextStageXP(currentStage) {
  switch(currentStage) {
    case 'egg': return XP_THRESHOLDS.baby;
    case 'baby': return XP_THRESHOLDS.toddler;
    case 'toddler': return XP_THRESHOLDS.puppy;
    case 'puppy': return XP_THRESHOLDS.child;
    case 'child': return XP_THRESHOLDS.teen;
    case 'teen': return XP_THRESHOLDS.young_adult;
    case 'young_adult': return XP_THRESHOLDS.adult;
    case 'adult': return XP_THRESHOLDS.adult;
    default: return XP_THRESHOLDS.baby;
  }
}

function getAgeMultiplier(userData) {
  const stage = getGrowthStage(userData);
  switch (stage) {
    case 'egg': return 1.0;
    case 'baby': return 1.05;
    case 'toddler': return 1.10;
    case 'puppy': return 1.30;
    case 'child': return 1.40;
    case 'teen': return 1.50;
    case 'young_adult': return 1.75;
    case 'adult': return 2.0;
    default: return 1.0;
  }
}

module.exports = {
  calculateDecay,
  getGrowthStage,
  calculatePetBonusPercent,
  calculateShopBonusPercent,
  calculateTrickBonusPercent,
  getAgeMultiplier,
  getNextStageXP,
  MAX_STAT
};
