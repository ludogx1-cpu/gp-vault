jest.mock('../src/services/firebaseService', () => ({
  admin: { firestore: jest.fn() },
  isAdmin: jest.fn(),
  verifyFirebaseToken: (req, res, next) => {
    req.user = req.headers['x-test-uid'] ? { uid: req.headers['x-test-uid'] } : null;
    next();
  },
}));

const express = require('express');
const request = require('supertest');
const { memoryFirestore } = require('./helpers/memoryFirestore');
const { admin, isAdmin } = require('../src/services/firebaseService');
const adminRoutes = require('../src/routes/adminRoutes');

const app = express();
app.use(express.json());
app.use('/admin', adminRoutes);

test('only the admin can export newsletter emails, de-duplicated and sorted', async () => {
  const db = memoryFirestore();
  admin.firestore.mockReturnValue(db);
  isAdmin.mockImplementation(async uid => uid === 'boss');
  db.rows.set('subscribers/a', { email: 'Zed@Example.com ' });
  db.rows.set('subscribers/b', { email: 'amy@example.com' });
  db.rows.set('subscribers/c', { email: 'zed@example.com' });
  db.rows.set('subscribers/d', { email: 'not an email' });

  expect((await request(app).get('/admin/subscribers')).status).toBe(401);
  expect((await request(app).get('/admin/subscribers').set('x-test-uid', 'someone')).status).toBe(403);
  const res = await request(app).get('/admin/subscribers').set('x-test-uid', 'boss');
  expect(res.status).toBe(200);
  expect(res.body.emails).toEqual(['amy@example.com', 'zed@example.com']);
});
