const express = require('express');
const { admin, verifyFirebaseToken } = require('../services/firebaseService');

const router = express.Router();
const getAdminUid = () => process.env.ADMIN_UID || 'P8iffVqbUgetAVA4MdHVZ1CfvUv1';

router.post('/add-update', verifyFirebaseToken, async (req, res) => {
  try {
    if (req.user.uid !== getAdminUid()) {
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
    if (req.user.uid !== getAdminUid()) {
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

module.exports = router;
