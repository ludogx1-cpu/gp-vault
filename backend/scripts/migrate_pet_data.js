const admin = require('firebase-admin');

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

async function migratePetData() {
  console.log('Starting pet data migration...');
  const usersSnapshot = await db.collection('users').get();
  
  let migratedCount = 0;
  
  const BATCH_SIZE = 500;
  let batch = db.batch();
  let operationCount = 0;

  for (const doc of usersSnapshot.docs) {
    const data = doc.data();
    
    const petKeys = Object.keys(data).filter(key => 
      key.startsWith('pet_') || 
      key === 'active_trick_buffs' || 
      key === 'fetch_click_count' || 
      key === 'weekly_time_above_40'
    );

    if (petKeys.length > 0) {
      const petRef = db.collection('users').doc(doc.id).collection('pet').doc('status');
      
      const petData = {};
      const userUpdates = {};
      
      for (const key of petKeys) {
        petData[key] = data[key];
        userUpdates[key] = admin.firestore.FieldValue.delete();
      }
      
      batch.set(petRef, petData, { merge: true });
      operationCount++;
      
      batch.update(doc.ref, userUpdates);
      operationCount++;
      
      migratedCount++;
      
      if (operationCount >= BATCH_SIZE) {
        await batch.commit();
        console.log(`Committed batch... (Migrated ${migratedCount} users so far)`);
        batch = db.batch();
        operationCount = 0;
      }
    }
  }
  
  if (operationCount > 0) {
    await batch.commit();
  }
  
  console.log(`Migration complete! Successfully migrated pet data for ${migratedCount} users.`);
  process.exit(0);
}

migratePetData().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
