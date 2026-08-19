const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { migrateUser } = require('../src/dataconnect-admin-generated');

if (!admin.apps.length) {
  // We assume FIREBASE_CONFIG or GOOGLE_APPLICATION_CREDENTIALS is set,
  // or it's run via firebase functions:shell / initialized manually
  // For local emulator test, this requires standard setup.
  admin.initializeApp();
}

const db = admin.firestore();
const BACKUP_FILE = path.join(__dirname, 'firestore_users_backup.json');

async function migrateUsers() {
  console.log('Starting User Migration...');
  try {
    const snapshot = await db.collection('users').get();
    const users = [];

    snapshot.forEach(doc => {
      users.push({ id: doc.id, ...doc.data() });
    });

    console.log(`Found ${users.length} users in Firestore.`);
    
    // 1. Create a local backup
    fs.writeFileSync(BACKUP_FILE, JSON.stringify(users, null, 2));
    console.log(`✅ Backup saved to ${BACKUP_FILE}`);

    // 2. Migrate to Data Connect
    let successCount = 0;
    let errorCount = 0;

    for (const user of users) {
      try {
        const payload = {
          id: user.id,
          dogeBalance: Number(user.doge_balance || 0),
          stakedBalance: Number(user.staked_balance || 0),
          bankBalance: Number(user.bank_balance || 0),
          offerwallBalance: Number(user.offerwall_balance || 0),
          adsBalance: Number(user.ads_balance || 0),
          xp: Number(user.xp || 0),
          role: user.role || 'user',
          totalClaims: Number(user.total_claims || 0),
          faucetClaims: Number(user.total_faucet_claims || 0),
          lastClaimTime: user.last_claim_time ? user.last_claim_time.toDate().toISOString() : null,
          stakeTimestamp: user.stake_timestamp ? user.stake_timestamp.toDate().toISOString() : null,
          petBirthDate: user.pet_birth_date ? user.pet_birth_date.toDate().toISOString() : null,
          petHunger: Number(user.pet_hunger ?? 100),
          petHappiness: Number(user.pet_happiness ?? 100),
          petEnergy: Number(user.pet_energy ?? 100),
          petLastInteraction: user.pet_last_interaction ? user.pet_last_interaction.toDate().toISOString() : null,
          petTotalDistanceWalked: Number(user.pet_total_distance_walked || 0)
        };
        
        // Remove nulls since GraphQL variables for Data Connect handle undefined/missing better than explicit nulls sometimes, 
        // though DataConnect variables allow null.
        Object.keys(payload).forEach(key => {
          if (payload[key] === null) {
            delete payload[key];
          }
        });

        await migrateUser(payload);
        successCount++;
        if (successCount % 10 === 0) console.log(`Migrated ${successCount} users...`);
      } catch (err) {
        errorCount++;
        console.error(`Failed to migrate user ${user.id}:`, err.message);
      }
    }
    console.log(`Migration complete! Successfully migrated ${successCount} users. Errors: ${errorCount}`);
  } catch (err) {
    console.error('Migration failed:', err);
  }
}

migrateUsers();
