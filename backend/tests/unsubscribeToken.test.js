describe('unsubscribe tokens', () => {
  const OLD = process.env.UNSUBSCRIBE_SECRET;
  beforeEach(() => { process.env.UNSUBSCRIBE_SECRET = 'test-secret'; jest.resetModules(); });
  afterAll(() => { if (OLD === undefined) delete process.env.UNSUBSCRIBE_SECRET; else process.env.UNSUBSCRIBE_SECRET = OLD; });

  test('a signed link verifies only for its own user', () => {
    const { unsubscribeToken, isValidUnsubscribeToken, unsubscribeUrl } = require('../src/utils/unsubscribeToken');
    const token = unsubscribeToken('user-a');
    expect(isValidUnsubscribeToken('user-a', token)).toBe(true);
    expect(isValidUnsubscribeToken('user-b', token)).toBe(false);
    expect(isValidUnsubscribeToken('user-a', token.slice(0, -1) + (token.endsWith('A') ? 'B' : 'A'))).toBe(false);
    expect(isValidUnsubscribeToken('user-a', undefined)).toBe(false);
    expect(unsubscribeUrl('user-a')).toBe(`https://golden-paw-vault.onrender.com/unsubscribe/user-a/${token}`);
  });

  test('without any secret no link is produced and nothing verifies', () => {
    delete process.env.UNSUBSCRIBE_SECRET;
    const saved = { k: process.env.FIREBASE_PRIVATE_KEY, j: process.env.FIREBASE_SERVICE_ACCOUNT_JSON };
    delete process.env.FIREBASE_PRIVATE_KEY; delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    const { unsubscribeUrl, isValidUnsubscribeToken } = require('../src/utils/unsubscribeToken');
    expect(unsubscribeUrl('user-a')).toBeNull();
    expect(isValidUnsubscribeToken('user-a', 'anything')).toBe(false);
    if (saved.k !== undefined) process.env.FIREBASE_PRIVATE_KEY = saved.k;
    if (saved.j !== undefined) process.env.FIREBASE_SERVICE_ACCOUNT_JSON = saved.j;
  });
});
