const { admin } = require('./src/services/firebaseService');
async function run() {
  const withdrawSnap = await admin.firestore().collection('withdrawals').get();
  withdrawSnap.forEach(d => {
    const w = d.data();
    if (w.email === 'cunoslife@gmail.com' || w.email === 'eetusavo95@gmail.com') {
      console.log(w.email, 'withdrew', w.amount, 'on', w.timestamp.toDate());
    }
  });
  process.exit(0);
}
run();
