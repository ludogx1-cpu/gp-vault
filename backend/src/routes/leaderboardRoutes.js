const express = require('express');
const { admin } = require('../services/firebaseService');
const router = express.Router();

const AI_USERNAMES = [
  "DogeLover99", "CryptoKing", "MoonWalker", "ShibaFanatic", 
  "DiamondHands", "FaucetHunter", "GoldenPawPro", "SatoshiN", 
  "Hodler4Life", "MuchWow"
];

const AI_PET_NAMES = [
  "Doge", "Fluffy", "Rex", "Bella", "Luna", "Max", "Rocky", "Charlie", "Buddy", "Daisy"
];

function seededRandom(seed) {
    let t = seed += 0x6D2B79F5;
    t = Math.imul(t ^ t >>> 15, t | 1);
    t ^= t + Math.imul(t ^ t >>> 7, t | 61);
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
}

function getAIBotScores(hoursSinceReset) {
  const bots = [];
  
  for (let i = 0; i < AI_USERNAMES.length; i++) {
     const name = AI_USERNAMES[i];
     const petName = AI_PET_NAMES[i];
     
     // AI bots are now significantly less strict, giving real users a solid chance to win!
     // They will keep their stats above 40% for only 5% to 25% of the time.
     const efficiency = 0.05 + (seededRandom(i) * 0.20); // 0.05 to 0.25
     const score = Math.floor(hoursSinceReset * efficiency);
     
     bots.push({
       uid: `ai_bot_${i}`,
       username: name,
       pet_name: petName,
       weekly_time_above_40: score,
       is_ai: true
     });
  }
  
  return bots;
}

router.get('/', async (req, res) => {
  try {
    const snapshot = await admin.firestore().collection('users')
      .orderBy('weekly_time_above_40', 'desc')
      .limit(50)
      .get();
      
    const realUsers = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.weekly_time_above_40 && data.weekly_time_above_40 > 0) {
        realUsers.push({
          uid: doc.id,
          username: data.username || data.chat_username || 'Anonymous',
          pet_name: data.pet_name || 'Golden Paw Shiba',
          weekly_time_above_40: data.weekly_time_above_40,
          is_ai: false
        });
      }
    });
    
    const now = new Date();
    const hoursSinceReset = (now.getDay() * 24) + now.getHours();
    
    const aiBots = getAIBotScores(hoursSinceReset);
    const combined = [...realUsers, ...aiBots];
    
    combined.sort((a, b) => b.weekly_time_above_40 - a.weekly_time_above_40);
    
    const top50 = combined.slice(0, 50);
    
    res.json({ success: true, leaderboard: top50 });
  } catch (error) {
    console.error("Error fetching leaderboard:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
