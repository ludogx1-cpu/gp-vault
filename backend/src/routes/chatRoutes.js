const express = require('express');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');
const router = express.Router();

const getAdminUid = () => process.env.ADMIN_UID || 'P8iffVqbUgetAVA4MdHVZ1CfvUv1';

const SWEAR_WORDS = ['fuck', 'shit', 'bitch', 'asshole', 'cunt', 'dick', 'pussy', 'bastard'];
const BEGGING_PHRASES = ['please send', 'send doge', 'need doge', 'give me', 'im poor'];
const LINK_REGEX = /(http|https|www\.)|(\.[a-zA-Z]{2,3}(\/\S*)?$)/i;

function getBanDuration(type, currentCount) {
  if (type === 'general') {
    return (currentCount + 1) * 10 * 60 * 1000;
  } else if (type === 'link') {
    const count = currentCount + 1;
    if (count === 1) return 1 * 60 * 60 * 1000; 
    if (count === 2) return 6 * 60 * 60 * 1000; 
    if (count === 3) return 12 * 60 * 60 * 1000; 
    return 12 * Math.pow(2, count - 3) * 60 * 60 * 1000; 
  }
  return 0;
}

router.post('/set-username', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Unauthorized' });
    const { username } = req.body;
    if (!username || username.trim().length < 3 || username.trim().length > 15) {
      return res.status(400).json({ success: false, error: 'Username must be 3-15 characters.' });
    }

    const cleanUsername = username.trim();
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    
    await admin.firestore().runTransaction(async (transaction) => {
      const doc = await transaction.get(userRef);
      const data = doc.data() || {};
      
      if (data.chat_username_last_changed) {
        const lastChanged = data.chat_username_last_changed.toDate();
        const daysSince = (Date.now() - lastChanged.getTime()) / (1000 * 60 * 60 * 24);
        if (daysSince < 90) {
          throw new Error(`You can only change your username once every 3 months. Try again in ${Math.ceil(90 - daysSince)} days.`);
        }
      }

      transaction.update(userRef, {
        chat_username: cleanUsername,
        chat_username_last_changed: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    res.json({ success: true, message: 'Username set successfully!' });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/send', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Unauthorized' });
    const { message } = req.body;
    
    if (!message || message.trim().length === 0 || message.length > 150) {
      return res.status(400).json({ success: false, error: 'Invalid message length.' });
    }

    const text = message.trim().toLowerCase();
    const isAdmin = req.user.uid === getAdminUid();
    
    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    let banType = null;
    let isSwear = false;

    if (!isAdmin) {
      if (LINK_REGEX.test(text)) {
        banType = 'link';
      } else {
        const hasSwear = SWEAR_WORDS.some(w => text.includes(w));
        const hasBegging = BEGGING_PHRASES.some(w => text.includes(w));
        if (hasSwear) {
          banType = 'general';
          isSwear = true;
        } else if (hasBegging) {
          banType = 'general';
        }
      }
    }

    let resultMessage = 'Message sent.';

    await admin.firestore().runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw new Error('User not found.');
      const data = userDoc.data() || {};

      if (data.chat_ban_until && data.chat_ban_until.toDate().getTime() > Date.now()) {
        const mins = Math.ceil((data.chat_ban_until.toDate().getTime() - Date.now()) / 60000);
        throw new Error(`You are currently banned from chat. Expires in ${mins} minutes.`);
      }

      if (banType) {
        let banCountField = banType === 'general' ? 'chat_ban_count_general' : 'chat_ban_count_links';
        let currentCount = Number(data[banCountField] || 0);
        
        let banDurationMs = getBanDuration(banType, currentCount);
        let banUntil = new Date(Date.now() + banDurationMs);

        let updates = {
          chat_ban_until: admin.firestore.Timestamp.fromDate(banUntil),
          [banCountField]: currentCount + 1
        };

        if (isSwear) {
          throw new Error('SWEAR_JAR_VIOLATION'); 
        } else {
          transaction.update(userRef, updates);
          throw new Error(`BAN_VIOLATION_${banType.toUpperCase()}`);
        }
      }

      let displayName = data.chat_username;
      if (!displayName) {
        if (req.user.email) displayName = req.user.email.split('@')[0];
        else displayName = "User";
      }

      const msgRef = admin.firestore().collection('chat_messages').doc();
      transaction.set(msgRef, {
        uid: req.user.uid,
        display_name: displayName,
        message: message.trim(),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        is_admin: isAdmin
      });
    });

    res.json({ success: true, message: resultMessage });

  } catch (error) {
    if (error.message === 'SWEAR_JAR_VIOLATION') {
      const userRef = admin.firestore().collection('users').doc(req.user.uid);
      const jarRef = admin.firestore().collection('system').doc('swear_jar');

      let shouldPayout = false;
      let payoutAmount = 0;

      await admin.firestore().runTransaction(async (tx) => {
        const doc = await tx.get(userRef);
        const jarDoc = await tx.get(jarRef);
        
        const data = doc.data() || {};
        const count = Number(data.chat_ban_count_general || 0);
        const banDurationMs = getBanDuration('general', count);
        
        const currentBalance = Number(data.doge_balance || 0);
        const deduction = Math.min(0.005, currentBalance);
        const newBalance = currentBalance - deduction;

        const currentJar = jarDoc.exists ? Number(jarDoc.data().balance || 0) : 0;
        const newJar = currentJar + deduction;

        tx.update(userRef, {
          doge_balance: newBalance,
          chat_ban_until: admin.firestore.Timestamp.fromDate(new Date(Date.now() + banDurationMs)),
          chat_ban_count_general: count + 1
        });

        if (newJar >= 0.05) {
          shouldPayout = true;
          payoutAmount = newJar;
          tx.set(jarRef, { balance: 0 });
        } else {
          tx.set(jarRef, { balance: newJar });
        }
      });

      if (shouldPayout) {
        // Distribute payout in the background so we don't block the response
        (async () => {
          try {
            const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);
            const messagesSnapshot = await admin.firestore().collection('chat_messages')
              .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(threeHoursAgo))
              .get();
              
            const activeUids = new Set();
            messagesSnapshot.forEach(d => {
              const dData = d.data();
              if (dData.uid && dData.uid !== getAdminUid()) activeUids.add(dData.uid);
            });

            if (activeUids.size > 0) {
              const payoutPerUser = payoutAmount / activeUids.size;
              const batch = admin.firestore().batch();
              
              for (const uid of activeUids) {
                const uRef = admin.firestore().collection('users').doc(uid);
                await admin.firestore().runTransaction(async (tx) => {
                  const uDoc = await tx.get(uRef);
                  if (uDoc.exists) {
                    const data = uDoc.data();
                    let history = data.reward_history || [];
                    history.unshift({ sector: 'Chat Rain', amount: payoutPerUser, timestamp: Date.now() });
                    if (history.length > 15) history = history.slice(0, 15);
                    tx.update(uRef, {
                      doge_balance: Number(data.doge_balance || 0) + payoutPerUser,
                      reward_history: history
                    });
                  }
                });
              }

              const msgRef = admin.firestore().collection('chat_messages').doc();
              batch.set(msgRef, {
                uid: 'system',
                display_name: '🐾 Golden Paw System',
                message: `The Swear Jar containing ${payoutAmount.toFixed(5)} DOGE was automatically shared equally among ${activeUids.size} active chatters!`,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                is_admin: true
              });

              await batch.commit();
            }
          } catch (err) {
            console.error("Auto payout failed:", err);
          }
        })();
      }
      return res.status(400).json({ 
        success: false, 
        error: "Swear Jar! You have been fined up to 0.005 DOGE and temporarily banned from chat." 
      });
    } else if (error.message.startsWith('BAN_VIOLATION_')) {
      return res.status(400).json({ 
        success: false, 
        error: "Message blocked due to rule violation. You have been temporarily banned." 
      });
    }

    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/payout-jar', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user || req.user.uid !== getAdminUid()) {
      return res.status(401).json({ success: false, error: 'Admin only' });
    }

    const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);
    
    const messagesSnapshot = await admin.firestore().collection('chat_messages')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(threeHoursAgo))
      .get();
      
    const activeUids = new Set();
    messagesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.uid && data.uid !== getAdminUid()) {
        activeUids.add(data.uid);
      }
    });

    if (activeUids.size === 0) {
      return res.json({ success: true, message: 'No active users found in the last 3 hours to payout to.' });
    }

    const jarRef = admin.firestore().collection('system').doc('swear_jar');
    
    await admin.firestore().runTransaction(async (transaction) => {
      const jarDoc = await transaction.get(jarRef);
      if (!jarDoc.exists) throw new Error('Swear jar not found.');
      
      const balance = Number(jarDoc.data().balance || 0);
      if (balance <= 0) throw new Error('Swear jar is empty.');

      const payoutPerUser = balance / activeUids.size;

      // Update all users
      for (const uid of activeUids) {
        const userRef = admin.firestore().collection('users').doc(uid);
        const userDoc = await transaction.get(userRef);
        if (userDoc.exists) {
          const data = userDoc.data();
          const currentBal = Number(data.doge_balance || 0);
          
          let history = data.reward_history || [];
          history.unshift({ sector: 'Chat Rain', amount: payoutPerUser, timestamp: Date.now() });
          if (history.length > 15) history = history.slice(0, 15);

          transaction.update(userRef, {
            doge_balance: currentBal + payoutPerUser,
            reward_history: history
          });
        }
      }

      // Reset jar
      transaction.update(jarRef, { balance: 0 });

      // Send system message
      const msgRef = admin.firestore().collection('chat_messages').doc();
      transaction.set(msgRef, {
        uid: 'system',
        display_name: '🐾 Golden Paw System',
        message: `The Swear Jar containing ${balance.toFixed(5)} DOGE was just shared equally among ${activeUids.size} active chatters!`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        is_admin: true
      });
    });

    res.json({ success: true, message: 'Jar paid out successfully!' });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/ban', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user || req.user.uid !== getAdminUid()) {
      return res.status(401).json({ success: false, error: 'Admin only' });
    }
    const { target_uid, reason } = req.body;
    if (!target_uid || !reason) {
      return res.status(400).json({ success: false, error: 'Missing target_uid or reason' });
    }

    const banType = reason === 'link' ? 'link' : 'general';
    const userRef = admin.firestore().collection('users').doc(target_uid);

    await admin.firestore().runTransaction(async (transaction) => {
      const doc = await transaction.get(userRef);
      if (!doc.exists) throw new Error('User not found');
      const data = doc.data() || {};

      let banCountField = banType === 'general' ? 'chat_ban_count_general' : 'chat_ban_count_links';
      let currentCount = Number(data[banCountField] || 0);
      let banDurationMs = getBanDuration(banType, currentCount);
      let banUntil = new Date(Date.now() + banDurationMs);

      transaction.update(userRef, {
        chat_ban_until: admin.firestore.Timestamp.fromDate(banUntil),
        [banCountField]: currentCount + 1
      });
    });

    res.json({ success: true, message: 'User banned successfully.' });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

module.exports = router;
