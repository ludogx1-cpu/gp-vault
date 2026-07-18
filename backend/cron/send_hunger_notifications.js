const admin = require('firebase-admin');

// Load service account (Assuming they have it set up via GOOGLE_APPLICATION_CREDENTIALS or path)
// For local testing:
// const serviceAccount = require('../serviceAccountKey.json');
// admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

if (!admin.apps.length) {
  admin.initializeApp();
}

async function sendHungerNotifications() {
  const db = admin.firestore();
  
  // We want to find users whose pet is hungry. 
  // pet_hunger drops to 0 after roughly 12 hours (43200000ms).
  // Let's notify users whose pet_hunger < 20
  
  console.log('Scanning for hungry pets...');
  
  const usersRef = db.collection('users');
  const snapshot = await usersRef.where('pet_hunger', '<', 20).get();
  
  if (snapshot.empty) {
    console.log('No hungry pets found right now.');
    return;
  }
  
  const tokens = [];
  snapshot.forEach(doc => {
    const data = doc.data();
    if (data.fcm_token) {
      tokens.push(data.fcm_token);
    }
  });
  
  if (tokens.length === 0) {
    console.log('Found hungry pets, but no users with FCM tokens registered.');
    return;
  }
  
  console.log(`Sending notifications to ${tokens.length} users...`);
  
  const payload = {
    notification: {
      title: 'Golden Paw',
      body: '🐶 Bark! I am getting really hungry! Come feed me!'
    },
    tokens: tokens
  };
  
  try {
    const response = await admin.messaging().sendMulticast(payload);
    console.log(`${response.successCount} messages were sent successfully.`);
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });
      console.log('List of tokens that caused failures: ' + failedTokens);
    }
  } catch (error) {
    console.error('Error sending multicast message:', error);
  }
}

sendHungerNotifications().then(() => process.exit(0)).catch((err) => {
  console.error(err);
  process.exit(1);
});
