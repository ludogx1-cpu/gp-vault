const { admin } = require('./firebaseService');

const PRIZES = [3, 2, 1, 0.5, 0.25];

function startWeeklyResetService() {
  console.log("Weekly Reset Service started.");

  let lastProcessedWeek = -1;

  // Check every hour
  setInterval(async () => {
    try {
      const now = new Date();
      const dateString = now.toISOString().split('T')[0];
      
      // Reset at Sunday (0) 00:00 (midnight to 1 AM)
      if (now.getDay() === 0 && now.getHours() === 0) {
        if (lastProcessedWeek !== dateString) {
          lastProcessedWeek = dateString;
          console.log("Starting weekly leaderboard reset and prize distribution...");
          await processWeeklyReset();
        }
      }
    } catch (e) {
      console.error("Error in weekly reset service:", e);
    }
  }, 60 * 60 * 1000); 
}

async function processWeeklyReset() {
  const usersRef = admin.firestore().collection('users');
  const snapshot = await usersRef.where('weekly_time_above_40', '>', 0).get();
  
  const AI_USERNAMES = [
    "DogeLover99", "CryptoKing", "MoonWalker", "ShibaFanatic", 
    "DiamondHands", "FaucetHunter", "GoldenPawPro", "SatoshiN", 
    "Hodler4Life", "MuchWow"
  ];

  function seededRandom(seed) {
      let t = seed += 0x6D2B79F5;
      t = Math.imul(t ^ t >>> 15, t | 1);
      t ^= t + Math.imul(t ^ t >>> 7, t | 61);
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
  }

  const aiBots = [];
  const hoursSinceReset = 168; // 1 week
  for (let i = 0; i < AI_USERNAMES.length; i++) {
     const name = AI_USERNAMES[i];
     const efficiency = 0.10 + (seededRandom(i) * 0.30); // 0.10 to 0.40
     const score = Math.floor(hoursSinceReset * efficiency);
     aiBots.push({
       uid: `ai_bot_${i}`,
       username: name,
       weekly_time_above_40: score,
       is_ai: true
     });
  }

  const realUsers = [];
  snapshot.forEach(doc => {
    const data = doc.data();
    realUsers.push({
      uid: doc.id,
      userRef: doc.ref,
      username: data.username || 'Anonymous',
      weekly_time_above_40: data.weekly_time_above_40,
      doge_balance: data.doge_balance || 0,
      reward_history: data.reward_history || []
    });
  });

  const combined = [...realUsers, ...aiBots];
  combined.sort((a, b) => b.weekly_time_above_40 - a.weekly_time_above_40);

  // Distribute prizes to top 5
  for (let i = 0; i < 5; i++) {
    const winner = combined[i];
    if (!winner) break;
    
    if (!winner.is_ai) {
      const prize = PRIZES[i];
      let history = winner.reward_history;
      history.unshift({ sector: `Leaderboard Prize (Rank ${i+1})`, amount: prize, timestamp: Date.now() });
      if (history.length > 15) history = history.slice(0, 15);

      await winner.userRef.update({
        doge_balance: Number(winner.doge_balance) + prize,
        reward_history: history
      });
      console.log(`Awarded ${prize} DOGE to ${winner.username} for rank ${i+1}`);
    } else {
      console.log(`AI Bot ${winner.username} took rank ${i+1}, no payout required.`);
    }
  }

  // Reset all real users' scores
  for (let doc of snapshot.docs) {
      await doc.ref.update({ weekly_time_above_40: 0 });
  }
  
  console.log("Weekly leaderboard reset complete!");
}

module.exports = { startWeeklyResetService };
