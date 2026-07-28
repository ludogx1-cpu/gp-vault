const { admin } = require('./src/services/firebaseService');
async function run() {
  const snapshot = await admin.firestore().collection('users').limit(1).get();
  snapshot.forEach(doc => {
    console.log(Object.keys(doc.data()));
    console.log(doc.data().created_at || doc.data().timestamp || doc.data());
  });
  process.exit(0);
}
run();
