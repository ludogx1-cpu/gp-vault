const DECAY_RATE_PER_HOUR = 2.0;
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
  energy = Math.max(0, energy - (decayAmount * 0.5));

  return { hunger, happiness, energy, hoursPassed };
}

function getGrowthStage(birthDate) {
  if (!birthDate) return 'puppy';
  const daysOld = (Date.now() - birthDate.toDate().getTime()) / (1000 * 60 * 60 * 24);
  if (daysOld < 7) return 'puppy';
  if (daysOld < 30) return 'teen';
  return 'adult';
}

function calculatePetBonusPercent(decayedStats) {
  // If stats average > 80%, give +10% bonus
  // If average > 50%, give +5%
  // If average < 20%, give 0%
  const avg = (decayedStats.hunger + decayedStats.happiness + decayedStats.energy) / 3;
  if (avg >= 80) return 10;
  if (avg >= 50) return 5;
  return 0;
}

module.exports = {
  calculateDecay,
  getGrowthStage,
  calculatePetBonusPercent,
  MAX_STAT
};
