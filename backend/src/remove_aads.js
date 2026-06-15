const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const db = admin.firestore();
    const batch = db.batch();
    
    batch.delete(db.collection('sponsor_placeholders').doc('NKyKCRJryZazEgQlQDXV'));
    batch.delete(db.collection('sponsor_placeholders').doc('TSD6CviaQ9UxQVOW1DsE'));
    batch.delete(db.collection('sponsor_placeholders').doc('YPHViQuORwoLdDe4QsIQ'));
    
    await batch.commit();
    console.log("Successfully removed the 3 AADS from sponsor_placeholders!");
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}
run();
