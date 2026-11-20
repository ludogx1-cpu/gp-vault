const express = require('express');
const { admin, verifyFirebaseToken, isAdmin } = require('../services/firebaseService');
const router = express.Router();

router.post('/add-update', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    if (!(await isAdmin(req.user.uid))) {
      return res.status(403).json({ success: false, error: 'Access Denied: Admins only.' });
    }

    const { title, message } = req.body;
    if (!title || !message) {
      return res.status(400).json({ success: false, error: 'Missing title or message' });
    }

    await admin.firestore().collection('updates').add({
      title,
      message,
      timestamp: admin.firestore.Timestamp.now(),
    });

    console.log('Admin update posted:', title);
    res.json({ success: true, message: 'Update posted successfully to all users!' });
  } catch (error) {
    console.error('add-update error:', error.message || error);
    res.status(500).json({ success: false, error: 'Failed to post update' });
  }
});

router.delete('/delete-update/:id', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    if (!(await isAdmin(req.user.uid))) {
      return res.status(403).json({ success: false, error: 'Admins only.' });
    }

    const docId = req.params.id;
    await admin.firestore().collection('updates').doc(docId).delete();
    
    res.json({ success: true, message: 'Deleted successfully' });
  } catch (error) {
    console.error('delete-update error:', error);
    res.status(500).json({ success: false, error: 'Failed to delete update' });
  }
});

// Newsletter sign-ups, for importing into Substack. Admin only: emails are
// de-duplicated (case-insensitive), lower-cased and sorted.
router.get('/subscribers', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    if (!(await isAdmin(req.user.uid))) {
      return res.status(403).json({ success: false, error: 'Access Denied: Admins only.' });
    }
    const snap = await admin.firestore().collection('subscribers').get();
    const emails = new Set();
    for (const doc of snap.docs) {
      const email = String((doc.data() || {}).email || '').trim().toLowerCase();
      if (/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) emails.add(email);
    }
    res.json({ success: true, emails: [...emails].sort() });
  } catch (error) {
    console.error('subscribers export error:', error.message || error);
    res.status(500).json({ success: false, error: 'Failed to load subscribers' });
  }
});

// Emails of everyone with a Golden Paw account, for the newsletter.
// Leaves out anyone who unsubscribed (users/{uid}.emailOptOut) and disabled
// accounts. Uses Firebase Auth as the source of emails, falling back to the
// email saved on the profile.
router.get('/account-emails', verifyFirebaseToken, async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ success: false, error: 'Authentication required' });
    if (!(await isAdmin(req.user.uid))) {
      return res.status(403).json({ success: false, error: 'Access Denied: Admins only.' });
    }
    const valid = e => /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(e);
    const optedOut = new Set();
    const byUid = new Map();
    const users = await admin.firestore().collection('users').get();
    for (const doc of users.docs) {
      const d = doc.data() || {};
      if (d.emailOptOut === true) optedOut.add(doc.id);
      const email = String(d.email || '').trim().toLowerCase();
      if (valid(email)) byUid.set(doc.id, email);
    }
    let pageToken;
    do {
      const page = await admin.auth().listUsers(1000, pageToken);
      for (const u of page.users) {
        const email = String(u.email || '').trim().toLowerCase();
        if (u.disabled) {
          byUid.delete(u.uid);
          optedOut.add(u.uid);
        } else if (valid(email)) {
          byUid.set(u.uid, email);
        }
      }
      pageToken = page.pageToken;
    } while (pageToken);
    const emails = new Set();
    for (const [uid, email] of byUid) if (!optedOut.has(uid)) emails.add(email);
    res.json({ success: true, emails: [...emails].sort(), opted_out: optedOut.size });
  } catch (error) {
    console.error('account emails export error:', error.message || error);
    res.status(500).json({ success: false, error: 'Failed to load account emails' });
  }
});

module.exports = router;
