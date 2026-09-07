jest.mock('../src/services/priceService', () => ({
  getDogePrice: jest.fn().mockResolvedValue({ price: 0.1, source: 'test' }),
}));
jest.mock('../src/services/offerwallCronService', () => ({
  releasePendingOffers: jest.fn(), startOfferwallCronService: jest.fn(),
}));
const request = require('supertest');
const { app } = require('../server');
const { releasePendingOffers } = require('../src/services/offerwallCronService');

describe('Backend route smoke tests', () => {
  it('reports an unavailable release job without an unhandled rejection', async () => {
    const previousSecret = process.env.CRON_SECRET;
    process.env.CRON_SECRET = 'test-only';
    releasePendingOffers.mockRejectedValueOnce(new Error('Database unavailable'));
    try {
      const response = await request(app).get('/cron/trigger-offerwall-release').set('x-cron-secret', 'test-only');
      expect(response.status).toBe(503);
      expect(response.body.success).toBe(false);
    } finally {
      if (previousSecret === undefined) delete process.env.CRON_SECRET;
      else process.env.CRON_SECRET = previousSecret;
    }
  });
  it('should respond to root health endpoint', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
  });

  it('should respond to ping endpoint', async () => {
    const response = await request(app).get('/ping');
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.message).toBe('pong');
  });

  it('should return price data from the price endpoint', async () => {
    const response = await request(app).get('/price');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('success');
    expect(response.body).toHaveProperty('usdPrice');
    expect(response.body).toHaveProperty('source');
  });

  it('should reject anonymous admin update requests with 401', async () => {
    const response = await request(app)
      .post('/admin/add-update')
      .send({ title: 'Test', message: 'Test message' });

    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
  });
});
