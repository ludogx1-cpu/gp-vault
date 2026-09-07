jest.mock('../src/services/firebaseService', () => ({ admin: { firestore: jest.fn() } }));
jest.mock('../src/services/faucetPayService', () => ({ faucetPaySend: jest.fn() }));
jest.mock('../src/utils/dataConnectSync', () => ({ syncUserBalances: jest.fn().mockResolvedValue() }));
jest.mock('../src/utils/rewardAudit', () => ({ logRewardEvent: jest.fn().mockResolvedValue() }));

const { memoryFirestore, FieldValue } = require('./helpers/memoryFirestore');
const { admin } = require('../src/services/firebaseService');
const { faucetPaySend } = require('../src/services/faucetPayService');
const { withdraw, settleWithdrawal } = require('../src/services/withdrawalService');
const { releasePendingOffers } = require('../src/services/offerwallCronService');
const { bankWithdraw } = require('../src/services/faucetService');
let db;
beforeEach(() => {
  db = memoryFirestore();
  admin.firestore.mockReturnValue(db);
  admin.firestore.FieldValue = FieldValue;
  admin.firestore.Timestamp = { now: () => ({ toDate: () => new Date() }) };
  faucetPaySend.mockReset().mockResolvedValue({ status: 200, payout_id: 12 });
  db.rows.set('users/u1', { doge_balance: 5, pending_offer_balance: 3, offerwall_balance: 0 });
});
const user = { uid: 'u1', email_verified: true, email: 'example@example.com' };

test('Vault payout debits once and settlement is idempotent', async () => {
  const result = await withdraw(user, 'address', 1);
  await settleWithdrawal(result.withdrawalId, 'succeeded');
  expect(db.rows.get('users/u1')).toMatchObject({ doge_balance: 4, total_withdrawn: 1 });
  expect(db.rows.get('users/u1').pending_withdrawal).toBeUndefined();
  expect(faucetPaySend).toHaveBeenCalledTimes(1);
});
test('definite rejection refunds exactly once', async () => {
  faucetPaySend.mockRejectedValue(Object.assign(new Error('Rejected'), { paymentDefinitelyNotSent: true }));
  await expect(withdraw(user, 'address', 1)).rejects.toThrow('refunded');
  const id = [...db.rows.keys()].find(key => key.startsWith('withdrawal_requests/')).split('/')[1];
  await settleWithdrawal(id, 'refunded');
  expect(db.rows.get('users/u1').doge_balance).toBe(5);
  expect([...db.rows.keys()].filter(key => key.startsWith('withdrawals/'))).toHaveLength(0);
});
test('timeout retains debit and blocks a second send until reconciled', async () => {
  faucetPaySend.mockRejectedValue(new Error('timeout'));
  await expect(withdraw(user, 'address', 1)).rejects.toThrow('confirmation is delayed');
  expect(db.rows.get('users/u1').doge_balance).toBe(4);
  await expect(withdraw(user, 'address', 1)).rejects.toThrow('awaiting confirmation');
  expect(faucetPaySend).toHaveBeenCalledTimes(1);
});
test('failed debit commit never calls the payment processor', async () => {
  db.failCommit = true;
  await expect(withdraw(user, 'address', 1)).rejects.toThrow('interrupted');
  expect(faucetPaySend).not.toHaveBeenCalled();
  expect(db.rows.get('users/u1').doge_balance).toBe(5);
});
test('paid withdrawals cannot subsequently be refunded', async () => {
  const result = await withdraw(user, 'address', 1);
  await expect(settleWithdrawal(result.withdrawalId, 'refunded')).rejects.toThrow('Conflicting');
});
test('database failure after payment preserves evidence for idempotent reconciliation', async () => {
  faucetPaySend.mockImplementation(async () => {
    db.failCommit = true;
    return { status: 200, payout_id: 12 };
  });
  await expect(withdraw(user, 'address', 1)).rejects.toThrow('Payment was sent');
  const id = db.rows.get('users/u1').pending_withdrawal;
  expect(db.rows.get(`withdrawal_requests/${id}`)).toMatchObject({ status: 'paid', faucetPayResponse: { payout_id: 12 } });
  db.failCommit = false;
  await settleWithdrawal(id, 'succeeded');
  await settleWithdrawal(id, 'succeeded');
  expect(db.rows.get('users/u1')).toMatchObject({ doge_balance: 4, total_withdrawn: 1 });
  expect(faucetPaySend).toHaveBeenCalledTimes(1);
});
test('concurrent Vault withdrawal requests cannot both send', async () => {
  const results = await Promise.allSettled([withdraw(user, 'address', 1), withdraw(user, 'address', 1)]);
  expect(results.filter(result => result.status === 'fulfilled')).toHaveLength(1);
  expect(faucetPaySend).toHaveBeenCalledTimes(1);
});
test('offerwall payment pause remains unconditional', async () => {
  await expect(bankWithdraw(user, 'address', 1)).rejects.toThrow('temporarily disabled');
  expect(faucetPaySend).not.toHaveBeenCalled();
});

function offer(id, days = 8) {
  db.rows.set(`offerwall_transactions/${id}`, {
    userId: 'u1', amount: 1, status: 'pending',
    timestamp: { toDate: () => new Date(Date.now() - days * 86400000) },
  });
}
test('overlapping and repeated offer releases credit each transaction once', async () => {
  offer('a'); offer('b'); offer('not-ready', 1);
  await Promise.all([releasePendingOffers(), releasePendingOffers()]);
  await releasePendingOffers();
  expect(db.rows.get('users/u1')).toMatchObject({ offerwall_balance: 2, pending_offer_balance: 1 });
  expect(db.rows.get('offerwall_transactions/not-ready').status).toBe('pending');
});
test('interrupted release leaves both reward and balance unchanged for a safe retry', async () => {
  offer('a');
  db.failCommit = true;
  await releasePendingOffers();
  expect(db.rows.get('offerwall_transactions/a').status).toBe('pending');
  expect(db.rows.get('users/u1').offerwall_balance).toBe(0);
  db.failCommit = false;
  await releasePendingOffers();
  expect(db.rows.get('users/u1').offerwall_balance).toBe(1);
});
test('more than 500 releases do not reuse a committed batch', async () => {
  for (let i = 0; i < 501; i++) offer(String(i));
  await releasePendingOffers();
  expect(db.rows.get('users/u1').offerwall_balance).toBe(501);
});
