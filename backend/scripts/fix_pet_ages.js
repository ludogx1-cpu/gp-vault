const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin (assuming default credentials or FIREBASE_SERVICE_ACCOUNT_JSON are set)
if (!admin.apps.length) {
  const firebaseServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON
    ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)
    : null;

  if (firebaseServiceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(firebaseServiceAccount),
    });
  } else {
    admin.initializeApp();
  }
}

const db = admin.firestore();

async function fixPetAges() {
  console.log('Starting pet age restoration...');
  const usersSnapshot = await db.collection('users').get();
  
  let migratedCount = 0;
  
  const BATCH_SIZE = 400;
  let batch = db.batch();
  let operationCount = 0;

  for (const doc of usersSnapshot.docs) {
    const data = doc.data();
    if (!data.joined_date) continue;
    
    // Parse joined_date
    const joinedTime = new Date(data.joined_date).getTime();
    if (isNaN(joinedTime)) continue;
    
    const daysOld = (Date.now() - joinedTime) / (1000 * 60 * 60 * 24);
    if (daysOld < 0) continue;
    
    // We give them 35 XP per day so they reach their old stages perfectly
    // (180 days * 35 = 6300 XP = Adult)
    const ageXP = Math.floor(daysOld * 35);
    
    // Check if they already have XP in pet/status
    let existingXP = 0;
    try {
      const petDoc = await doc.ref.collection('pet').doc('status').get();
      if (petDoc.exists) {
        existingXP = petDoc.data().pet_xp || 0;
      }
    } catch (e) {
      // ignore
    }
    
    const finalXP = Math.max(existingXP, ageXP);
    const birthDateTimestamp = admin.firestore.Timestamp.fromMillis(joinedTime);
    
    const userUpdates = {
      pet_birth_date: birthDateTimestamp,
      pet_xp: finalXP
    };
    
    // Write to users/{uid} (needed for faucetService which hasn't been fully refactored)
    batch.update(doc.ref, userUpdates);
    operationCount++;
    
    // Write to users/{uid}/pet/status
    const petRef = doc.ref.collection('pet').doc('status');
    batch.set(petRef, userUpdates, { merge: true });
    operationCount++;
    
    migratedCount++;
    
    if (operationCount >= BATCH_SIZE) {
      await batch.commit();
      console.log(`Committed batch... (Fixed ${migratedCount} users so far)`);
      batch = db.batch();
      operationCount = 0;
    }
  }
  
  if (operationCount > 0) {
    await batch.commit();
  }
  
  console.log(`Restoration complete! Successfully restored pet age/xp for ${migratedCount} users.`);
  process.exit(0);
}

fixPetAges().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
