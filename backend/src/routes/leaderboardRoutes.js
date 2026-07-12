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

function getAIBotScores() {
  const now = new Date();
  const dayOfWeek = now.getDay(); // 0 is Sunday
  const hourOfDay = now.getHours();
  const hoursSinceReset = (dayOfWeek * 24) + hourOfDay;
  
  const bots = [];
  
  for (let i = 0; i < AI_USERNAMES.length; i++) {
     const name = AI_USERNAMES[i];
     const petName = AI_PET_NAMES[i];
     
     // AI bots are pretty good but not perfect. 
     // Let's say they keep their pet stats above 40% for 60% to 95% of the time.
     const efficiency = 0.60 + (seededRandom(i) * 0.35); // 0.60 to 0.95
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
          username: data.username || 'Anonymous',
          pet_name: data.pet_name || 'Golden Paw Shiba',
          weekly_time_above_40: data.weekly_time_above_40,
          is_ai: false
        });
      }
    });
    
    const aiBots = getAIBotScores();
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
