jest.mock('../src/services/firebaseService', () => ({
  admin: { firestore: jest.fn(), storage: jest.fn() },
  isAdmin: jest.fn(),
  verifyFirebaseToken: (req, res, next) => {
    req.user = req.headers['x-test-uid'] ? { uid: req.headers['x-test-uid'] } : null;
    next();
  },
}));

const express = require('express');
const request = require('supertest');
const sharp = require('sharp');
const { memoryFirestore, FieldValue } = require('./helpers/memoryFirestore');
const { admin, isAdmin } = require('../src/services/firebaseService');
const dogbookRoutes = require('../src/routes/dogbookRoutes');

const app = express();
app.use(express.json());
app.use('/dogbook', dogbookRoutes);

let db;
let files;
let uid = 0;
const fresh = () => `user${++uid}`; // a new account per test keeps rate limits apart

beforeEach(() => {
  db = memoryFirestore();
  files = new Map();
  admin.firestore.mockReturnValue(db);
  admin.firestore.FieldValue = FieldValue;
  admin.storage.mockReturnValue({
    bucket: name => ({
      name,
      file: path => ({
        save: async (buffer, options) => files.set(path, { buffer, options }),
        delete: async () => files.delete(path),
      }),
    }),
  });
  isAdmin.mockImplementation(async u => u === 'boss');
});

async function photo({ withGps = false } = {}) {
  let img = sharp({ create: { width: 3000, height: 2000, channels: 3, background: '#c9a227' } }).jpeg();
  if (withGps) img = img.withExif({ IFD0: { Make: 'PhoneCo', Model: 'Secret Phone' } });
  return img.toBuffer();
}

async function share(user, fields = {}) {
  const req = request(app).post('/dogbook/posts').set('x-test-uid', user)
    .field('dog_name', fields.dog_name ?? 'Biscuit')
    .field('caption', fields.caption ?? 'First walk on the beach!');
  if (fields.photo !== null) req.attach('photo', fields.photo || await photo(), 'dog.jpg');
  return req;
}

test('sharing a post cleans the photo and saves a visible post', async () => {
  const user = fresh();
  db.rows.set(`users/${user}`, { chat_username: 'BiscuitMum' });
  const res = await share(user, { photo: await photo({ withGps: true }) });
  expect(res.status).toBe(200);
  const post = db.rows.get(`dogbook_posts/${res.body.id}`);
  expect(post).toMatchObject({ uid: user, author_name: 'BiscuitMum', dog_name: 'Biscuit', hidden: false, like_count: 0 });
  expect(post.image_url).toContain('golden-paw-database.firebasestorage.app');
  const saved = files.get(`dogbook/${res.body.id}.jpg`);
  const meta = await sharp(saved.buffer).metadata();
  expect(meta.format).toBe('jpeg');
  expect(Math.max(meta.width, meta.height)).toBe(1280);
  expect(meta.exif).toBeUndefined();
});

test('posting needs sign-in, a photo, a name and friendly text', async () => {
  expect((await request(app).post('/dogbook/posts').field('dog_name', 'x')).status).toBe(401);
  const user = fresh();
  expect((await share(user, { photo: null })).body.error).toMatch(/photo/);
  expect((await share(user, { dog_name: '' })).body.error).toMatch(/name/);
  expect((await share(user, { caption: 'see www.scam.xyz' })).body.error).toMatch(/Links/);
  expect((await share(user, { caption: 'what a shit day' })).body.error).toMatch(/friendly/);
  expect((await share(user, { photo: Buffer.from('not an image') })).body.error).toMatch(/JPG/);
  expect((await share(user, { dog_name: 'Shih Tzu Dickens' })).status).toBe(200);
});

test('banned accounts cannot post or comment', async () => {
  const user = fresh();
  db.rows.set(`users/${user}`, { dogbook_banned: true });
  expect((await share(user)).status).toBe(403);
  db.rows.set('dogbook_posts/p1', { uid: 'other', hidden: false, comment_count: 0 });
  const res = await request(app).post('/dogbook/posts/p1/comments').set('x-test-uid', user).send({ text: 'hi' });
  expect(res.status).toBe(403);
});

test('likes toggle once per person', async () => {
  db.rows.set('dogbook_posts/p1', { uid: 'owner', hidden: false, like_count: 0 });
  const user = fresh();
  const like = () => request(app).post('/dogbook/posts/p1/like').set('x-test-uid', user);
  expect((await like()).body.liked).toBe(true);
  expect(db.rows.get('dogbook_posts/p1').like_count).toBe(1);
  expect((await like()).body.liked).toBe(false);
  expect(db.rows.get('dogbook_posts/p1').like_count).toBe(0);
  expect(db.rows.has(`dogbook_likes/p1_${user}`)).toBe(false);
});

test('comments are added, counted and only deletable by their author or the admin', async () => {
  db.rows.set('dogbook_posts/p1', { uid: 'owner', hidden: false, comment_count: 0 });
  const user = fresh();
  const res = await request(app).post('/dogbook/posts/p1/comments').set('x-test-uid', user).send({ text: 'So fluffy!' });
  expect(res.status).toBe(200);
  expect(db.rows.get(`dogbook_comments/${res.body.id}`)).toMatchObject({ post_id: 'p1', text: 'So fluffy!', hidden: false });
  expect(db.rows.get('dogbook_posts/p1').comment_count).toBe(1);
  expect((await request(app).delete(`/dogbook/comments/${res.body.id}`).set('x-test-uid', 'stranger')).status).toBe(403);
  expect((await request(app).delete(`/dogbook/comments/${res.body.id}`).set('x-test-uid', user)).status).toBe(200);
  expect(db.rows.get('dogbook_posts/p1').comment_count).toBe(0);
});

test('deleting a post removes its photo, comments and likes', async () => {
  const user = fresh();
  const res = await share(user);
  const id = res.body.id;
  await request(app).post(`/dogbook/posts/${id}/comments`).set('x-test-uid', 'friend').send({ text: 'aww' });
  await request(app).post(`/dogbook/posts/${id}/like`).set('x-test-uid', 'friend');
  expect((await request(app).delete(`/dogbook/posts/${id}`).set('x-test-uid', 'stranger')).status).toBe(403);
  expect((await request(app).delete(`/dogbook/posts/${id}`).set('x-test-uid', user)).status).toBe(200);
  expect([...db.rows.keys()].filter(k => k.startsWith('dogbook_'))).toEqual([]);
  expect(files.size).toBe(0);
});

test('three different reports hide a post; repeat and self reports are refused', async () => {
  db.rows.set('dogbook_posts/p1', { uid: 'owner', dog_name: 'Rex', caption: 'hi', hidden: false, report_count: 0 });
  const report = u => request(app).post('/dogbook/report').set('x-test-uid', u).send({ type: 'post', id: 'p1', reason: 'Not a dog' });
  expect((await report('owner')).status).toBe(400);
  expect((await report('r1')).status).toBe(200);
  expect((await report('r1')).status).toBe(409);
  expect((await report('r2')).status).toBe(200);
  expect(db.rows.get('dogbook_posts/p1').hidden).toBe(false);
  expect((await report('r3')).status).toBe(200);
  expect(db.rows.get('dogbook_posts/p1').hidden).toBe(true);
  const bad = await request(app).post('/dogbook/report').set('x-test-uid', 'r4').send({ type: 'post', id: 'p1', reason: 'made up' });
  expect(bad.status).toBe(400);
});

test('hidden posts cannot be liked or commented on', async () => {
  db.rows.set('dogbook_posts/p1', { uid: 'owner', hidden: true });
  expect((await request(app).post('/dogbook/posts/p1/like').set('x-test-uid', fresh())).status).toBe(404);
  expect((await request(app).post('/dogbook/posts/p1/comments').set('x-test-uid', fresh()).send({ text: 'hi' })).status).toBe(404);
});

test('blocking adds and removes accounts from the list', async () => {
  const user = fresh();
  db.rows.set(`users/${user}`, { email: 'a@b.c' });
  const block = (target, blocked) => request(app).post('/dogbook/block').set('x-test-uid', user).send({ uid: target, blocked });
  expect((await block('pest', true)).body.blocked).toEqual(['pest']);
  expect((await block('pest', true)).body.blocked).toEqual(['pest']);
  expect((await block('pest', false)).body.blocked).toEqual([]);
  expect((await block(user, true)).status).toBe(400);
  expect(db.rows.get(`users/${user}`).email).toBe('a@b.c');
});

test('admin review: reports are grouped, and remove + ban deletes the post and stops the author', async () => {
  db.rows.set('users/owner', { email: 'o@x' });
  db.rows.set('dogbook_posts/p1', { uid: 'owner', dog_name: 'Rex', caption: 'buy coins', hidden: false, report_count: 0 });
  db.rows.set('dogbook_posts/p2', { uid: 'nice', dog_name: 'Bo', caption: 'cute', hidden: false, report_count: 0 });
  for (const u of ['a', 'b']) {
    await request(app).post('/dogbook/report').set('x-test-uid', u).send({ type: 'post', id: 'p1', reason: 'Spam' });
  }
  await request(app).post('/dogbook/report').set('x-test-uid', 'c').send({ type: 'post', id: 'p2', reason: 'Something else' });

  expect((await request(app).get('/dogbook/reports').set('x-test-uid', 'a')).status).toBe(401);
  const list = await request(app).get('/dogbook/reports').set('x-test-uid', 'boss');
  expect(list.body.reports.find(r => r.target_key === 'post_p1')).toMatchObject({ reporters: 2, reasons: ['Spam'], reported_uid: 'owner' });

  const resolve = (key, action) => request(app).post('/dogbook/reports/resolve').set('x-test-uid', 'boss').send({ target_key: key, action });
  expect((await resolve('post_p1', 'banned')).status).toBe(200);
  expect(db.rows.has('dogbook_posts/p1')).toBe(false);
  expect(db.rows.get('users/owner').dogbook_banned).toBe(true);

  db.rows.get('dogbook_posts/p2').hidden = true;
  expect((await resolve('post_p2', 'kept')).status).toBe(200);
  expect(db.rows.get('dogbook_posts/p2')).toMatchObject({ hidden: false, report_count: 0 });

  const open = await request(app).get('/dogbook/reports').set('x-test-uid', 'boss');
  expect(open.body.reports).toEqual([]);
  const handled = await request(app).get('/dogbook/reports?status=handled').set('x-test-uid', 'boss');
  expect(handled.body.reports.map(r => r.action).sort()).toEqual(['banned', 'kept']);
});
