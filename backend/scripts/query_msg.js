const { admin } = require('./src/services/firebaseService');
async function run() {
  const snap = await admin.firestore().collection('debug_logs').get();
  snap.forEach(d => {
    const data = d.data();
    if (data.message) {
      console.log(data.message.substring(0, 50));
    }
  });
  process.exit(0);
}
run();
