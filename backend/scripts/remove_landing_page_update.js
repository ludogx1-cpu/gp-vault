const { admin } = require('./src/services/firebaseService');

async function run() {
  const db = admin.firestore();
  
  const snapshot = await db.collection('updates').get();
  
  if (!snapshot.empty) {
    const batch = db.batch();
    let deleted = 0;
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const title = (data.title || '').toLowerCase();
      const msg = (data.message || '').toLowerCase();
      
      if (title.includes('landing page') || msg.includes('landing page') || title.includes('about page') || msg.includes('about page')) {
        console.log(`Deleting about/landing page update: ${doc.id}`);
        batch.delete(doc.ref);
        deleted++;
      }
    });
    
    if (deleted > 0) {
      await batch.commit();
      console.log(`Deleted ${deleted} updates about the landing page/about page.`);
    } else {
      console.log('No landing page updates found.');
    }
  }

  process.exit(0);
}

run();
