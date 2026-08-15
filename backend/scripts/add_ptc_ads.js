require('dotenv').config();
const { admin } = require('./src/services/firebaseService');

async function addPtcAds() {
  try {
    const db = admin.firestore();
    
    // Surfe.be
    await db.collection('ptc_ads').add({
      target_url: 'https://surfe.be/rar/2433417',
      title: 'Surfe.be - Earn Crypto Surfing',
      tier: 'custom',
      duration: 30,
      reward: 0.008,
      clicks_total: 999999,
      clicks_remaining: 999999,
      creator_uid: 'admin',
      status: 'active',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Satoshi Hero
    await db.collection('ptc_ads').add({
      target_url: 'https://satoshihero.com/register?r=62g97002',
      title: 'Satoshi Hero - Free Crypto Games',
      tier: 'custom',
      duration: 30,
      reward: 0.008,
      clicks_total: 999999,
      clicks_remaining: 999999,
      creator_uid: 'admin',
      status: 'active',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('Successfully added PTC ads to Firestore!');
    process.exit(0);
  } catch (error) {
    console.error('Error adding PTC ads:', error);
    process.exit(1);
  }
}

addPtcAds();
