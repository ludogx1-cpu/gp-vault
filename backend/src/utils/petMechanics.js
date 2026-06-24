const DECAY_RATE_PER_HOUR = 5.0;
const MAX_STAT = 100;

function calculateDecay(userData) {
  const now = Date.now();
  const lastInteraction = userData.pet_last_interaction ? userData.pet_last_interaction.toDate().getTime() : now;
  const hoursPassed = (now - lastInteraction) / (1000 * 60 * 60);

  const decayAmount = hoursPassed * DECAY_RATE_PER_HOUR;

  let hunger = Number(userData.pet_hunger ?? 50);
  let happiness = Number(userData.pet_happiness ?? 50);
  let energy = Number(userData.pet_energy ?? 50);

  hunger = Math.max(0, hunger - decayAmount);
  happiness = Math.max(0, happiness - decayAmount);
  energy = Math.max(0, energy - decayAmount);

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
  const avg = (decayedStats.hunger + decayedStats.happiness + decayedStats.energy) / 3;
  let baseBonus = 0;
  if (avg >= 80) baseBonus = 10;
  else if (avg >= 50) baseBonus = 5;

  let happinessPenalty = 0;
  if (decayedStats.happiness <= 0) happinessPenalty = -20;
  else if (decayedStats.happiness <= 25) happinessPenalty = -15;
  else if (decayedStats.happiness <= 50) happinessPenalty = -10;
  else if (decayedStats.happiness <= 75) happinessPenalty = -5;

  return baseBonus + happinessPenalty; // Penalty applied directly to total bonus
}

function calculateShopBonusPercent(userData) {
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
  const trickBonuses = {
    'Spin': 10,
    'Jump': 20,
    'Roll Over': 30,
    'Backflip': 50,
    'Moonwalk': 100
  };

  let trickBonus = 0;
  const activeTricks = userData.active_trick_buffs || [];
  for (const trick of activeTricks) {
    if (trickBonuses[trick]) trickBonus += trickBonuses[trick];
  }
  return trickBonus;
}


function getAgeMultiplier(birthDate) {
  if (!birthDate) return 1.0;
  const daysOld = (Date.now() - birthDate.toDate().getTime()) / (1000 * 60 * 60 * 24);
  
  if (daysOld < 2) return 1.0; // Egg: 0%
  if (daysOld < 7) return 1.05; // Baby: 5%
  if (daysOld < 14) return 1.10; // Toddler: 10%
  if (daysOld < 30) return 1.30; // Puppy: 30%
  if (daysOld < 90) return 1.40; // Child: 40%
  if (daysOld < 180) return 1.50; // Teen: 50%
  if (daysOld < 365) return 1.75; // Young Adult: 75%
  return 2.0; // Adult: 100%
}

module.exports = {
  calculateDecay,
  getGrowthStage,
  calculatePetBonusPercent,
  calculateShopBonusPercent,
  calculateTrickBonusPercent,
  getAgeMultiplier,
  MAX_STAT
};
