require('dotenv').config({ path: '.env' });
const { admin } = require('./src/services/firebaseService');

async function check() {
  try {
    let authUsersCount = 0;
    let pageToken;
    do {
      const result = await admin.auth().listUsers(1000, pageToken);
      authUsersCount += result.users.length;
      pageToken = result.pageToken;
    } while (pageToken);
    
    console.log(`Total Auth users: ${authUsersCount}`);
    
    const dbUsers = await admin.firestore().collection('users').count().get();
    console.log(`Total Firestore users: ${dbUsers.data().count}`);
  } catch (e) {
    console.error(e);
  }
}
check();
