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

test('account email export: admin only, skips unsubscribed and disabled accounts', async () => {
  const db = memoryFirestore();
  admin.firestore.mockReturnValue(db);
  isAdmin.mockImplementation(async uid => uid === 'boss');
  db.rows.set('users/u1', { email: 'one@example.com' });
  db.rows.set('users/u2', { email: 'two@example.com', emailOptOut: true });
  db.rows.set('users/u3', {});
  db.rows.set('users/u4', { email: 'four@example.com' });
  admin.auth = jest.fn(() => ({
    listUsers: jest.fn(async (n, token) => token
      ? { users: [{ uid: 'u4', email: 'four@example.com', disabled: true }] }
      : { users: [
          { uid: 'u1', email: 'One@Example.com' },
          { uid: 'u2', email: 'two@example.com' },
          { uid: 'u3', email: 'three@example.com' },
          { uid: 'u5', email: 'five@example.com' },
        ], pageToken: 'next' }),
  }));
  expect((await request(app).get('/admin/account-emails').set('x-test-uid', 'someone')).status).toBe(403);
  const res = await request(app).get('/admin/account-emails').set('x-test-uid', 'boss');
  expect(res.status).toBe(200);
  expect(res.body.emails).toEqual(['five@example.com', 'one@example.com', 'three@example.com']);
});
