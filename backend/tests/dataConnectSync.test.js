jest.mock('../src/dataconnect-admin-generated', () => ({
  updateUserBalances: jest.fn().mockResolvedValue({}),
  updatePetStats: jest.fn().mockResolvedValue({}),
}));

const { updateUserBalances } = require('../src/dataconnect-admin-generated');
const { syncUserBalances } = require('../src/utils/dataConnectSync');

describe('dataConnectSync', () => {
  beforeEach(() => {
    updateUserBalances.mockClear();
  });

  it('resolves Firestore increment transforms before syncing numeric fields', async () => {
    await syncUserBalances(
      'user-123',
      {
        doge_balance: 1,
        staked_balance: 2,
        bank_balance: 3,
        offerwall_balance: 4,
        ads_balance: 5,
        xp: 10,
        total_claims: 7,
        total_faucet_claims: 8,
      },
      {
        xp: { operand: 5 },
        total_faucet_claims: { operand: 1 },
      }
    );

    expect(updateUserBalances).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 'user-123',
        xp: 15,
        faucetClaims: 9,
      })
    );
  });
});
