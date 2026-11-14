const { admin } = require('./firebaseService');
const { logRewardEvent } = require('../utils/rewardAudit');
const { syncUserBalances } = require('../utils/dataConnectSync');

// Referrers earn 20% of each faucet claim made by people they invited.
// Golden Paw pays the bonus; the invited user's own reward is not reduced.
const REFERRAL_RATE = 0.2;
// Only new accounts can be linked to a referrer.
const NEW_ACCOUNT_DAYS = 7;
const CODE_PATTERN = /^[A-Za-z0-9]{6,40}$/;

function referralError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function roundDoge(amount) {
  return Math.floor(amount * 1e8) / 1e8;
}

/** Referral codes are the start of the referrer's user ID (8 characters in shared links). */
async function findReferrerByCode(code) {
  const db = admin.firestore();
  const snap = await db.collection('users')
    .orderBy(admin.firestore.FieldPath.documentId())
    .startAt(code)
    .endAt(`${code}`)
    .limit(2)
    .get();
  // Ambiguous or unknown codes don't match anyone.
  return snap.docs.length === 1 ? snap.docs[0].id : null;
}

async function accountAgeDays(uid) {
  const record = await admin.auth().getUser(uid);
  const created = new Date(record.metadata.creationTime).getTime();
  return (Date.now() - created) / 86400000;
}

/** Links a new account to the user who invited it. Safe to call more than once. */
async function claimReferral(user, rawCode) {
  const code = String(rawCode || '').trim();
  if (!CODE_PATTERN.test(code)) throw referralError('That referral code is not valid.');

  const db = admin.firestore();
  const userRef = db.collection('users').doc(user.uid);
  const existing = await userRef.get();
  if (existing.exists && existing.data().referred_by) {
    return { linked: false, message: 'Your account is already linked to a referrer.' };
  }

  if ((await accountAgeDays(user.uid)) > NEW_ACCOUNT_DAYS) {
    throw referralError(`Referral codes can only be used within ${NEW_ACCOUNT_DAYS} days of creating your account.`);
  }

  const referrerUid = await findReferrerByCode(code);
  if (!referrerUid) throw referralError('That referral code was not found.');
  if (referrerUid === user.uid) throw referralError("You can't use your own referral code.");

  const linked = await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(userRef);
    const referrerRef = db.collection('users').doc(referrerUid);
    const referrerSnap = await transaction.get(referrerRef);
    if (snap.exists && snap.data().referred_by) return false;
    if (!referrerSnap.exists) throw referralError('That referral code was not found.');

    const updates = {
      referred_by: referrerUid,
      referred_at: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (snap.exists) transaction.update(userRef, updates);
    else transaction.set(userRef, { ...updates, joined_date: new Date().toISOString() });
    transaction.update(referrerRef, { referral_count: admin.firestore.FieldValue.increment(1) });
    return true;
  });

  return linked
    ? { linked: true, message: 'Thanks! Your account is now linked to the friend who invited you.' }
    : { linked: false, message: 'Your account is already linked to a referrer.' };
}

/**
 * Pays the referrer 20% of a faucet claim. Never throws: a failed bonus must
 * not affect the claim itself. Only email-verified users earn their referrer
 * a bonus, which makes farming with throwaway accounts harder.
 */
async function payReferralBonus(user, claimAmount) {
  try {
    if (!user || !user.email_verified || !(claimAmount > 0)) return 0;
    const bonus = roundDoge(claimAmount * REFERRAL_RATE);
    if (bonus <= 0) return 0;

    const db = admin.firestore();
    const userRef = db.collection('users').doc(user.uid);
    const result = await db.runTransaction(async (transaction) => {
      const snap = await transaction.get(userRef);
      const referrerUid = snap.exists ? snap.data().referred_by : null;
      if (!referrerUid || referrerUid === user.uid) return null;
      const referrerRef = db.collection('users').doc(referrerUid);
      const referrerSnap = await transaction.get(referrerRef);
      if (!referrerSnap.exists) return null;

      const referrerData = referrerSnap.data() || {};
      const updates = {
        doge_balance: Number(referrerData.doge_balance || 0) + bonus,
        referral_earnings_total: admin.firestore.FieldValue.increment(bonus),
        total_earned: admin.firestore.FieldValue.increment(bonus),
      };
      transaction.update(referrerRef, updates);
      transaction.update(userRef, { referral_earnings_for_parent: admin.firestore.FieldValue.increment(bonus) });
      return { referrerUid, referrerData, updates };
    });
    if (!result) return 0;

    syncUserBalances(result.referrerUid, result.referrerData, result.updates).catch(console.error);
    await logRewardEvent(result.referrerUid, 'referral_bonus', bonus, { from: user.uid });
    return bonus;
  } catch (error) {
    console.error('Referral bonus failed:', error.message);
    return 0;
  }
}

/** The referrer's invited users (short IDs only) and what each has earned them. */
async function getReferralStats(uid) {
  const snap = await admin.firestore().collection('users').where('referred_by', '==', uid).get();
  const referrals = snap.docs.map(doc => ({
    id: doc.id.slice(0, 8),
    earned: Number(doc.data().referral_earnings_for_parent || 0),
  }));
  const total = referrals.reduce((sum, r) => sum + r.earned, 0);
  return { referrals, total: roundDoge(total), rate: REFERRAL_RATE };
}

module.exports = { claimReferral, payReferralBonus, getReferralStats, findReferrerByCode, REFERRAL_RATE, NEW_ACCOUNT_DAYS };
