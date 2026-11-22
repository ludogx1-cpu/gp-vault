// GPAWS: Golden Paw loyalty points.
//
// A partly hidden golden paw appears now and then while a signed-in player
// uses the app; tapping it collects one GPAW. They are loyalty points only:
// they have no cash value and cannot be exchanged for DOGE or anything else.
//
// The server decides when a paw may appear and checks every collection:
//   - at most MAX_PER_HOUR paws are handed out in any rolling hour
//   - paws are spaced a random MIN_GAP_MS..MAX_GAP_MS apart
//   - one paw at a time, visible for VISIBLE_MS
//   - a paw must be the one handed out, unexpired, uncollected, and not
//     collected faster than MIN_REACTION_MS (bots)
//
// User fields (server-owned; clients cannot write them):
//   gpaws (balance), gpaws_lifetime, gpaws_recent (spawn times, ms),
//   gpaws_next_at (ms), gpaws_active {id, created_ms, expires_ms}

const crypto = require('crypto');
const express = require('express');
const rateLimit = require('express-rate-limit');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');

const router = express.Router();

const HOUR_MS = 60 * 60 * 1000;
const MAX_PER_HOUR = 5;
const MIN_GAP_MS = 6 * 60 * 1000;
const MAX_GAP_MS = 15 * 60 * 1000;
const VISIBLE_MS = 90 * 1000;
const MIN_REACTION_MS = 1000;

const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  keyGenerator: req => (req.user ? req.user.uid : 'anon'),
  validate: { keyGeneratorIpFallback: false },
  message: { success: false, error: 'Too many requests.' },
});

function requireUser(req, res, next) {
  if (!req.user || !req.user.uid) return res.status(401).json({ success: false, error: 'Please sign in first.' });
  next();
}

const randomGap = () => MIN_GAP_MS + Math.floor(Math.random() * (MAX_GAP_MS - MIN_GAP_MS));

// Asks for a paw. Returns {paw: {id, expires_ms}} when one may appear now,
// otherwise {paw: null, retry_ms} saying when to ask again.
router.post('/spawn', verifyFirebaseToken, requireUser, limiter, async (req, res) => {
  try {
    const db = admin.firestore();
    const userRef = db.collection('users').doc(req.user.uid);
    const result = await db.runTransaction(async tx => {
      const snap = await tx.get(userRef);
      const d = snap.exists ? snap.data() : {};
      const now = Date.now();
      const active = d.gpaws_active;
      if (active && active.expires_ms > now) {
        return { paw: { id: active.id, expires_ms: active.expires_ms }, balance: Number(d.gpaws || 0) };
      }
      const recent = (Array.isArray(d.gpaws_recent) ? d.gpaws_recent : []).filter(t => now - t < HOUR_MS);
      let waitUntil = Number(d.gpaws_next_at || 0);
      if (recent.length >= MAX_PER_HOUR) waitUntil = Math.max(waitUntil, Math.min(...recent) + HOUR_MS);
      if (waitUntil > now) {
        return { paw: null, retry_ms: waitUntil - now, balance: Number(d.gpaws || 0) };
      }
      const paw = { id: crypto.randomUUID(), created_ms: now, expires_ms: now + VISIBLE_MS };
      const updates = {
        gpaws_active: paw,
        gpaws_recent: [...recent, now],
        gpaws_next_at: now + randomGap(),
      };
      if (snap.exists) tx.update(userRef, updates);
      else tx.set(userRef, updates);
      return { paw: { id: paw.id, expires_ms: paw.expires_ms }, balance: Number(d.gpaws || 0) };
    });
    res.json({ success: true, ...result });
  } catch (error) {
    console.error('gpaws spawn error:', error.message || error);
    res.status(500).json({ success: false, error: 'Could not check for GPAWS.' });
  }
});

// Collects the paw that was handed out.
router.post('/collect', verifyFirebaseToken, requireUser, limiter, async (req, res) => {
  try {
    const id = req.body && req.body.id;
    if (typeof id !== 'string' || id.length > 64) {
      return res.status(400).json({ success: false, error: 'Invalid paw.' });
    }
    const db = admin.firestore();
    const userRef = db.collection('users').doc(req.user.uid);
    const balance = await db.runTransaction(async tx => {
      const snap = await tx.get(userRef);
      const d = snap.exists ? snap.data() : {};
      const active = d.gpaws_active;
      const now = Date.now();
      if (!active || active.id !== id) {
        const err = new Error('That paw has gone. Keep an eye out for the next one!');
        err.status = 410;
        throw err;
      }
      if (now > active.expires_ms) {
        const err = new Error('Too slow! That paw has wandered off.');
        err.status = 410;
        throw err;
      }
      if (now - active.created_ms < MIN_REACTION_MS) {
        const err = new Error('Not so fast!');
        err.status = 429;
        throw err;
      }
      const newBalance = Number(d.gpaws || 0) + 1;
      tx.update(userRef, {
        gpaws: newBalance,
        gpaws_lifetime: Number(d.gpaws_lifetime || 0) + 1,
        gpaws_active: admin.firestore.FieldValue.delete(),
      });
      return newBalance;
    });
    res.json({ success: true, gpaws: balance });
  } catch (error) {
    if (error.status) return res.status(error.status).json({ success: false, error: error.message });
    console.error('gpaws collect error:', error.message || error);
    res.status(500).json({ success: false, error: 'Could not collect the paw.' });
  }
});

module.exports = router;
module.exports.MAX_PER_HOUR = MAX_PER_HOUR;
