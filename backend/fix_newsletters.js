const { admin } = require('./src/services/firebaseService');

async function fixNewsletters() {
  try {
    const db = admin.firestore();
    const snapshot = await db.collection('blog_posts').get();
    
    let count = 0;
    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (!data.category) {
        console.log(`Fixing doc ${doc.id}: ${data.topic}`);
        await doc.ref.update({
          category: 'newsletter',
          approved: true
        });
        count++;
      }
    }
    
    console.log(`Successfully fixed ${count} newsletters!`);
    process.exit(0);
  } catch (error) {
    console.error('Error fixing newsletters:', error);
    process.exit(1);
  }
}

fixNewsletters();
