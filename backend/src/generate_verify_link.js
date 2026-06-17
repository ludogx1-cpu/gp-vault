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

    const link = await admin.auth().generateEmailVerificationLink(email);
    console.log('\n--- VERIFICATION LINK ---');
    console.log(link);
    console.log('-------------------------\n');
    console.log('You can also just mark them as verified if you want to save them the trouble:');
    console.log(`node src/verify_user_manual.js ${email}`);
    process.exit(0);
  } catch (error) {
    console.error('Error generating link:', error);
    process.exit(1);
  }
}

main();
