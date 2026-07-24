const { admin } = require('./backend/src/services/firebaseService');

async function fetchLogs() {
  try {
    const snapshot = await admin.firestore().collection('debug_logs').orderBy('timestamp', 'desc').limit(2).get();
    snapshot.forEach(doc => {
      console.log("Log ID:", doc.id);
      console.log(JSON.stringify(doc.data(), null, 2));
    });
  } catch (err) {
    console.error(err);
  } finally {
    process.exit(0);
  }
}
fetchLogs();
