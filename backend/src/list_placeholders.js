const { admin } = require('./services/firebaseService');

async function run() {
  try {
    const snapshot = await admin.firestore().collection('sponsor_placeholders').get();
    snapshot.forEach(doc => {
      console.log(doc.id, "=>", doc.data());
    });
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}
run();
