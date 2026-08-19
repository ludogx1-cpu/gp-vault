require('dotenv').config({ path: '.env' });
const { admin } = require('./src/services/firebaseService');
const { getUserById } = require('./src/dataconnect-admin-generated');

async function verifyData() {
  console.log('Starting verification...');
  try {
    const usersSnapshot = await admin.firestore().collection('users')
      .orderBy('doge_balance', 'desc')
      .limit(5)
      .get();
      
    console.log(`Found ${usersSnapshot.size} top users in Firestore. Verifying against Data Connect...`);

    let allMatch = true;

    for (const doc of usersSnapshot.docs) {
      const firestoreData = doc.data();
      const uid = doc.id;
      
      const response = await getUserById({ id: uid });
      const sqlData = response.data.user;

      if (!sqlData) {
        console.error(`❌ User ${uid} NOT FOUND in Data Connect!`);
        allMatch = false;
        continue;
      }

      const fsDoge = Number(firestoreData.doge_balance || 0);
      const sqlDoge = sqlData.dogeBalance;
      const fsPetHunger = Number(firestoreData.pet_hunger ?? 100);
      const sqlPetHunger = sqlData.petHunger;

      if (fsDoge !== sqlDoge || fsPetHunger !== sqlPetHunger) {
        console.error(`❌ Mismatch for user ${uid}!`);
        console.error(`   Firestore - DOGE: ${fsDoge}, Pet Hunger: ${fsPetHunger}`);
        console.error(`   Data Connect - DOGE: ${sqlDoge}, Pet Hunger: ${sqlPetHunger}`);
        allMatch = false;
      } else {
        console.log(`✅ User ${uid} perfectly matches! (DOGE: ${fsDoge}, Pet Hunger: ${fsPetHunger})`);
      }
    }

    if (allMatch) {
      console.log('🎉 Verification successful! All tested users match between Firestore and Data Connect.');
    } else {
      console.log('⚠️ Verification failed. Some users have mismatched data.');
    }

  } catch (error) {
    console.error('Error during verification:', error);
  }
}

verifyData();
