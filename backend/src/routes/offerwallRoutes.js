const express = require('express');
const crypto = require('crypto');
const { admin } = require('../services/firebaseService');
const router = express.Router();

// Offerwall Postback Routes
// Use this endpoint to receive conversion notifications from offerwalls
// Example: https://your-backend.onrender.com/api/offerwall/postback/bitcotasks

router.all('/postback/bitcotasks', async (req, res) => {
  try {
    // BitcoTasks sends data either via GET (req.query) or POST (req.body)
    const data = req.method === 'POST' ? req.body : req.query;

    const subId = data.subId; // User ID
    const transId = data.transId; // Transaction ID
    const reward = data.reward; // Amount to credit
    const signature = data.signature; // MD5 Signature
    const status = data.status; // Optional status e.g. "reversed"

    if (!subId || !transId || !reward || !signature) {
      return res.status(400).send("ERROR: Missing parameters");
    }

    const secret = process.env.BITCOTASKS_SECRET;
    if (!secret) {
      console.error("BITCOTASKS_SECRET is not configured in environment variables");
      return res.status(500).send("ERROR: Server configuration error");
    }

    // Verify signature: md5(subId . transId . reward . secret)
    const hashInput = `${subId}${transId}${reward}${secret}`;
    const expectedSignature = crypto.createHash('md5').update(hashInput).digest('hex');

    if (expectedSignature !== signature) {
      return res.status(401).send("ERROR: Signature doesn't match");
    }

    // Process the conversion
    const userRef = admin.firestore().collection('users').doc(subId);
    
    await admin.firestore().runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new Error("User not found");
      }

      // BitcoTasks usually sends status 'reversed' if the offer is cancelled
      if (status === 'reversed') {
         // Deduct if necessary, or just ignore. Usually handled manually or we deduct pending.
         // Here we just log for now to prevent double-spending attacks on reversals.
         console.warn(`BitcoTasks reversed transaction ${transId} for user ${subId}`);
         return;
      }

      // Check if transaction was already processed to prevent duplicates
      const txRef = admin.firestore().collection('offerwall_transactions').doc(transId);
      const txDoc = await transaction.get(txRef);
      if (txDoc.exists) {
        throw new Error("Transaction already processed");
      }

      // Mark transaction as processed
      transaction.set(txRef, {
        provider: 'BitcoTasks',
        userId: subId,
        amount: Number(reward),
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

      // Update user pending offer balance
      const userData = userDoc.data();
      const currentPending = Number(userData.pending_offer_balance || 0);
      transaction.update(userRef, {
        pending_offer_balance: currentPending + Number(reward)
      });
    });

    // BitcoTasks expects exactly "ok"
    return res.status(200).send("ok");

  } catch (error) {
    console.error("BitcoTasks Postback Error:", error.message);
    // If it's a duplicate or user not found, we don't want them to keep retrying, so we can return 'ok'
    if (error.message === "Transaction already processed" || error.message === "User not found") {
      return res.status(200).send("ok");
    }
    res.status(500).send("ERROR: Internal server error");
  }
});

module.exports = router;
