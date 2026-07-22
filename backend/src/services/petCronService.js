const cron = require('node-cron');
const { admin } = require('./firebaseService');

const runPetCareLogic = async () => {
  console.log('Running pet care reminder logic...');
  try {
    const db = admin.firestore();
    
    // Query users with pets needing attention (pet_hunger < 30 or pet_sick)
    const snapshot = await db.collection('users')
      .where('pet_hunger', '<', 30)
      .limit(100)
      .get();

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

    if (tokens.length > 0) {
      // Send notification to hungry pet owners
      const message = {
        notification: {
          title: 'Golden Paw 🐾',
          body: '🐶 Woof! Your Shiba is getting hungry! Log in to feed your pet and keep your bonus active!'
        },
        tokens: tokens
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(`Pet reminder notifications sent to ${response.successCount} users.`);
    }
  } catch (error) {
    console.error('Error running pet cron logic:', error);
  }
};

function startPetCronService() {
  // Run every 4 hours (e.g. at 00:00, 04:00, 08:00, 12:00, 16:00, 20:00)
  cron.schedule('0 */4 * * *', runPetCareLogic);

  console.log('Pet Care Reminder Cron Service initialized (Runs every 4 hours).');
}

module.exports = { startPetCronService, runPetCareLogic };
