const { admin } = require('./src/services/firebaseService');

async function run() {
  const now = new Date();
  const fiveDaysAgo = new Date(now.getTime() - (5 * 24 * 60 * 60 * 1000));
  
  console.log("Checking signups since:", fiveDaysAgo.toISOString());
  
  const snapshot = await admin.firestore().collection('users')
    .where('joined_date', '>=', fiveDaysAgo.toISOString())
    .get();
    
  console.log(`Total signups in the last 5 days: ${snapshot.size}`);
  process.exit(0);
}
run();
