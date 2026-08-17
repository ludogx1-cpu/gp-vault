const { admin, isAdmin: checkIsAdmin } = require('./firebaseService');
const { faucetPaySend } = require('./faucetPayService');
const { logTransaction } = require('./ledgerService');
const { getDogePrice } = require('./priceService');
const { calculateDogeReward } = require('../utils/rewardCalculator');
const { formatAmount, verifyCaptchaToken, getStreakUpdates } = require('../utils/helpers');
const { calculateDecay, calculateTrickBonusPercent, getAgeMultiplier } = require('../utils/petMechanics');
const { logRewardEvent } = require('../utils/rewardAudit');

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

async function verifyCaptcha(userUid, token, provider) {
  if (!(await checkIsAdmin(userUid))) {
    if (!token || !provider) {
      throw new Error('Missing captcha verification data');
    }
    const isValid = await verifyCaptchaToken(token, provider);
    if (!isValid) {
      throw new Error('Invalid captcha token');
    }
  }
}

async function sendDoge(user, address, captcha_token, captcha_provider, source) {
  if (!user.email_verified) throw new Error('Email verification required.');
  if (!address) throw new Error('Missing destination address');
  await verifyCaptcha(user.uid, captcha_token, captcha_provider);

  const userRef = admin.firestore().collection('users').doc(user.uid);
  const cooldownMs = 5 * 60 * 1000;
  let ageMult = 1.0;

  await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) throw new Error('User profile not found');
    const data = snapshot.data() || {};
    const lastDirectClaim = data.last_direct_faucet_claim;

    if (lastDirectClaim && Date.now() - lastDirectClaim.toDate().getTime() < cooldownMs) {
      const minutesLeft = Math.ceil((cooldownMs - (Date.now() - lastDirectClaim.toDate().getTime())) / 60000);
      throw new Error(`Please wait ${minutesLeft} minutes before claiming again.`);
    }

    const streakUpdates = getStreakUpdates(data);
    if (data.pet_birth_date) {
      const decayed = calculateDecay(data);
      ageMult = getAgeMultiplier(data);
      transaction.update(userRef, {
        last_direct_faucet_claim: admin.firestore.Timestamp.now(),
        pet_hunger: decayed.hunger,
        pet_happiness: decayed.happiness,
        pet_energy: decayed.energy,
        pet_last_interaction: admin.firestore.FieldValue.serverTimestamp(),
        ...streakUpdates
      });
    } else {
      transaction.update(userRef, {
        last_direct_faucet_claim: admin.firestore.Timestamp.now(),
        ...streakUpdates
      });
    }
  });

  const priceResult = await getDogePrice();
  const price = priceResult.price;
  let dogeAmount = calculateDogeReward(price) * ageMult;
  dogeAmount = Math.min(dogeAmount, 0.072);

  const faucetPayResponse = await faucetPaySend(address, dogeAmount);

  try {
    await userRef.update({
      total_faucet_claims: admin.firestore.FieldValue.increment(1),
      total_earned: admin.firestore.FieldValue.increment(dogeAmount)
    });
    await logRewardEvent(user.uid, 'faucet_claim', dogeAmount, { sector: 'Direct Send', address });
  } catch (metricErr) {
    console.error('Failed to update lifetime metrics for direct claim:', metricErr);
  }

  return {
    address,
    amount: dogeAmount,
    usdPrice: price,
    priceSource: priceResult.source,
    faucetPayResponse,
    source: source || 'send-doge',
    captchaToken: captcha_token || 'Admin Bypass',
    captchaProvider: captcha_provider || 'Admin Bypass',
    authUser: user
  };
}

async function claimVault(user) {
  const userRef = admin.firestore().collection('users').doc(user.uid);
  const now = admin.firestore.Timestamp.now();
  const cooldownMs = 5 * 60 * 1000;
  const priceResult = await getDogePrice();
  const baseReward = calculateDogeReward(priceResult.price);
  let finalReward = 0;

  await admin.firestore().runTransaction(async (transaction) => {
    const petRef = userRef.collection('pet').doc('status');
    const snapshot = await transaction.get(userRef);
    let data = snapshot.data() || {};
    const petSnapshot = await transaction.get(petRef);
    Object.assign(data, petSnapshot.data() || {});
    
    let isNewUser = false;
    if (!snapshot.exists) {
      isNewUser = true;
      data = {
        email: user.email || 'unknown@example.com',
        doge_balance: 0.0,
        staked_balance: 0.0,
        ads_balance: 0.0,
        offerwall_balance: 0.0,
        xp: 0,
        streak_count: 0,
        joined_date: new Date().toISOString()
      };
    }

    const lastClaim = data.last_claim_time;
    if (lastClaim && Date.now() - lastClaim.toDate().getTime() < cooldownMs) {
      const secondsLeft = Math.ceil((cooldownMs - (Date.now() - lastClaim.toDate().getTime())) / 1000);
      const cooldownError = new Error(`Cooldown active. Try again in ${secondsLeft} seconds.`);
      cooldownError.statusCode = 429;
      throw cooldownError;
    }

    const xp = Number(data.xp || 0);
    const streakUpdates = getStreakUpdates(data);
    const streak = streakUpdates.streak_count !== undefined ? streakUpdates.streak_count : Number(data.streak_count || 0);
    let level = Math.floor(Math.sqrt(xp / 100));
    if (level > 100) level = 100;
    
    let ageMult = 1.0;
    let streakMultiplier = 1.0;
    if (streak == 2) streakMultiplier = 1.1;
    else if (streak == 3) streakMultiplier = 1.2;
    else if (streak == 4) streakMultiplier = 1.3;
    else if (streak == 5) streakMultiplier = 1.4;
    else if (streak == 6) streakMultiplier = 1.5;
    else if (streak >= 7) streakMultiplier = 1.6;

    if (data.pet_birth_date) {
      const decayed = calculateDecay(data);
      ageMult = getAgeMultiplier(data);
    }
    
    finalReward = baseReward * (1 + (level / 100)) * streakMultiplier * ageMult;
    finalReward = Math.min(finalReward, 0.072);

    let history = data.reward_history || [];
    history.unshift({ sector: 'Vault Faucet', amount: finalReward, timestamp: Date.now() });
    if (history.length > 15) history = history.slice(0, 15);

    const updates = {
      doge_balance: Number(data.doge_balance || 0) + finalReward,
      xp: xp + 10,
      last_claim_time: now,
      reward_history: history,
      total_faucet_claims: admin.firestore.FieldValue.increment(1),
      total_earned: admin.firestore.FieldValue.increment(finalReward),
      ...streakUpdates
    };

    if (data.pet_birth_date) {
      const decayed = calculateDecay(data);
      updates.pet_hunger = decayed.hunger;
      updates.pet_happiness = decayed.happiness;
      updates.pet_energy = decayed.energy;
      updates.pet_last_interaction = admin.firestore.FieldValue.serverTimestamp();
    }

    if (isNewUser) {
      transaction.set(userRef, { ...data, ...updates });
    } else {
      const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
    }
    logTransaction(transaction, user.uid, finalReward, 'faucet_claim', { sector: 'Vault Faucet' });
  });

  await logRewardEvent(user.uid, 'faucet_claim', finalReward, { sector: 'Vault Faucet' });

  return { earned: finalReward, authUser: user.uid };
}

async function withdraw(user, address, amount) {
  if (!user.email_verified) throw new Error('Email verification required to withdraw.');
  if (!address) throw new Error('Missing destination address');
  
  const sendAmount = Number(amount);
  if (!Number.isFinite(sendAmount) || sendAmount < 1) {
    throw new Error(`Minimum withdrawal is 1 DOGE`);
  }

  const userRef = admin.firestore().collection('users').doc(user.uid);
  const cooldownMs = 60 * 1000;

  await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) throw new Error('User profile not found');
    const data = snapshot.data();
    
    if (data.last_withdrawal && Date.now() - data.last_withdrawal.toDate().getTime() < cooldownMs) {
      throw new Error('Please wait a minute between withdrawals.');
    }
    if (Number(data.doge_balance || 0) < sendAmount) {
      throw new Error('Insufficient balance for this withdrawal.');
    }

    transaction.update(userRef, {
      doge_balance: Number(data.doge_balance || 0) - sendAmount,
      last_withdrawal: admin.firestore.Timestamp.now()
    });
  });

  let faucetPayResponse;
  try {
    faucetPayResponse = await faucetPaySend(address, formatAmount(sendAmount));
  } catch (faucetError) {
    await admin.firestore().runTransaction(async (refundTx) => {
      const snapshot = await refundTx.get(userRef);
      if (snapshot.exists) {
        refundTx.update(userRef, {
          doge_balance: Number(snapshot.data().doge_balance || 0) + sendAmount,
        });
      }
    });
    throw new Error('Payment processor is temporarily down. Your funds have been securely refunded.');
  }

  try {
    await admin.firestore().collection('withdrawals').add({
      uid: user.uid,
      email: user.email,
      amount: sendAmount,
      address,
      source: 'vault',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    logTransaction(null, user.uid, -sendAmount, 'withdrawal', { faucetPayResponse, address });
    await userRef.update({ total_withdrawn: admin.firestore.FieldValue.increment(sendAmount) });
  } catch (err) {
    console.error('Failed to log withdrawal:', err);
  }

  return { address, amount: formatAmount(sendAmount), faucetPayResponse, authUser: user };
}

async function bankWithdraw(user, address, amount) {
  throw new Error('Offerwall withdrawals are temporarily disabled while we configure backend systems. Please check the notice board for updates.');
}

async function bankTransfer(user, source, amount) {
  if (!['vault', 'offerwall'].includes(source)) throw new Error('Invalid transfer source');
  
  const transferAmount = Number(amount);
  if (!Number.isFinite(transferAmount) || transferAmount <= 0) throw new Error('Invalid transfer amount');

  const userRef = admin.firestore().collection('users').doc(user.uid);

  await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) throw new Error('User profile not found');
    const data = snapshot.data();
    const currentBankBalance = Number(data.bank_balance || 0);

    if (source === 'vault') {
      const vaultBalance = Number(data.doge_balance || 0);
      if (vaultBalance < transferAmount) throw new Error('Insufficient Vault balance for this transfer.');
      transaction.update(userRef, { doge_balance: vaultBalance - transferAmount, bank_balance: currentBankBalance + transferAmount });
    } else if (source === 'offerwall') {
      const offerwallBalance = Number(data.offerwall_balance || 0);
      if (offerwallBalance < transferAmount) throw new Error('Insufficient Offerwall balance for this transfer.');
      transaction.update(userRef, { offerwall_balance: offerwallBalance - transferAmount, bank_balance: currentBankBalance + transferAmount });
    }
  });

  return 'Transfer successful';
}

async function claimBonusSponsor(user, captcha_token, captcha_provider) {
  await verifyCaptcha(user.uid, captcha_token, captcha_provider);
  const userRef = admin.firestore().collection('users').doc(user.uid);
  const rewardAmount = 0.004;
  const xpReward = 15;
  const cooldownMs = 15 * 60 * 1000;
  let finalRewardAmount = rewardAmount;

  await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) throw new Error('User profile not found');
    const data = snapshot.data();

    if (data.last_bonus_sponsor_claim && Date.now() - data.last_bonus_sponsor_claim.toDate().getTime() < cooldownMs) {
      const minutesLeft = Math.ceil((cooldownMs - (Date.now() - data.last_bonus_sponsor_claim.toDate().getTime())) / 60000);
      const cooldownError = new Error(`Sponsor bonus cooldown active. Try again in ${minutesLeft} minutes.`);
      cooldownError.statusCode = 429;
      throw cooldownError;
    }

    const trickBonusPercent = calculateTrickBonusPercent(data);
    finalRewardAmount = rewardAmount * (1 + (trickBonusPercent / 100));

    let history = data.reward_history || [];
    history.unshift({ sector: 'Bonus Sponsor', amount: finalRewardAmount, timestamp: Date.now() });
    if (history.length > 15) history = history.slice(0, 15);

    const updates = {
      doge_balance: Number(data.doge_balance || 0) + finalRewardAmount,
      xp: Number(data.xp || 0) + xpReward,
      last_bonus_sponsor_claim: admin.firestore.Timestamp.now(),
      active_trick_buffs: [],
      reward_history: history,
    };
    transaction.update(userRef, updates);
    logTransaction(transaction, user.uid, finalRewardAmount, 'faucet_claim', { sector: 'Ads Faucet' });
  });

  await logRewardEvent(user.uid, 'faucet_claim', finalRewardAmount, { sector: 'Bonus Sponsor' });

  return { rewardAmount: finalRewardAmount, xpReward };
}

async function claimEcosystemVideo(user, captcha_token, captcha_provider) {
  await verifyCaptcha(user.uid, captcha_token, captcha_provider);
  const userRef = admin.firestore().collection('users').doc(user.uid);
  const rewardAmount = 0.003;
  const xpReward = 15;
  const cooldownMs = 30 * 60 * 1000;
  let finalRewardAmount = rewardAmount;

  await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    if (!snapshot.exists) throw new Error('User profile not found');
    const data = snapshot.data();

    if (data.last_ecosystem_video_claim && Date.now() - data.last_ecosystem_video_claim.toDate().getTime() < cooldownMs) {
      const minutesLeft = Math.ceil((cooldownMs - (Date.now() - data.last_ecosystem_video_claim.toDate().getTime())) / 60000);
      const cooldownError = new Error(`Ecosystem video cooldown active. Try again in ${minutesLeft} minutes.`);
      cooldownError.statusCode = 429;
      throw cooldownError;
    }

    const trickBonusPercent = calculateTrickBonusPercent(data);
    finalRewardAmount = rewardAmount * (1 + (trickBonusPercent / 100));

    let history = data.reward_history || [];
    history.unshift({ sector: 'Ecosystem Video', amount: finalRewardAmount, timestamp: Date.now() });
    if (history.length > 15) history = history.slice(0, 15);

    const updates = {
      doge_balance: Number(data.doge_balance || 0) + finalRewardAmount,
      xp: Number(data.xp || 0) + xpReward,
      last_ecosystem_video_claim: admin.firestore.Timestamp.now(),
      active_trick_buffs: [],
      reward_history: history,
    };
    transaction.update(userRef, updates);
    logTransaction(transaction, user.uid, finalRewardAmount, 'faucet_claim', { sector: 'Offerwall Faucet' });
  });

  await logRewardEvent(user.uid, 'faucet_claim', finalRewardAmount, { sector: 'Ecosystem Video' });

  return { rewardAmount: finalRewardAmount, xpReward };
}

module.exports = {
  sendDoge,
  claimVault,
  withdraw,
  bankWithdraw,
  bankTransfer,
  claimBonusSponsor,
  claimEcosystemVideo
};
