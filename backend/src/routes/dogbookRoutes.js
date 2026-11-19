// The Book Of Dog: a feed where players share photos of their dogs.
//
// Every write goes through this server, like chat does, so text can be
// filtered, photos cleaned, banned accounts stopped and reports counted.
// The app reads visible posts and comments straight from Firestore (see
// firestore.rules); hidden ones are only visible here, to the admin.
//
// Collections:
//   dogbook_posts/{id}       uid, author_name, dog_name, caption, image_url,
//                            image_path, created_at, like_count,
//                            comment_count, report_count, hidden
//   dogbook_comments/{id}    post_id, uid, author_name, text, created_at,
//                            report_count, hidden
//   dogbook_likes/{post_uid} post_id, uid, created_at
//   dogbook_reports/{key_reporter}  one per person per post or comment
// User fields: dogbook_banned (bool), dogbook_blocked (list of uids).

const crypto = require('crypto');
const express = require('express');
const multer = require('multer');
const rateLimit = require('express-rate-limit');
const sharp = require('sharp');
const { admin, verifyFirebaseToken, isAdmin } = require('../services/firebaseService');

const router = express.Router();

const AUTO_HIDE_REPORTS = 3;
const MAX_CAPTION = 200;
const MAX_COMMENT = 200;
const MAX_DOG_NAME = 30;
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
const postLimiter = perUser(60 * 60 * 1000, 6, 'You have posted a lot this hour. Please try again later.');
const commentLimiter = perUser(10 * 60 * 1000, 20, 'You are commenting too quickly. Please wait a few minutes.');
const likeLimiter = perUser(60 * 1000, 60, 'Slow down a little!');
const reportLimiter = perUser(60 * 60 * 1000, 30, 'You have sent a lot of reports. Please try again later.');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024, files: 1, fields: 5 },
});

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

function bucket() {
  const name = process.env.DOGBOOK_BUCKET
    || `${process.env.FIREBASE_PROJECT_ID || 'golden-paw-database'}.firebasestorage.app`;
  return admin.storage().bucket(name);
}

// Loads the user's profile and refuses banned accounts.
async function loadPoster(uid) {
  const snap = await db().collection('users').doc(uid).get();
  const data = snap.exists ? snap.data() : {};
  if (data.dogbook_banned === true) {
    const err = new Error('Your account can no longer post in The Book Of Dog.');
    err.status = 403;
    throw err;
  }
  const name = data.chat_username || data.username || data.display_name || 'Dog lover';
  return { author_name: String(name).slice(0, 30) };
}

// Shrinks the photo, turns it the right way up and re-saves it as a JPEG.
// Re-encoding drops all metadata, including any GPS location.
async function cleanPhoto(buffer) {
  let image;
  try {
    image = sharp(buffer, { limitInputPixels: 50_000_000, failOn: 'error' });
    const meta = await image.metadata();
    if (!['jpeg', 'png', 'webp', 'gif'].includes(meta.format)) throw new Error('format');
  } catch (_) {
    const err = new Error('Please choose a JPG, PNG or WebP photo.');
    err.status = 400;
    throw err;
  }
  return image
    .rotate()
    .resize({ width: 1280, height: 1280, fit: 'inside', withoutEnlargement: true })
    .flatten({ background: '#ffffff' })
    .jpeg({ quality: 82, mozjpeg: true })
    .toBuffer();
}

function fail(res, error, fallback) {
  if (error && error.status) {
    return res.status(error.status).json({ success: false, error: error.message });
  }
  console.error(fallback, error);
  return res.status(500).json({ success: false, error: fallback });
}

// --- Posts ----------------------------------------------------------------

router.post('/posts', verifyFirebaseToken, requireUser, postLimiter, (req, res, next) => {
  upload.single('photo')(req, res, err => {
    if (err) {
      const tooBig = err.code === 'LIMIT_FILE_SIZE';
      return res.status(400).json({ success: false, error: tooBig ? 'That photo is too big (10 MB max).' : 'Upload failed.' });
    }
    next();
  });
}, async (req, res) => {
  try {
    const dogName = cleanText(req.body.dog_name, MAX_DOG_NAME);
    const caption = cleanText(req.body.caption, MAX_CAPTION);
    if (!req.file) return res.status(400).json({ success: false, error: 'Please add a photo of your dog.' });
    if (!dogName) return res.status(400).json({ success: false, error: "Please add your dog's name." });
    if (dogName.length > MAX_DOG_NAME) return res.status(400).json({ success: false, error: `Dog names can be up to ${MAX_DOG_NAME} characters.` });
    if (caption.length > MAX_CAPTION) return res.status(400).json({ success: false, error: `Captions can be up to ${MAX_CAPTION} characters.` });
    const problem = textProblem(`${dogName} ${caption}`);
    if (problem) return res.status(400).json({ success: false, error: problem });

    const poster = await loadPoster(req.user.uid);
    const jpeg = await cleanPhoto(req.file.buffer);

    const ref = db().collection('dogbook_posts').doc();
    const path = `dogbook/${ref.id}.jpg`;
    const token = crypto.randomUUID();
    const b = bucket();
    await b.file(path).save(jpeg, {
      resumable: false,
      contentType: 'image/jpeg',
      metadata: { cacheControl: 'public, max-age=31536000', metadata: { firebaseStorageDownloadTokens: token } },
    });
    const imageUrl = `https://firebasestorage.googleapis.com/v0/b/${b.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;

    await ref.set({
      uid: req.user.uid,
      author_name: poster.author_name,
      dog_name: dogName,
      caption,
      image_url: imageUrl,
      image_path: path,
      created_at: now(),
      like_count: 0,
      comment_count: 0,
      report_count: 0,
      hidden: false,
    });
    res.json({ success: true, id: ref.id });
  } catch (error) {
    fail(res, error, 'Could not share your post. Please try again.');
  }
});

async function deletePost(postRef, post) {
  if (post.image_path) {
    try {
      await bucket().file(post.image_path).delete({ ignoreNotFound: true });
    } catch (e) {
      console.error('Book Of Dog: could not delete photo', post.image_path, e.message || e);
    }
  }
  for (const name of ['dogbook_comments', 'dogbook_likes']) {
    const snap = await db().collection(name).where('post_id', '==', postRef.id).get();
    for (const doc of snap.docs) await doc.ref.delete();
  }
  await postRef.delete();
}

router.delete('/posts/:id', verifyFirebaseToken, requireUser, async (req, res) => {
  try {
    const ref = db().collection('dogbook_posts').doc(req.params.id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ success: false, error: 'Post not found.' });
    const post = snap.data();
    if (post.uid !== req.user.uid && !(await isAdmin(req.user.uid))) {
      return res.status(403).json({ success: false, error: 'You can only delete your own posts.' });
    }
    await deletePost(ref, post);
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Could not delete the post.');
  }
});

// --- Likes ----------------------------------------------------------------

// Toggles the signed-in player's like. Returns whether they now like it.
router.post('/posts/:id/like', verifyFirebaseToken, requireUser, likeLimiter, async (req, res) => {
  try {
    const postRef = db().collection('dogbook_posts').doc(req.params.id);
    const likeRef = db().collection('dogbook_likes').doc(`${req.params.id}_${req.user.uid}`);
    const liked = await db().runTransaction(async tx => {
      const post = await tx.get(postRef);
      if (!post.exists || post.data().hidden === true) {
        const err = new Error('Post not found.');
        err.status = 404;
        throw err;
      }
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
    res.json({ success: true, liked });
  } catch (error) {
    fail(res, error, 'Could not update the like.');
  }
});

// --- Comments -------------------------------------------------------------

router.post('/posts/:id/comments', verifyFirebaseToken, requireUser, commentLimiter, async (req, res) => {
  try {
    const text = cleanText(req.body && req.body.text, MAX_COMMENT);
    if (!text) return res.status(400).json({ success: false, error: 'Please write a comment.' });
    if (text.length > MAX_COMMENT) return res.status(400).json({ success: false, error: `Comments can be up to ${MAX_COMMENT} characters.` });
    const problem = textProblem(text);
    if (problem) return res.status(400).json({ success: false, error: problem });

    const poster = await loadPoster(req.user.uid);
    const postRef = db().collection('dogbook_posts').doc(req.params.id);
    const commentRef = db().collection('dogbook_comments').doc();
    await db().runTransaction(async tx => {
      const post = await tx.get(postRef);
      if (!post.exists || post.data().hidden === true) {
        const err = new Error('Post not found.');
        err.status = 404;
        throw err;
      }
      tx.set(commentRef, {
        post_id: req.params.id,
        uid: req.user.uid,
        author_name: poster.author_name,
        text,
        created_at: now(),
        report_count: 0,
        hidden: false,
      });
      tx.update(postRef, { comment_count: increment(1) });
    });
    res.json({ success: true, id: commentRef.id });
  } catch (error) {
    fail(res, error, 'Could not add your comment.');
  }
});

async function deleteComment(commentRef, comment) {
  await commentRef.delete();
  const postRef = db().collection('dogbook_posts').doc(comment.post_id);
  const post = await postRef.get();
  if (post.exists) await postRef.update({ comment_count: increment(-1) });
}

router.delete('/comments/:id', verifyFirebaseToken, requireUser, async (req, res) => {
  try {
    const ref = db().collection('dogbook_comments').doc(req.params.id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ success: false, error: 'Comment not found.' });
    const comment = snap.data();
    if (comment.uid !== req.user.uid && !(await isAdmin(req.user.uid))) {
      return res.status(403).json({ success: false, error: 'You can only delete your own comments.' });
    }
    await deleteComment(ref, comment);
    res.json({ success: true });
  } catch (error) {
    fail(res, error, 'Could not delete the comment.');
  }
});

// --- Reports (Online Safety Act) ------------------------------------------

// One report per person per post or comment. After AUTO_HIDE_REPORTS
// different people report something it is hidden until the admin reviews it.
router.post('/report', verifyFirebaseToken, requireUser, reportLimiter, async (req, res) => {
  try {
    const { type, id, reason } = req.body || {};
    if (!['post', 'comment'].includes(type) || typeof id !== 'string' || !id || id.length > 200 || id.includes('/')) {
      return res.status(400).json({ success: false, error: 'Invalid report.' });
    }
    if (!REPORT_REASONS.includes(reason)) {
      return res.status(400).json({ success: false, error: 'Please choose a reason.' });
    }
    const targetKey = `${type}_${id}`;
    const targetRef = db().collection(type === 'post' ? 'dogbook_posts' : 'dogbook_comments').doc(id);
    const reportRef = db().collection('dogbook_reports').doc(`${targetKey}_${req.user.uid}`);

    await db().runTransaction(async tx => {
      const target = await tx.get(targetRef);
      if (!target.exists) {
        const err = new Error('That has already been removed.');
        err.status = 404;
        throw err;
      }
      const existing = await tx.get(reportRef);
      if (existing.exists) {
        const err = new Error('You have already reported this. Thank you.');
        err.status = 409;
        throw err;
      }
      const t = target.data();
      if (t.uid === req.user.uid) {
        const err = new Error('You cannot report your own post.');
        err.status = 400;
        throw err;
      }
      const count = Number(t.report_count || 0) + 1;
      tx.set(reportRef, {
        target_key: targetKey,
        target_type: type,
        target_id: id,
        post_id: type === 'post' ? id : (t.post_id || ''),
        reported_uid: t.uid || '',
        reporter_uid: req.user.uid,
        reason,
        text: type === 'post' ? `${t.dog_name || ''}: ${t.caption || ''}` : (t.text || ''),
        image_url: type === 'post' ? (t.image_url || '') : '',
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
    if (typeof uid !== 'string' || !uid || uid.length > 200 || uid === req.user.uid) {
      return res.status(400).json({ success: false, error: 'Invalid account.' });
    }
    const userRef = db().collection('users').doc(req.user.uid);
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

// Open reports, grouped so each reported post or comment appears once.
router.get('/reports', verifyFirebaseToken, requireAdmin, async (req, res) => {
  try {
    const handled = req.query.status === 'handled';
    const snap = await db().collection('dogbook_reports').orderBy('timestamp', 'desc').limit(500).get();
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

// action: 'removed' deletes the post or comment, 'banned' also stops the
// author posting again, 'kept' puts it back on show and clears its reports.
router.post('/reports/resolve', verifyFirebaseToken, requireAdmin, async (req, res) => {
  try {
    const { target_key: targetKey, action } = req.body || {};
    if (!['removed', 'banned', 'kept'].includes(action)) {
      return res.status(400).json({ success: false, error: 'Action must be removed, banned or kept' });
    }
    const match = /^(post|comment)_([^/]{1,200})$/.exec(targetKey || '');
    if (!match) return res.status(400).json({ success: false, error: 'Invalid report' });
    const [, type, id] = match;

    const targetRef = db().collection(type === 'post' ? 'dogbook_posts' : 'dogbook_comments').doc(id);
    const target = await targetRef.get();
    if (target.exists) {
      const t = target.data();
      if (action === 'kept') {
        await targetRef.update({ hidden: false, report_count: 0 });
      } else {
        if (type === 'post') await deletePost(targetRef, t);
        else await deleteComment(targetRef, t);
        if (action === 'banned' && t.uid) {
          const userRef = db().collection('users').doc(t.uid);
          const user = await userRef.get();
          if (user.exists) await userRef.update({ dogbook_banned: true });
          else await userRef.set({ dogbook_banned: true });
        }
      }
    }

    const reports = await db().collection('dogbook_reports').where('target_key', '==', targetKey).get();
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
