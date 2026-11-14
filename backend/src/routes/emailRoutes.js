const express = require('express');
const router = express.Router();
const { admin } = require('../services/firebaseService');
const { isValidUnsubscribeToken } = require('../utils/unsubscribeToken');

function page(title, message, colour = '#d9534f') {
  return `
      <html>
      <head>
        <title>${title}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background: #fdfdfd; }
          .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); display: inline-block; max-width: 480px; }
          h1 { color: ${colour}; }
          p { color: #555; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>${title}</h1>
          <p>${message}</p>
        </div>
      </body>
      </html>
    `;
}

// Opt-out route for emails. Links are signed per user (see
// utils/unsubscribeToken.js) so nobody can unsubscribe someone else just by
// knowing their user ID.
router.get('/unsubscribe/:uid/:token', async (req, res) => {
  const { uid, token } = req.params;
  if (!isValidUnsubscribeToken(uid, token)) {
    return res.status(400).send(page('Link not valid',
      'This unsubscribe link is not valid. To stop emails, reply to any of our emails or contact goldenpaw.dogeadmin@gmail.com.'));
  }

  try {
    const userRef = admin.firestore().collection('users').doc(uid);
    const doc = await userRef.get();
    if (!doc.exists) {
      return res.status(404).send(page('Account not found', 'We could not find this account.'));
    }
    await userRef.set({ emailOptOut: true }, { merge: true });
    res.send(page('Unsubscribed Successfully', 'You have been removed from our mailing list. You will no longer receive these emails.'));
  } catch (error) {
    console.error('Error in unsubscribe route:', error);
    res.status(500).send(page('Something went wrong', 'Please try again, or contact goldenpaw.dogeadmin@gmail.com.'));
  }
});

// Old unsigned links no longer unsubscribe anyone.
router.get('/unsubscribe/:uid', (req, res) => {
  res.status(410).send(page('Link expired',
    'This unsubscribe link has expired. To stop emails, reply to any of our emails or contact goldenpaw.dogeadmin@gmail.com.'));
});

module.exports = router;
