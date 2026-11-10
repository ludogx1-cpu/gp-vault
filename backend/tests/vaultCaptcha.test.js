jest.mock('../src/services/firebaseService', () => ({
  admin: { firestore: jest.fn() },
  isAdmin: jest.fn().mockResolvedValue(false),
}));
jest.mock('../src/services/priceService', () => ({
  getDogePrice: jest.fn().mockResolvedValue({ price: 0.1, source: 'test' }),
}));
jest.mock('../src/utils/helpers', () => ({
  ...jest.requireActual('../src/utils/helpers'),
  verifyCaptchaToken: jest.fn(),
}));
jest.mock('../src/utils/dataConnectSync', () => ({
  syncUserBalances: jest.fn().mockResolvedValue(),
  syncPetStats: jest.fn().mockResolvedValue(),
}));
jest.mock('../src/utils/rewardAudit', () => ({ logRewardEvent: jest.fn().mockResolvedValue() }));

const { memoryFirestore, FieldValue } = require('./helpers/memoryFirestore');
const { admin } = require('../src/services/firebaseService');
const { verifyCaptchaToken } = require('../src/utils/helpers');
const { claimVault } = require('../src/services/faucetService');

let db;
beforeEach(() => {
  db = memoryFirestore();
  admin.firestore.mockReturnValue(db);
  admin.firestore.FieldValue = FieldValue;
  admin.firestore.Timestamp = { now: () => ({ toDate: () => new Date() }) };
  verifyCaptchaToken.mockReset();
  db.rows.set('users/u1', { doge_balance: 0, xp: 0 });
});
const user = { uid: 'u1', email_verified: true, email: 'example@example.com' };

test('vault claim without a captcha is rejected before any balance change', async () => {
  await expect(claimVault(user)).rejects.toMatchObject({ message: 'Missing captcha verification data', statusCode: 400 });
  expect(verifyCaptchaToken).not.toHaveBeenCalled();
  expect(db.rows.get('users/u1').doge_balance).toBe(0);
});

test('vault claim with a failed captcha is rejected', async () => {
  verifyCaptchaToken.mockResolvedValue(false);
  await expect(claimVault(user, 'bad-token', 'turnstile')).rejects.toMatchObject({ message: 'Invalid captcha token', statusCode: 400 });
  expect(db.rows.get('users/u1').doge_balance).toBe(0);
});

test('vault claim with a valid captcha credits the vault', async () => {
  verifyCaptchaToken.mockResolvedValue(true);
  const result = await claimVault(user, 'good-token', 'Turnstile');
  expect(verifyCaptchaToken).toHaveBeenCalledWith('good-token', 'Turnstile');
  expect(result.earned).toBeGreaterThan(0);
  expect(db.rows.get('users/u1').doge_balance).toBeGreaterThan(0);
});
