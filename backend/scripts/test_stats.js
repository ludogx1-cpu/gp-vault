const { admin } = require('./src/services/firebaseService');
async function run() {
  try {
    const db = admin.firestore();
    const uid = 'pvFYdxQcvlcWtEtQrHXi272Fk2z1';
    
    const snapshot = await db.collection('users').doc(uid).get();
    console.log(JSON.stringify(snapshot.data(), null, 2));
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}
run();
