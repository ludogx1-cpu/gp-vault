require('dotenv').config({ path: '../.env' });
const { admin } = require('./services/firebaseService');

async function main() {
  const email = process.argv[2];
  if (!email) {
    console.error('Please provide an email address as an argument.');
    process.exit(1);
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    console.log(`Found user: ${userRecord.uid}`);
    
    if (userRecord.emailVerified) {
      console.log('User email is already verified.');
      process.exit(0);
    }

    await admin.auth().updateUser(userRecord.uid, { emailVerified: true });
    console.log(`Successfully verified email for user ${email}`);
    process.exit(0);
  } catch (error) {
    console.error('Error verifying user:', error);
    process.exit(1);
  }
}

main();
