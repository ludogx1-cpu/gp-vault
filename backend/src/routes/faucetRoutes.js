const express = require('express');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');
const { faucetPaySend } = require('../services/faucetPayService');
const { getDogePrice } = require('../services/priceService');
const { calculateDogeReward } = require('../utils/rewardCalculator');
const { formatAmount, verifyCaptchaToken } = require('../utils/helpers');

const router = express.Router();

const getAdminUid = () => process.env.ADMIN_UID || 'P8iffVqbUgetAVA4MdHVZ1CfvUv1';

router.post('/send-doge', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for faucet claim' });
    }

    if (!req.user.email_verified) {
      return res.status(403).json({ success: false, error: 'Email verification required.' });
    }

    const { address: bodyAddress, user_address, captcha_token, captcha_provider, source } = req.body;
    const address = bodyAddress || user_address;
    if (!address) {
      return res.status(400).json({ success: false, error: 'Missing destination address' });
    }

    if (req.user.uid !== getAdminUid()) {
      if (!captcha_token || !captcha_provider) {
        return res.status(400).json({ success: false, error: 'Missing captcha verification data' });
      }
      const isCaptchaValid = await verifyCaptchaToken(captcha_token, captcha_provider);
      if (!isCaptchaValid) {
        return res.status(400).json({ success: false, error: 'Invalid captcha token' });
      }
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    const cooldownMs = 5 * 60 * 1000; 

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw new Error('User profile not found');
      }

      const data = snapshot.data() || {};
      const lastDirectClaim = data.last_direct_faucet_claim;

      if (lastDirectClaim && Date.now() - lastDirectClaim.toDate().getTime() < cooldownMs) {
        const minutesLeft = Math.ceil((cooldownMs - (Date.now() - lastDirectClaim.toDate().getTime())) / 60000);
        throw new Error(`Please wait ${minutesLeft} minutes before claiming again.`);
      }

      transaction.update(userRef, {
        last_direct_faucet_claim: admin.firestore.Timestamp.now()
      });
    });

    const priceResult = await getDogePrice();
    const price = priceResult.price;
    const dogeAmount = calculateDogeReward(price);

    const faucetPayResponse = await faucetPaySend(address, dogeAmount);

    const resultPayload = {
      success: true,
      address,
      amount: dogeAmount,
      usdPrice: price,
      priceSource: priceResult.source,
      faucetPayResponse,
      source: source || 'send-doge',
      captchaToken: captcha_token || 'Admin Bypass',
      captchaProvider: captcha_provider || 'Admin Bypass',
      authUser: req.user || null,
    };

    console.log('Send DOGE success:', JSON.stringify({ address, amount: dogeAmount }));
    res.json(resultPayload);
  } catch (error) {
    console.error('send-doge error:', error.response?.data || error.message || error);
    res.status(500).json({
      success: false,
      error: error.message || error.response?.data?.message || 'Failed to send DOGE',
    });
  }
});

router.post('/claim-vault', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for vault claim' });
    }

    console.log('Claim vault request for user:', req.user.uid);

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    const now = admin.firestore.Timestamp.now();
    const cooldownMs = 5 * 60 * 1000; 

    const priceResult = await getDogePrice();
    const price = priceResult.price;
    const baseReward = calculateDogeReward(price);

    let finalReward = 0;

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw new Error('User profile not found');
      }

      const data = snapshot.data() || {};
      
      const lastClaim = data.last_claim_time;
      if (lastClaim && Date.now() - lastClaim.toDate().getTime() < cooldownMs) {
        const secondsLeft = Math.ceil((cooldownMs - (Date.now() - lastClaim.toDate().getTime())) / 1000);
        const cooldownError = new Error(`Cooldown active. Try again in ${secondsLeft} seconds.`);
        cooldownError.statusCode = 429;
        throw cooldownError;
      }

      const xp = Number(data.xp || 0);
      const streak = Number(data.streak_count || 0);
      let level = Math.floor(Math.sqrt(xp / 100));
      if (level > 100) level = 100;
      
      const totalBonusPercent = level + streak;
      finalReward = baseReward * (1 + (totalBonusPercent / 100));

      transaction.update(userRef, {
        doge_balance: Number(data.doge_balance || 0) + finalReward,
        xp: xp + 10,
        last_claim_time: now,
      });
    });

    res.json({
      success: true,
      message: 'Vault claim verified. Your reward has been recorded.',
      earned: finalReward,
      authUser: req.user.uid,
    });
  } catch (error) {
    console.error('claim-vault error:', error.response?.data || error.message || error);
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Failed to claim vault',
    });
  }
});

router.post('/withdraw', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for withdrawal' });
    }

    if (!req.user.email_verified) {
      return res.status(403).json({ success: false, error: 'Email verification required to withdraw.' });
    }

    const { user_address, amount } = req.body;
    if (!user_address) {
      return res.status(400).json({ success: false, error: 'Missing destination address' });
    }

    const sendAmount = Number(amount);
    
    const MIN_WITHDRAWAL = 1; 
    if (!Number.isFinite(sendAmount) || sendAmount < MIN_WITHDRAWAL) {
      return res.status(400).json({ success: false, error: `Minimum withdrawal is ${MIN_WITHDRAWAL} DOGE` });
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    const cooldownMs = 60 * 1000; 

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw new Error('User profile not found');
      }

      const data = snapshot.data();
      const currentBalance = Number(data.doge_balance || 0);
      const lastWithdrawal = data.last_withdrawal;

      if (lastWithdrawal && Date.now() - lastWithdrawal.toDate().getTime() < cooldownMs) {
        throw new Error('Please wait a minute between withdrawals.');
      }

      if (currentBalance < sendAmount) {
        throw new Error('Insufficient balance for this withdrawal.');
      }

      transaction.update(userRef, {
        doge_balance: currentBalance - sendAmount,
        last_withdrawal: admin.firestore.Timestamp.now()
      });
    });

    const formattedAmount = formatAmount(sendAmount);
    const faucetPayResponse = await faucetPaySend(user_address, formattedAmount);

    const resultPayload = {
      success: true,
      address: user_address,
      amount: formattedAmount,
      faucetPayResponse,
      authUser: req.user,
    };

    console.log('Withdraw request:', JSON.stringify(resultPayload));
    res.json(resultPayload);
  } catch (error) {
    console.error('withdraw error:', error.response?.data || error.message || error);
    res.status(500).json({
      success: false,
      error: error.message || error.response?.data || 'Failed to process withdrawal',
    });
  }
});

router.post('/claim-bonus-sponsor', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required for sponsor bonus claim' });
    }

    const { captcha_token, captcha_provider } = req.body;
    
    if (req.user.uid !== getAdminUid()) {
      if (!captcha_token || !captcha_provider) {
        return res.status(400).json({ success: false, error: 'Missing captcha verification data' });
      }
      const isCaptchaValid = await verifyCaptchaToken(captcha_token, captcha_provider);
      if (!isCaptchaValid) {
        return res.status(400).json({ success: false, error: 'Invalid captcha token' });
      }
    }

    const userRef = admin.firestore().collection('users').doc(req.user.uid);
    const rewardAmount = 0.006;
    const xpReward = 60;
    const cooldownMs = 3 * 60 * 60 * 1000;
    const now = admin.firestore.Timestamp.now();

    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw new Error('User profile not found');
      }

      const data = snapshot.data() || {};
      const lastClaim = data.last_bonus_sponsor_claim;
      if (lastClaim && Date.now() - lastClaim.toDate().getTime() < cooldownMs) {
        const minutesLeft = Math.ceil((cooldownMs - (Date.now() - lastClaim.toDate().getTime())) / 60000);
        const cooldownError = new Error(`Sponsor bonus cooldown active. Try again in ${minutesLeft} minutes.`);
        cooldownError.statusCode = 429;
        throw cooldownError;
      }

      transaction.update(userRef, {
        doge_balance: Number(data.doge_balance || 0) + rewardAmount,
        xp: Number(data.xp || 0) + xpReward,
        last_bonus_sponsor_claim: now,
      });
    });

    res.json({
      success: true,
      message: 'Sponsor bonus claim processed successfully',
      rewardAmount,
      xpReward,
    });
  } catch (error) {
    console.error('claim-bonus-sponsor error:', error.message || error);
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Failed to process sponsor bonus claim',
    });
  }
});

module.exports = router;
