const { admin } = require('./src/services/firebaseService');
async function run() {
  const snap = await admin.firestore().collection('chat_messages').get();
  snap.forEach(d => {
    const data = d.data();
    if (data.message && (data.message.toLowerCase().includes('fail') || data.message.toLowerCase().includes('withdraw'))) {
      console.log(data.display_name, ':', data.message);
    }
  });
  process.exit(0);
}
run();
