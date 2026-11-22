jest.mock('../src/services/firebaseService', () => ({
  admin: { firestore: jest.fn() },
  verifyFirebaseToken: (req, res, next) => {
    req.user = req.headers['x-test-uid'] ? { uid: req.headers['x-test-uid'] } : null;
    next();
  },
}));

const express = require('express');
const request = require('supertest');
const { memoryFirestore, FieldValue } = require('./helpers/memoryFirestore');
const { admin } = require('../src/services/firebaseService');
const gpawsRoutes = require('../src/routes/gpawsRoutes');
const { pendingPooCount } = require('../src/services/petCareService');

const app = express();
app.use(express.json());
app.use('/gpaws', gpawsRoutes);

let db;
let now;
let uid = 0;
const fresh = () => `g${++uid}`;
beforeEach(() => {
  db = memoryFirestore();
  admin.firestore.mockReturnValue(db);
  admin.firestore.FieldValue = FieldValue;
  now = 1_800_000_000_000;
  jest.spyOn(Date, 'now').mockImplementation(() => now);
});
afterEach(() => jest.restoreAllMocks());

const spawn = u => request(app).post('/gpaws/spawn').set('x-test-uid', u);
const collect = (u, id) => request(app).post('/gpaws/collect').set('x-test-uid', u).send({ id });

test('signed-out players get nothing', async () => {
  expect((await request(app).post('/gpaws/spawn')).status).toBe(401);
});

test('a paw can be collected once, after a moment, before it expires', async () => {
  const u = fresh();
  const paw = (await spawn(u)).body.paw;
  expect(paw.id).toBeTruthy();
  expect((await collect(u, paw.id)).status).toBe(429); // too fast
  now += 3000;
  const ok = await collect(u, paw.id);
  expect(ok.status).toBe(200);
  expect(ok.body.gpaws).toBe(1);
  expect(db.rows.get(`users/${u}`)).toMatchObject({ gpaws: 1, gpaws_lifetime: 1 });
  expect((await collect(u, paw.id)).status).toBe(410); // already collected
  expect((await collect(fresh(), paw.id)).status).toBe(410); // someone else's paw
});

test('expired paws cannot be collected', async () => {
  const u = fresh();
  const paw = (await spawn(u)).body.paw;
  now += 2 * 60 * 1000;
  expect((await collect(u, paw.id)).status).toBe(410);
});

test('paws are spaced out and never more than 5 in an hour', async () => {
  const u = fresh();
  let handedOut = 0;
  const start = now;
  while (now - start < 60 * 60 * 1000) {
    const r = (await spawn(u)).body;
    if (r.paw) {
      handedOut += 1;
      now += 2000;
      await collect(u, r.paw.id);
      now += 1000;
    } else {
      expect(r.retry_ms).toBeGreaterThan(0);
      now += 30 * 1000;
    }
  }
  expect(handedOut).toBeGreaterThanOrEqual(3);
  expect(handedOut).toBeLessThanOrEqual(5);
});

test('poo now builds up once every 4 hours, one at a time', () => {
  const h = 3600000;
  expect(pendingPooCount(now - 1 * h, now)).toBe(0);
  expect(pendingPooCount(now - 4 * h, now)).toBe(1);
  expect(pendingPooCount(now - 30 * h, now)).toBe(1);
});
