const express = require('express');
const { admin } = require('../services/firebaseService');
const router = express.Router();

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
    
    realUsers.sort((a, b) => b.weekly_time_above_40 - a.weekly_time_above_40);

    res.json({ success: true, leaderboard: realUsers });
  } catch (error) {
    console.error("Error fetching leaderboard:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
