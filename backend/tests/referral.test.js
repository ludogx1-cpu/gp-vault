jest.mock('../src/services/firebaseService', () => ({
  admin: { firestore: jest.fn(), auth: jest.fn() },
  isAdmin: jest.fn().mockResolvedValue(false),
}));
jest.mock('../src/utils/rewardAudit', () => ({ logRewardEvent: jest.fn().mockResolvedValue() }));
jest.mock('../src/utils/dataConnectSync', () => ({ syncUserBalances: jest.fn().mockResolvedValue() }));

const { memoryFirestore, FieldValue } = require('./helpers/memoryFirestore');
const { admin } = require('../src/services/firebaseService');
const { logRewardEvent } = require('../src/utils/rewardAudit');
const { claimReferral, payReferralBonus, getReferralStats } = require('../src/services/referralService');

const REFERRER = 'AbCdEfGh1234567890referrer';
const NEWBIE = 'NewUser0001xxxxxxxxxxxxxxxx';
let db;
let accountCreated;

beforeEach(() => {
  db = memoryFirestore();
  admin.firestore.mockReturnValue(db);
  admin.firestore.FieldValue = FieldValue;
  admin.firestore.FieldPath = { documentId: () => '__name__' };
  accountCreated = new Date();
  admin.auth.mockReturnValue({ getUser: async () => ({ metadata: { creationTime: accountCreated.toUTCString() } }) });
  db.rows.set(`users/${REFERRER}`, { doge_balance: 1 });
  db.rows.set(`users/${NEWBIE}`, { doge_balance: 0 });
  logRewardEvent.mockClear();
});

const newbie = { uid: NEWBIE, email_verified: true };

describe('claiming a referral code', () => {
  test('links a new account to the referrer from the 8-character code', async () => {
    const result = await claimReferral(newbie, 'AbCdEfGh');
    expect(result.linked).toBe(true);
    expect(db.rows.get(`users/${NEWBIE}`).referred_by).toBe(REFERRER);
    expect(db.rows.get(`users/${REFERRER}`).referral_count).toBe(1);
  });

  test('only links once', async () => {
    await claimReferral(newbie, 'AbCdEfGh');
    const again = await claimReferral(newbie, 'AbCdEfGh');
    expect(again.linked).toBe(false);
    expect(db.rows.get(`users/${REFERRER}`).referral_count).toBe(1);
  });

  test('rejects own code, unknown, ambiguous and malformed codes', async () => {
    await expect(claimReferral({ uid: REFERRER }, 'AbCdEfGh')).rejects.toMatchObject({ statusCode: 400 });
    await expect(claimReferral(newbie, 'Zzzzzzzz')).rejects.toThrow('not found');
    db.rows.set('users/AbCdEfGhOTHERuser', {});
    await expect(claimReferral(newbie, 'AbCdEfGh')).rejects.toThrow('not found');
    await expect(claimReferral(newbie, 'bad code!')).rejects.toThrow('not valid');
    expect(db.rows.get(`users/${NEWBIE}`).referred_by).toBeUndefined();
  });

  test('only works for accounts created in the last 7 days', async () => {
    accountCreated = new Date(Date.now() - 8 * 86400000);
    await expect(claimReferral(newbie, 'AbCdEfGh')).rejects.toThrow('within 7 days');
  });
});

describe('paying the referral bonus', () => {
  beforeEach(async () => { await claimReferral(newbie, 'AbCdEfGh'); });

  test('pays the referrer 20% of a claim without touching the claimer', async () => {
    const bonus = await payReferralBonus(newbie, 0.001);
    expect(bonus).toBeCloseTo(0.0002, 8);
    expect(db.rows.get(`users/${REFERRER}`).doge_balance).toBeCloseTo(1.0002, 8);
    expect(db.rows.get(`users/${NEWBIE}`).doge_balance).toBe(0);
    expect(db.rows.get(`users/${NEWBIE}`).referral_earnings_for_parent).toBeCloseTo(0.0002, 8);
    expect(logRewardEvent).toHaveBeenCalledWith(REFERRER, 'referral_bonus', bonus, { from: NEWBIE });
  });

  test('pays nothing for unverified emails or users with no referrer', async () => {
    expect(await payReferralBonus({ uid: NEWBIE, email_verified: false }, 0.001)).toBe(0);
    expect(await payReferralBonus({ uid: REFERRER, email_verified: true }, 0.001)).toBe(0);
    expect(db.rows.get(`users/${REFERRER}`).doge_balance).toBe(1);
  });

  test('a failure never throws into the faucet claim', async () => {
    admin.firestore.mockReturnValueOnce({ collection: () => { throw new Error('db down'); } });
    await expect(payReferralBonus(newbie, 0.001)).resolves.toBe(0);
  });

  test('stats list invited users with short IDs and totals', async () => {
    await payReferralBonus(newbie, 0.001);
    const stats = await getReferralStats(REFERRER);
    expect(stats.referrals).toEqual([{ id: 'NewUser0', earned: expect.closeTo(0.0002, 8) }]);
    expect(stats.total).toBeCloseTo(0.0002, 8);
    expect(stats.rate).toBe(0.2);
  });
});
