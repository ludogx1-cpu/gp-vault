// The Book Of Dog: Golden Paw's social feed for dogs.
//
// Every write goes through this server, like chat does, so text can be
// filtered, photos cleaned, banned accounts stopped, reports counted and
// notifications sent. The app reads visible content straight from Firestore
// (see firestore.rules); hidden content is only visible here, to the admin.
//
// Collections:
//   dogbook_dogs/{id}        owner_uid, name, breed, birthday, bio, photo_url,
//                            photo_path, follower_count, post_count,
//                            report_count, hidden, created_at
//   dogbook_posts/{id}       uid, author_name, dog_id, dog_name, dog_photo_url,
//                            caption (the post text), images [{url, path}],
//                            image_url/image_path (first photo, kept for older
//                            app versions), reshare_of {id, dog_id, dog_name,
//                            text, image_url}, like_count, comment_count,
//                            share_count, report_count, hidden, edited,
//                            created_at
//   dogbook_comments/{id}    post_id, parent_id ('' for top level), uid,
//                            author_name, dog_name, text, like_count,
//                            reply_count, report_count, hidden, created_at
//   dogbook_likes/{post_uid}           post_id, uid, created_at
//   dogbook_comment_likes/{comment_uid} comment_id, post_id, uid, created_at
//   dogbook_follows/{dog_uid}          dog_id, uid, created_at
//   dogbook_notifications/{id}         to_uid, type, from_name, post_id,
//                                      dog_id, text, read, created_at
//   dogbook_reports/{key_reporter}     one per person per post/comment/dog
// User fields: dogbook_banned (bool), dogbook_blocked (list of uids).

const crypto = require('crypto');
const express = require('express');
const multer = require('multer');
const rateLimit = require('express-rate-limit');
const sharp = require('sharp');
const { admin, verifyFirebaseToken, isAdmin } = require('../services/firebaseService');

const router = express.Router();

const AUTO_HIDE_REPORTS = 3;
const MAX_POST_TEXT = 1000;
const MAX_COMMENT = 300;
const MAX_DOG_NAME = 30;
const MAX_BREED = 40;
const MAX_BIO = 200;
const MAX_PHOTOS = 4;
const MAX_DOGS_PER_OWNER = 10;
const REPORT_REASONS = ['Not a dog', 'Rude or abusive', 'Spam', 'Something else'];

// Whole words only, so breeds and names such as "Shih Tzu" or "Dickens" pass.
const BLOCKED_WORDS = /\b(fuck\w*|shit|shits|shitty|bitch(es)?|assholes?|cunts?|dicks?|pussy|bastards?|nigg\w*|faggots?|retards?)\b/i;
const LINK_REGEX = /(https?:\/\/|www\.)|\b[a-z0-9-]+\.(com|net|org|io|co|uk|xyz|ru|ly|me|app|dog)\b/i;

function textProblem(text) {
  const lower = text.toLowerCase();
  if (LINK_REGEX.test(lower)) return 'Links are not allowed in The Book Of Dog.';
  if (BLOCKED_WORDS.test(lower)) return 'Please keep it friendly. That wording is not allowed.';
  return null;
}

function cleanText(value, max) {
  if (typeof value !== 'string') return '';
  return value.replace(/[\u0000-\u0008\u000B-\u001F\u007F]/g, '').trim().slice(0, max + 1);
}

function httpError(status, message) {
  const err = new Error(message);
  err.status = status;
  return err;
}

function validId(id) {
  return typeof id === 'string' && id.length > 0 && id.length <= 200 && !id.includes('/');
}

// Limits are per signed-in account (the route checks sign-in first).
const perUser = (windowMs, max, error) => rateLimit({
  windowMs,
  max,
  keyGenerator: req => (req.user ? req.user.uid : 'anon'),
  standardHeaders: true,
  legacyHeaders: false,
  validate: { keyGeneratorIpFallback: false },
  message: { success: false, error },
});
const postLimiter = perUser(60 * 60 * 1000, 10, 'You have posted a lot this hour. Please try again later.');
const commentLimiter = perUser(10 * 60 * 1000, 30, 'You are commenting too quickly. Please wait a few minutes.');
const likeLimiter = perUser(60 * 1000, 90, 'Slow down a little!');
const followLimiter = perUser(60 * 60 * 1000, 120, 'You have followed a lot of dogs this hour. Please try again later.');
const reportLimiter = perUser(60 * 60 * 1000, 30, 'You have sent a lot of reports. Please try again later.');
const profileLimiter = perUser(60 * 60 * 1000, 20, 'Too many profile changes. Please try again later.');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024, files: MAX_PHOTOS, fields: 10 },
});

function uploadMiddleware(handler) {
  return (req, res, next) => handler(req, res, err => {
    if (err) {
      const msg = err.code === 'LIMIT_FILE_SIZE' ? 'That photo is too big (10 MB max).'
        : (err.code === 'LIMIT_FILE_COUNT' || err.code === 'LIMIT_UNEXPECTED_FILE') ? `You can add up to ${MAX_PHOTOS} photos.`
          : 'Upload failed.';
      return res.status(400).json({ success: false, error: msg });
    }
    next();
  });
}

function requireUser(req, res, next) {
  if (!req.user || !req.user.uid) {
    return res.status(401).json({ success: false, error: 'Please sign in first.' });
  }
  next();
}

async function requireAdmin(req, res, next) {
  if (!req.user || !(await isAdmin(req.user.uid))) {
    return res.status(401).json({ success: false, error: 'Admin only' });
  }
  next();
}

const db = () => admin.firestore();
const now = () => admin.firestore.FieldValue.serverTimestamp();
const increment = n => admin.firestore.FieldValue.increment(n);
const col = name => db().collection(name);

function bucket() {
  const name = process.env.DOGBOOK_BUCKET
    || `${process.env.FIREBASE_PROJECT_ID || 'golden-paw-database'}.firebasestorage.app`;
  return admin.storage().bucket(name);
}

// Loads the user's profile and refuses banned accounts.
async function loadPoster(uid) {
  const snap = await col('users').doc(uid).get();
  const data = snap.exists ? snap.data() : {};
  if (data.dogbook_banned === true) {
    throw httpError(403, 'Your account can no longer post in The Book Of Dog.');
  }
  const name = data.chat_username || data.username || data.display_name || 'Dog lover';
  return { author_name: String(name).slice(0, 30) };
}

// Loads one of the signed-in player's own dogs.
async function loadOwnDog(uid, dogId) {
  if (!validId(dogId)) throw httpError(400, 'Please choose which dog is posting.');
  const snap = await col('dogbook_dogs').doc(dogId).get();
  if (!snap.exists || snap.data().owner_uid !== uid) throw httpError(404, 'Dog profile not found.');
  if (snap.data().hidden === true) throw httpError(403, 'This dog profile is under review.');
  return { id: snap.id, ...snap.data() };
}

// Shrinks the photo, turns it the right way up and re-saves it as a JPEG.
// Re-encoding drops all metadata, including any GPS location.
async function cleanPhoto(buffer, maxSide = 1280) {
  let image;
  try {
    image = sharp(buffer, { limitInputPixels: 50_000_000, failOn: 'error' });
    const meta = await image.metadata();
    if (!['jpeg', 'png', 'webp', 'gif'].includes(meta.format)) throw new Error('format');
  } catch (_) {
    throw httpError(400, 'Please choose a JPG, PNG or WebP photo.');
  }
  return image
    .rotate()
    .resize({ width: maxSide, height: maxSide, fit: 'inside', withoutEnlargement: true })
    .flatten({ background: '#ffffff' })
    .jpeg({ quality: 82, mozjpeg: true })
    .toBuffer();
}

async function savePhoto(path, jpeg) {
  const token = crypto.randomUUID();
  const b = bucket();
  await b.file(path).save(jpeg, {
    resumable: false,
    contentType: 'image/jpeg',
    metadata: { cacheControl: 'public, max-age=31536000', metadata: { firebaseStorageDownloadTokens: token } },
  });
  return `https://firebasestorage.googleapis.com/v0/b/${b.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

async function deletePhoto(path) {
  if (!path) return;
  try {
    await bucket().file(path).delete({ ignoreNotFound: true });
  } catch (e) {
    console.error('Book Of Dog: could not delete photo', path, e.message || e);
  }
}

// Sends an in-app notification (never to yourself). Failures are logged, not
// shown to the player: the action itself has already succeeded.
async function notify(toUid, fromUid, fields) {
  if (!toUid || toUid === fromUid) return;
  try {
    await col('dogbook_notifications').doc().set({
      to_uid: toUid,
      type: fields.type,
      from_name: String(fields.from_name || 'Someone').slice(0, 40),
      post_id: fields.post_id || '',
      dog_id: fields.dog_id || '',
      text: String(fields.text || '').slice(0, 120),
      read: false,
      created_at: now(),
    });
  } catch (e) {
    console.error('Book Of Dog: notification failed', e.message || e);
  }
}

function fail(res, error, fallback) {
  if (error && error.status) {
    return res.status(error.status).json({ success: false, error: error.message });
  }
  console.error(fallback, error);
  return res.status(500).json({ success: false, error: fallback });
}

// --- Dog profiles -------------------------------------------------------------

function readDogFields(body, { partial = false } = {}) {
  const out = {};
  if (!partial || body.name !== undefined) {
    const name = cleanText(body.name, MAX_DOG_NAME);
    if (!name) throw httpError(400, "Please add your dog's name.");
    if (name.length > MAX_DOG_NAME) throw httpError(400, `Dog names can be up to ${MAX_DOG_NAME} characters.`);
    out.name = name;
  }
  if (!partial || body.breed !== undefined) {
    const breed = cleanText(body.breed, MAX_BREED);
    if (breed.length > MAX_BREED) throw httpError(400, `Breeds can be up to ${MAX_BREED} characters.`);
    out.breed = breed;
  }
  if (!partial || body.bio !== undefined) {
    const bio = cleanText(body.bio, MAX_BIO);
    if (bio.length > MAX_BIO) throw httpError(400, `The bio can be up to ${MAX_BIO} characters.`);
    out.bio = bio;
  }
  if (!partial || body.birthday !== undefined) {
    const birthday = cleanText(body.birthday, 10);
    if (birthday) {
      const d = new Date(`${birthday}T00:00:00Z`);
      if (!/^\d{4}-\d{2}-\d{2}$/.test(birthday) || Number.isNaN(d.getTime()) || d.getTime() > Date.now()
        || d.getUTCFullYear() < 1990) {
        throw httpError(400, 'Please enter a valid birthday.');
      }
    }
    out.birthday = birthday;
  }
  const problem = textProblem([out.name, out.breed, out.bio].filter(Boolean).join(' '));
  if (problem) throw httpError(400, problem);
  return out;
}

router.post('/dogs', verifyFirebaseToken, requireUser, profileLimiter, uploadMiddleware(upload.single('photo')), async (req, res) => {
  try {
    const fields = readDogFields(req.body || {});
    await loadPoster(req.user.uid);
    const existing = await col('dogbook_dogs').where('owner_uid', '==', req.user.uid).get();
    if (existing.size >= MAX_DOGS_PER_OWNER) throw httpError(400, `You can add up to ${MAX_DOGS_PER_OWNER} dogs.`);

    const ref = col('dogbook_dogs').doc();
    let photo = { photo_url: '', photo_path: '' };
    if (req.file) {
      const path = `dogbook/dogs/${ref.id}-${Date.now()}.jpg`;
      photo = { photo_url: await savePhoto(path, await cleanPhoto(req.file.buffer, 640)), photo_path: path };
    }
    await ref.set({
      owner_uid: req.user.uid,
      ...fields,
      ...photo,
      follower_count: 0,
      post_count: 0,
      report_count: 0,
      hidden: false,
      created_at: now(),
    });
    res.json({ success: true, id: ref.id });
  } catch (error) {
    fail(res, error, 'Could not create the dog profile.');
  }
});

router.patch('/dogs/:id', verifyFirebaseToken, requireUser, profileLimiter, uploadMiddleware(upload.single('photo')), async (req, res) => {
  try {
    const dog = await loadOwnDog(req.user.uid, req.params.id);
    const fields = readDogFields(req.body || {}, { partial: true });
    if (req.file) {
      const path = `dogbook/dogs/${dog.id}-${Date.now()}.jpg`;
      fields.photo_url = await savePhoto(path, await cleanPhoto(req.file.buffer, 640));
      fields.photo_path = path;
    }
    await col('dogbook_dogs').doc(dog.id).update(fields);
    if (req.file) await deletePhoto(dog.photo_path);
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Could not update the dog profile.');
  }
});

async function deleteDog(dogRef, dog) {
  const posts = await col('dogbook_posts').where('dog_id', '==', dogRef.id).get();
  for (const p of posts.docs) await deletePost(p.ref, p.data());
  const follows = await col('dogbook_follows').where('dog_id', '==', dogRef.id).get();
  for (const f of follows.docs) await f.ref.delete();
  await deletePhoto(dog.photo_path);
  await dogRef.delete();
}

router.delete('/dogs/:id', verifyFirebaseToken, requireUser, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Dog profile not found.');
    const ref = col('dogbook_dogs').doc(req.params.id);
    const snap = await ref.get();
    if (!snap.exists) throw httpError(404, 'Dog profile not found.');
    if (snap.data().owner_uid !== req.user.uid && !(await isAdmin(req.user.uid))) {
      throw httpError(403, 'You can only delete your own dog profiles.');
    }
    await deleteDog(ref, snap.data());
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Could not delete the dog profile.');
  }
});

// Follow or unfollow a dog. Returns whether you now follow it.
router.post('/dogs/:id/follow', verifyFirebaseToken, requireUser, followLimiter, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Dog profile not found.');
    const dogRef = col('dogbook_dogs').doc(req.params.id);
    const followRef = col('dogbook_follows').doc(`${req.params.id}_${req.user.uid}`);
    let dog;
    const following = await db().runTransaction(async tx => {
      const d = await tx.get(dogRef);
      if (!d.exists || d.data().hidden === true) throw httpError(404, 'Dog profile not found.');
      dog = d.data();
      if (dog.owner_uid === req.user.uid) throw httpError(400, "You can't follow your own dog.");
      const f = await tx.get(followRef);
      if (f.exists) {
        tx.delete(followRef);
        tx.update(dogRef, { follower_count: increment(-1) });
        return false;
      }
      tx.set(followRef, { dog_id: req.params.id, uid: req.user.uid, created_at: now() });
      tx.update(dogRef, { follower_count: increment(1) });
      return true;
    });
    if (following) {
      const me = await loadPoster(req.user.uid).catch(() => ({ author_name: 'Someone' }));
      await notify(dog.owner_uid, req.user.uid, {
        type: 'follow', from_name: me.author_name, dog_id: req.params.id, text: dog.name,
      });
    }
    res.json({ success: true, following });
  } catch (error) {
    fail(res, error, 'Could not update the follow.');
  }
});

// --- Posts ----------------------------------------------------------------

function readPostText(body) {
  const text = cleanText(body.text !== undefined ? body.text : body.caption, MAX_POST_TEXT);
  if (text.length > MAX_POST_TEXT) throw httpError(400, `Posts can be up to ${MAX_POST_TEXT} characters.`);
  const problem = text ? textProblem(text) : null;
  if (problem) throw httpError(400, problem);
  return text;
}

// New post from one of your dogs: text, up to 4 photos, or both.
// (Older app versions send dog_name + one 'photo' and no dog_id; that still works.)
router.post('/posts', verifyFirebaseToken, requireUser, postLimiter,
  uploadMiddleware(upload.fields([{ name: 'photos', maxCount: MAX_PHOTOS }, { name: 'photo', maxCount: 1 }])),
  async (req, res) => {
    try {
      const body = req.body || {};
      const files = [...((req.files && req.files.photos) || []), ...((req.files && req.files.photo) || [])];
      if (files.length > MAX_PHOTOS) throw httpError(400, `You can add up to ${MAX_PHOTOS} photos.`);
      const text = readPostText(body);
      if (!text && files.length === 0) throw httpError(400, 'Write something or add a photo.');

      const poster = await loadPoster(req.user.uid);
      let dog = null;
      let dogName;
      if (body.dog_id) {
        dog = await loadOwnDog(req.user.uid, body.dog_id);
        dogName = dog.name;
      } else {
        dogName = cleanText(body.dog_name, MAX_DOG_NAME);
        if (!dogName) throw httpError(400, 'Please choose which dog is posting.');
        if (dogName.length > MAX_DOG_NAME) throw httpError(400, `Dog names can be up to ${MAX_DOG_NAME} characters.`);
        const problem = textProblem(dogName);
        if (problem) throw httpError(400, problem);
      }

      const cleaned = [];
      for (const f of files) cleaned.push(await cleanPhoto(f.buffer));

      const ref = col('dogbook_posts').doc();
      const images = [];
      for (let i = 0; i < cleaned.length; i++) {
        const path = `dogbook/${ref.id}-${i}.jpg`;
        images.push({ url: await savePhoto(path, cleaned[i]), path });
      }

      await ref.set({
        uid: req.user.uid,
        author_name: poster.author_name,
        dog_id: dog ? dog.id : '',
        dog_name: dogName,
        dog_photo_url: dog ? (dog.photo_url || '') : '',
        caption: text,
        images,
        image_url: images[0] ? images[0].url : '',
        image_path: images[0] ? images[0].path : '',
        like_count: 0,
        comment_count: 0,
        share_count: 0,
        report_count: 0,
        hidden: false,
        edited: false,
        created_at: now(),
      });
      if (dog) await col('dogbook_dogs').doc(dog.id).update({ post_count: increment(1) });
      res.json({ success: true, id: ref.id });
    } catch (error) {
      fail(res, error, 'Could not share your post. Please try again.');
    }
  });

// Edit your own post's text.
router.patch('/posts/:id', verifyFirebaseToken, requireUser, postLimiter, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Post not found.');
    const ref = col('dogbook_posts').doc(req.params.id);
    const snap = await ref.get();
    if (!snap.exists) throw httpError(404, 'Post not found.');
    const post = snap.data();
    if (post.uid !== req.user.uid) throw httpError(403, 'You can only edit your own posts.');
    await loadPoster(req.user.uid);
    const text = readPostText(req.body || {});
    const hasImages = (post.images && post.images.length) || post.image_url || post.reshare_of;
    if (!text && !hasImages) throw httpError(400, 'A post needs some text or a photo.');
    await ref.update({ caption: text, edited: true });
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Could not edit the post.');
  }
});

// Share a post to your own dog's feed, with optional text of your own.
router.post('/posts/:id/reshare', verifyFirebaseToken, requireUser, postLimiter, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Post not found.');
    const body = req.body || {};
    const poster = await loadPoster(req.user.uid);
    const dog = await loadOwnDog(req.user.uid, body.dog_id);
    const text = readPostText(body);

    // Re-sharing a re-share shares the original.
    let origRef = col('dogbook_posts').doc(req.params.id);
    let orig = await origRef.get();
    if (orig.exists && orig.data().reshare_of && orig.data().reshare_of.id) {
      origRef = col('dogbook_posts').doc(orig.data().reshare_of.id);
      orig = await origRef.get();
    }
    if (!orig.exists || orig.data().hidden === true) throw httpError(404, 'Post not found.');
    const o = orig.data();
    const firstImage = (o.images && o.images[0] && o.images[0].url) || o.image_url || '';

    const ref = col('dogbook_posts').doc();
    await ref.set({
      uid: req.user.uid,
      author_name: poster.author_name,
      dog_id: dog.id,
      dog_name: dog.name,
      dog_photo_url: dog.photo_url || '',
      caption: text,
      images: [],
      image_url: '',
      image_path: '',
      reshare_of: {
        id: origRef.id,
        dog_id: o.dog_id || '',
        dog_name: o.dog_name || '',
        text: String(o.caption || '').slice(0, 280),
        image_url: firstImage,
      },
      like_count: 0,
      comment_count: 0,
      share_count: 0,
      report_count: 0,
      hidden: false,
      edited: false,
      created_at: now(),
    });
    await origRef.update({ share_count: increment(1) });
    await col('dogbook_dogs').doc(dog.id).update({ post_count: increment(1) });
    await notify(o.uid, req.user.uid, {
      type: 'reshare', from_name: dog.name, post_id: origRef.id, text: o.caption,
    });
    res.json({ success: true, id: ref.id });
  } catch (error) {
    fail(res, error, 'Could not share the post.');
  }
});

// Counts a share outside the site (link copied or shared to another app).
router.post('/posts/:id/shared', verifyFirebaseToken, requireUser, likeLimiter, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Post not found.');
    const ref = col('dogbook_posts').doc(req.params.id);
    const snap = await ref.get();
    if (!snap.exists || snap.data().hidden === true) throw httpError(404, 'Post not found.');
    await ref.update({ share_count: increment(1) });
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Could not count the share.');
  }
});

function postImagePaths(post) {
  const paths = new Set();
  for (const img of post.images || []) if (img && img.path) paths.add(img.path);
  if (post.image_path) paths.add(post.image_path);
  return [...paths];
}

async function deletePost(postRef, post) {
  for (const path of postImagePaths(post)) await deletePhoto(path);
  for (const name of ['dogbook_comments', 'dogbook_likes', 'dogbook_comment_likes']) {
    const snap = await col(name).where('post_id', '==', postRef.id).get();
    for (const doc of snap.docs) await doc.ref.delete();
  }
  await postRef.delete();
  if (post.dog_id) {
    const dogRef = col('dogbook_dogs').doc(post.dog_id);
    const dog = await dogRef.get();
    if (dog.exists) await dogRef.update({ post_count: increment(-1) });
  }
}

router.delete('/posts/:id', verifyFirebaseToken, requireUser, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Post not found.');
    const ref = col('dogbook_posts').doc(req.params.id);
    const snap = await ref.get();
    if (!snap.exists) throw httpError(404, 'Post not found.');
    const post = snap.data();
    if (post.uid !== req.user.uid && !(await isAdmin(req.user.uid))) {
      throw httpError(403, 'You can only delete your own posts.');
    }
    await deletePost(ref, post);
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Could not delete the post.');
  }
});

// --- Likes ("paws") ---------------------------------------------------------

// Toggles the signed-in player's like. Returns whether they now like it.
router.post('/posts/:id/like', verifyFirebaseToken, requireUser, likeLimiter, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Post not found.');
    const postRef = col('dogbook_posts').doc(req.params.id);
    const likeRef = col('dogbook_likes').doc(`${req.params.id}_${req.user.uid}`);
    let post;
    const liked = await db().runTransaction(async tx => {
      const p = await tx.get(postRef);
      if (!p.exists || p.data().hidden === true) throw httpError(404, 'Post not found.');
      post = p.data();
      const like = await tx.get(likeRef);
      if (like.exists) {
        tx.delete(likeRef);
        tx.update(postRef, { like_count: increment(-1) });
        return false;
      }
      tx.set(likeRef, { post_id: req.params.id, uid: req.user.uid, created_at: now() });
      tx.update(postRef, { like_count: increment(1) });
      return true;
    });
    if (liked) {
      const me = await loadPoster(req.user.uid).catch(() => ({ author_name: 'Someone' }));
      await notify(post.uid, req.user.uid, {
        type: 'like', from_name: me.author_name, post_id: req.params.id, text: post.caption,
      });
    }
    res.json({ success: true, liked });
  } catch (error) {
    fail(res, error, 'Could not update the like.');
  }
});

router.post('/comments/:id/like', verifyFirebaseToken, requireUser, likeLimiter, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Comment not found.');
    const commentRef = col('dogbook_comments').doc(req.params.id);
    const likeRef = col('dogbook_comment_likes').doc(`${req.params.id}_${req.user.uid}`);
    let comment;
    const liked = await db().runTransaction(async tx => {
      const c = await tx.get(commentRef);
      if (!c.exists || c.data().hidden === true) throw httpError(404, 'Comment not found.');
      comment = c.data();
      const like = await tx.get(likeRef);
      if (like.exists) {
        tx.delete(likeRef);
        tx.update(commentRef, { like_count: increment(-1) });
        return false;
      }
      tx.set(likeRef, { comment_id: req.params.id, post_id: comment.post_id, uid: req.user.uid, created_at: now() });
      tx.update(commentRef, { like_count: increment(1) });
      return true;
    });
    if (liked) {
      const me = await loadPoster(req.user.uid).catch(() => ({ author_name: 'Someone' }));
      await notify(comment.uid, req.user.uid, {
        type: 'comment_like', from_name: me.author_name, post_id: comment.post_id, text: comment.text,
      });
    }
    res.json({ success: true, liked });
  } catch (error) {
    fail(res, error, 'Could not update the like.');
  }
});

// --- Comments and replies ---------------------------------------------------

router.post('/posts/:id/comments', verifyFirebaseToken, requireUser, commentLimiter, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Post not found.');
    const body = req.body || {};
    const text = cleanText(body.text, MAX_COMMENT);
    if (!text) throw httpError(400, 'Please write a comment.');
    if (text.length > MAX_COMMENT) throw httpError(400, `Comments can be up to ${MAX_COMMENT} characters.`);
    const problem = textProblem(text);
    if (problem) throw httpError(400, problem);

    const poster = await loadPoster(req.user.uid);
    let dogName = '';
    if (body.dog_id) dogName = (await loadOwnDog(req.user.uid, body.dog_id)).name;
    const parentId = body.parent_id ? String(body.parent_id) : '';
    if (parentId && !validId(parentId)) throw httpError(400, 'Invalid reply.');

    const postRef = col('dogbook_posts').doc(req.params.id);
    const parentRef = parentId ? col('dogbook_comments').doc(parentId) : null;
    const commentRef = col('dogbook_comments').doc();
    let post;
    let parent = null;
    await db().runTransaction(async tx => {
      const p = await tx.get(postRef);
      if (!p.exists || p.data().hidden === true) throw httpError(404, 'Post not found.');
      post = p.data();
      if (parentRef) {
        const pc = await tx.get(parentRef);
        if (!pc.exists || pc.data().hidden === true || pc.data().post_id !== req.params.id) {
          throw httpError(404, 'That comment has been removed.');
        }
        if (pc.data().parent_id) throw httpError(400, 'You can only reply to top-level comments.');
        parent = pc.data();
      }
      tx.set(commentRef, {
        post_id: req.params.id,
        parent_id: parentId,
        uid: req.user.uid,
        author_name: poster.author_name,
        dog_name: dogName,
        text,
        like_count: 0,
        reply_count: 0,
        report_count: 0,
        hidden: false,
        created_at: now(),
      });
      tx.update(postRef, { comment_count: increment(1) });
      if (parentRef) tx.update(parentRef, { reply_count: increment(1) });
    });
    const from = dogName || poster.author_name;
    if (parent) {
      await notify(parent.uid, req.user.uid, { type: 'reply', from_name: from, post_id: req.params.id, text });
    }
    if (!parent || parent.uid !== post.uid) {
      await notify(post.uid, req.user.uid, { type: 'comment', from_name: from, post_id: req.params.id, text });
    }
    res.json({ success: true, id: commentRef.id });
  } catch (error) {
    fail(res, error, 'Could not add your comment.');
  }
});

async function deleteComment(commentRef, comment) {
  let removed = 1;
  if (!comment.parent_id) {
    const replies = await col('dogbook_comments').where('parent_id', '==', commentRef.id).get();
    for (const r of replies.docs) {
      await r.ref.delete();
      removed += 1;
    }
  }
  const likes = await col('dogbook_comment_likes').where('comment_id', '==', commentRef.id).get();
  for (const l of likes.docs) await l.ref.delete();
  await commentRef.delete();
  const postRef = col('dogbook_posts').doc(comment.post_id);
  const post = await postRef.get();
  if (post.exists) await postRef.update({ comment_count: increment(-removed) });
  if (comment.parent_id) {
    const parentRef = col('dogbook_comments').doc(comment.parent_id);
    const parent = await parentRef.get();
    if (parent.exists) await parentRef.update({ reply_count: increment(-1) });
  }
}

router.delete('/comments/:id', verifyFirebaseToken, requireUser, async (req, res) => {
  try {
    if (!validId(req.params.id)) throw httpError(404, 'Comment not found.');
    const ref = col('dogbook_comments').doc(req.params.id);
    const snap = await ref.get();
    if (!snap.exists) throw httpError(404, 'Comment not found.');
    const comment = snap.data();
    if (comment.uid !== req.user.uid && !(await isAdmin(req.user.uid))) {
      throw httpError(403, 'You can only delete your own comments.');
    }
    await deleteComment(ref, comment);
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Could not delete the comment.');
  }
});

// --- Notifications ----------------------------------------------------------

router.post('/notifications/read', verifyFirebaseToken, requireUser, async (req, res) => {
  try {
    const snap = await col('dogbook_notifications').where('to_uid', '==', req.user.uid).get();
    for (const doc of snap.docs) {
      if (doc.data().read !== true) await doc.ref.update({ read: true });
    }
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Could not update notifications.');
  }
});

// --- Reports (Online Safety Act) ------------------------------------------

const TARGETS = {
  post: 'dogbook_posts',
  comment: 'dogbook_comments',
  dog: 'dogbook_dogs',
};

function reportSnapshot(type, t) {
  if (type === 'post') {
    return {
      owner: t.uid || '',
      text: `${t.dog_name || ''}: ${t.caption || ''}`,
      image_url: (t.images && t.images[0] && t.images[0].url) || t.image_url || '',
    };
  }
  if (type === 'comment') return { owner: t.uid || '', text: t.text || '', image_url: '' };
  return { owner: t.owner_uid || '', text: `${t.name || ''} (${t.breed || 'dog'}): ${t.bio || ''}`, image_url: t.photo_url || '' };
}

// One report per person per post, comment or dog profile. After
// AUTO_HIDE_REPORTS different people report something it is hidden until
// the admin reviews it.
router.post('/report', verifyFirebaseToken, requireUser, reportLimiter, async (req, res) => {
  try {
    const { type, id, reason } = req.body || {};
    if (!TARGETS[type] || !validId(id)) {
      return res.status(400).json({ success: false, error: 'Invalid report.' });
    }
    if (!REPORT_REASONS.includes(reason)) {
      return res.status(400).json({ success: false, error: 'Please choose a reason.' });
    }
    const targetKey = `${type}_${id}`;
    const targetRef = col(TARGETS[type]).doc(id);
    const reportRef = col('dogbook_reports').doc(`${targetKey}_${req.user.uid}`);

    await db().runTransaction(async tx => {
      const target = await tx.get(targetRef);
      if (!target.exists) throw httpError(404, 'That has already been removed.');
      const existing = await tx.get(reportRef);
      if (existing.exists) throw httpError(409, 'You have already reported this. Thank you.');
      const t = target.data();
      const snap = reportSnapshot(type, t);
      if (snap.owner === req.user.uid) throw httpError(400, 'You cannot report your own post.');
      const count = Number(t.report_count || 0) + 1;
      tx.set(reportRef, {
        target_key: targetKey,
        target_type: type,
        target_id: id,
        post_id: type === 'post' ? id : (t.post_id || ''),
        reported_uid: snap.owner,
        reporter_uid: req.user.uid,
        reason,
        text: snap.text,
        image_url: snap.image_url,
        timestamp: now(),
        status: 'open',
      });
      const update = { report_count: count };
      if (count >= AUTO_HIDE_REPORTS) update.hidden = true;
      tx.update(targetRef, update);
    });
    res.json({ success: true, message: 'Thanks for telling us. We will take a look.' });
  } catch (error) {
    fail(res, error, 'Could not send the report.');
  }
});

// --- Blocking -------------------------------------------------------------

// Adds or removes a player from the signed-in player's block list. The app
// hides posts and comments from blocked players.
router.post('/block', verifyFirebaseToken, requireUser, async (req, res) => {
  try {
    const { uid, blocked } = req.body || {};
    if (!validId(uid) || uid === req.user.uid) {
      return res.status(400).json({ success: false, error: 'Invalid account.' });
    }
    const userRef = col('users').doc(req.user.uid);
    const list = await db().runTransaction(async tx => {
      const snap = await tx.get(userRef);
      const current = (snap.exists && Array.isArray(snap.data().dogbook_blocked)) ? snap.data().dogbook_blocked : [];
      let next = current.filter(u => u !== uid);
      if (blocked !== false) next = [...next, uid].slice(-500);
      if (snap.exists) tx.update(userRef, { dogbook_blocked: next });
      else tx.set(userRef, { dogbook_blocked: next });
      return next;
    });
    res.json({ success: true, blocked: list });
  } catch (error) {
    fail(res, error, 'Could not update your block list.');
  }
});

// --- Admin review -----------------------------------------------------------

// Open reports, grouped so each reported post, comment or dog appears once.
router.get('/reports', verifyFirebaseToken, requireAdmin, async (req, res) => {
  try {
    const handled = req.query.status === 'handled';
    const snap = await col('dogbook_reports').orderBy('timestamp', 'desc').limit(500).get();
    const groups = new Map();
    for (const doc of snap.docs) {
      const d = doc.data() || {};
      const isOpen = (d.status || 'open') === 'open';
      if (handled === isOpen) continue;
      const key = d.target_key;
      if (!groups.has(key)) {
        groups.set(key, {
          target_key: key,
          target_type: d.target_type,
          target_id: d.target_id,
          post_id: d.post_id || '',
          reported_uid: d.reported_uid || '',
          text: d.text || '',
          image_url: d.image_url || '',
          reasons: [],
          reporters: 0,
          latest: d.timestamp && d.timestamp.toDate ? d.timestamp.toDate().toISOString() : null,
          action: d.action || null,
          handled_at: d.handled_at && d.handled_at.toDate ? d.handled_at.toDate().toISOString() : null,
        });
      }
      const g = groups.get(key);
      g.reporters += 1;
      if (d.reason && !g.reasons.includes(d.reason)) g.reasons.push(d.reason);
    }
    res.json({ success: true, reports: [...groups.values()] });
  } catch (error) {
    fail(res, error, 'Failed to load reports');
  }
});

// action: 'removed' deletes the post, comment or dog profile, 'banned' also
// stops the owner posting again, 'kept' puts it back on show and clears its
// reports.
router.post('/reports/resolve', verifyFirebaseToken, requireAdmin, async (req, res) => {
  try {
    const { target_key: targetKey, action } = req.body || {};
    if (!['removed', 'banned', 'kept'].includes(action)) {
      return res.status(400).json({ success: false, error: 'Action must be removed, banned or kept' });
    }
    const match = /^(post|comment|dog)_([^/]{1,200})$/.exec(targetKey || '');
    if (!match) return res.status(400).json({ success: false, error: 'Invalid report' });
    const [, type, id] = match;

    const targetRef = col(TARGETS[type]).doc(id);
    const target = await targetRef.get();
    if (target.exists) {
      const t = target.data();
      if (action === 'kept') {
        await targetRef.update({ hidden: false, report_count: 0 });
      } else {
        if (type === 'post') await deletePost(targetRef, t);
        else if (type === 'comment') await deleteComment(targetRef, t);
        else await deleteDog(targetRef, t);
        const owner = type === 'dog' ? t.owner_uid : t.uid;
        if (action === 'banned' && owner) {
          const userRef = col('users').doc(owner);
          const user = await userRef.get();
          if (user.exists) await userRef.update({ dogbook_banned: true });
          else await userRef.set({ dogbook_banned: true });
        }
      }
    }

    const reports = await col('dogbook_reports').where('target_key', '==', targetKey).get();
    for (const doc of reports.docs) {
      if ((doc.data().status || 'open') !== 'open') continue;
      await doc.ref.update({ status: 'handled', action, handled_at: now(), handled_by: req.user.uid });
    }
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Failed to resolve report');
  }
});

module.exports = router;
module.exports.cleanPhoto = cleanPhoto;
module.exports.textProblem = textProblem;
