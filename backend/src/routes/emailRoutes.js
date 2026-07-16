const express = require('express');
const router = express.Router();
const { admin } = require('../services/firebaseService');

// Opt-out route for mass emails
router.get('/unsubscribe/:uid', async (req, res) => {
  const { uid } = req.params;

  if (!uid) {
    return res.status(400).send('Invalid unsubscribe link.');
  }

  try {
    const userRef = admin.firestore().collection('users').doc(uid);
    const doc = await userRef.get();

    if (!doc.exists) {
      return res.status(404).send('User not found.');
    }

    // Set the emailOptOut flag
    await userRef.set({ emailOptOut: true }, { merge: true });

    res.send(`
      <html>
      <head>
        <title>Unsubscribed</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background: #fdfdfd; }
          .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); display: inline-block; }
          h1 { color: #d9534f; }
          p { color: #555; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>Unsubscribed Successfully</h1>
          <p>You have been removed from our mailing list. You will no longer receive these emails.</p>
        </div>
      </body>
      </html>
    `);
  } catch (error) {
    console.error('Error in unsubscribe route:', error);
    res.status(500).send('An error occurred while trying to unsubscribe. Please contact support.');
  }
});

module.exports = router;
