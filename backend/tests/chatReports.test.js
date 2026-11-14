jest.mock('../src/services/firebaseService', () => ({
  admin: { firestore: jest.fn() },
  isAdmin: jest.fn(),
  verifyFirebaseToken: (req, res, next) => {
    req.user = req.headers['x-test-uid'] ? { uid: req.headers['x-test-uid'] } : null;
    next();
  },
}));
jest.mock('../src/utils/dataConnectSync', () => ({ syncUserBalances: jest.fn().mockResolvedValue() }));

const express = require('express');
const request = require('supertest');
const { memoryFirestore, FieldValue } = require('./helpers/memoryFirestore');
const { admin, isAdmin } = require('../src/services/firebaseService');
const chatRoutes = require('../src/routes/chatRoutes');

const app = express();
app.use(express.json());
app.use('/chat', chatRoutes);

let db;
const ts = ms => ({ toDate: () => new Date(ms) });
beforeEach(() => {
  db = memoryFirestore();
  admin.firestore.mockReturnValue(db);
  admin.firestore.FieldValue = FieldValue;
  isAdmin.mockImplementation(async uid => uid === 'boss');
  db.rows.set('chat_messages/m1', { message: 'buy my scam coin', uid: 'bad' });
  db.rows.set('chat_messages/m2', { message: 'hello', uid: 'nice' });
  db.rows.set('chat_reports/r1', { reporter_uid: 'a', reported_uid: 'bad', message_id: 'm1', message_text: 'buy my scam coin', reason: 'Spam or scam', timestamp: ts(2000) });
  db.rows.set('chat_reports/r2', { reporter_uid: 'b', reported_uid: 'nice', message_id: 'm2', message_text: 'hello', reason: 'Other', timestamp: ts(1000) });
});

test('only the admin can list or resolve reports', async () => {
  expect((await request(app).get('/chat/reports').set('x-test-uid', 'someone')).status).toBe(401);
  expect((await request(app).post('/chat/reports/r1/resolve').set('x-test-uid', 'someone').send({ action: 'removed' })).status).toBe(401);
  expect(db.rows.has('chat_messages/m1')).toBe(true);
});

test('admin sees open reports newest first', async () => {
  const res = await request(app).get('/chat/reports').set('x-test-uid', 'boss');
  expect(res.status).toBe(200);
  expect(res.body.reports.map(r => r.id)).toEqual(['r1', 'r2']);
});

test('removing deletes the message and records the decision', async () => {
  const res = await request(app).post('/chat/reports/r1/resolve').set('x-test-uid', 'boss').send({ action: 'removed' });
  expect(res.status).toBe(200);
  expect(db.rows.has('chat_messages/m1')).toBe(false);
  expect(db.rows.get('chat_reports/r1')).toMatchObject({ status: 'handled', action: 'removed', handled_by: 'boss' });
  const open = await request(app).get('/chat/reports').set('x-test-uid', 'boss');
  expect(open.body.reports.map(r => r.id)).toEqual(['r2']);
  const handled = await request(app).get('/chat/reports?status=handled').set('x-test-uid', 'boss');
  expect(handled.body.reports.map(r => r.id)).toEqual(['r1']);
});

test('dismissing keeps the message', async () => {
  const res = await request(app).post('/chat/reports/r2/resolve').set('x-test-uid', 'boss').send({ action: 'dismissed' });
  expect(res.status).toBe(200);
  expect(db.rows.has('chat_messages/m2')).toBe(true);
  expect(db.rows.get('chat_reports/r2')).toMatchObject({ status: 'handled', action: 'dismissed' });
});

test('rejects unknown actions and missing reports', async () => {
  expect((await request(app).post('/chat/reports/r1/resolve').set('x-test-uid', 'boss').send({ action: 'nuke' })).status).toBe(400);
  expect((await request(app).post('/chat/reports/nope/resolve').set('x-test-uid', 'boss').send({ action: 'removed' })).status).toBe(404);
});
