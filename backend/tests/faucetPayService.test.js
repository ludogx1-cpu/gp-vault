jest.mock('axios', () => ({ post: jest.fn() }));
const axios = require('axios');
const { faucetPaySend } = require('../src/services/faucetPayService');
const originalKey = process.env.FAUCETPAY_API_KEY;
beforeEach(() => { process.env.FAUCETPAY_API_KEY = 'test-only'; axios.post.mockReset(); });
afterAll(() => {
  if (originalKey === undefined) delete process.env.FAUCETPAY_API_KEY;
  else process.env.FAUCETPAY_API_KEY = originalKey;
});
test('converts a decimal reward to exact integer smallest units', async () => {
  axios.post.mockResolvedValue({ data: { status: 200 } });
  await faucetPaySend('address', '1.00000003');
  expect(new URLSearchParams(axios.post.mock.calls[0][1]).get('amount')).toBe('100000003');
});
test('a timeout is never classified as a definite rejection', async () => {
  axios.post.mockRejectedValue(new Error('timeout'));
  await expect(faucetPaySend('address', '1')).rejects.not.toHaveProperty('paymentDefinitelyNotSent', true);
});
test('an explicit processor rejection is classified for refund', async () => {
  axios.post.mockResolvedValue({ data: { status: 402, message: 'Insufficient funds' } });
  await expect(faucetPaySend('address', '1')).rejects.toHaveProperty('paymentDefinitelyNotSent', true);
});
