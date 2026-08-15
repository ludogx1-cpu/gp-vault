const cron = require('node-cron');
const { admin } = require('./firebaseService');

const runPetCareLogic = async () => {
  console.log('Running pet care reminder logic...');
  try {
    const db = admin.firestore();
    
    // Query users with pets needing attention (pet_hunger < 30 or pet_sick)
    const snapshot = await db.collectionGroup('pet')
      .where('pet_hunger', '<', 45)
      .limit(100)
      .get();

    if (snapshot.empty) {
      console.log('No hungry pets found right now.');
      return;
    }

    const tokens = [];
    for (const petDoc of snapshot.docs) {
      const uid = petDoc.ref.parent.parent.id;
      const userDoc = await db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        const data = userDoc.data();
        if (data.fcm_token) {
          tokens.push(data.fcm_token);
        }
      }
    }

    if (tokens.length > 0) {
      // Send notification to hungry pet owners
      const message = {
        notification: {
          title: 'Golden Paw 🐾',
          body: '🐶 Woof! Your Shiba is getting hungry! Log in to feed your pet and keep your bonus active!'
        },
        tokens: tokens
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Pet reminder notifications sent to ${response.successCount} users.`);
    }
  } catch (error) {
    console.error('Error running pet cron logic:', error);
  }
};

function startPetCronService() {
  // Run every hour at the top of the hour
  cron.schedule('0 * * * *', runPetCareLogic);

  console.log('Pet Care Reminder Cron Service initialized (Runs every hour).');
}

module.exports = { startPetCronService, runPetCareLogic };
