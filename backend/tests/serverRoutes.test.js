const request = require('supertest');
const { app } = require('../server');

describe('Backend route smoke tests', () => {
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
