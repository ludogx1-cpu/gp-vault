jest.mock('../src/services/firebaseService', () => ({ admin: { firestore: jest.fn() } }));
jest.mock('../src/dataconnect-admin-generated', () => ({
  updateUserBalances: jest.fn().mockResolvedValue({}), updatePetStats: jest.fn().mockResolvedValue({}),
}));
const { memoryFirestore, FieldValue } = require('./helpers/memoryFirestore');
const { admin } = require('../src/services/firebaseService');
const { updateUserBalances, updatePetStats } = require('../src/dataconnect-admin-generated');
const { retryFailedDataConnectSyncs } = require('../src/services/dataconnectRetryCron');
let db;
beforeEach(() => {
  db = memoryFirestore();
  admin.firestore.mockReturnValue(db);
  admin.firestore.FieldValue = FieldValue;
  jest.clearAllMocks();
});
test('legacy retry rebuilds current balances and supplies the missing ID', async () => {
  db.rows.set('users/u1', { doge_balance: 8 });
  db.rows.set('failed_dataconnect_syncs/old', {
    uid: 'u1', mutationType: 'UpdateUserBalances', status: 'pending', payload: { dogeBalance: 50 },
  });
  await retryFailedDataConnectSyncs();
  expect(updateUserBalances).toHaveBeenCalledWith(expect.objectContaining({ id: 'u1', dogeBalance: 8 }));
  expect(db.rows.has('failed_dataconnect_syncs/old')).toBe(false);
});
test('pet recovery uses current stats rather than the failed historical payload', async () => {
  db.rows.set('users/u1', { pet_hunger: 20 });
  db.rows.set('failed_dataconnect_syncs/old', {
    uid: 'u1', mutationType: 'UpdatePetStats', status: 'pending', payload: { petHunger: 100 },
  });
  await retryFailedDataConnectSyncs();
  expect(updatePetStats).toHaveBeenCalledWith(expect.objectContaining({ id: 'u1', petHunger: 20 }));
});
test('failed recovery retains the queue entry and increments retry count', async () => {
  db.rows.set('users/u1', { doge_balance: 8 });
  db.rows.set('failed_dataconnect_syncs/old', {
    uid: 'u1', mutationType: 'UpdateUserBalances', status: 'pending', retryCount: 4,
  });
  updateUserBalances.mockRejectedValueOnce(new Error('offline'));
  await retryFailedDataConnectSyncs();
  expect(db.rows.get('failed_dataconnect_syncs/old')).toMatchObject({ status: 'failed', retryCount: 5 });
});
