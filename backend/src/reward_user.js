require('dotenv').config({ path: '../.env' });
const { admin } = require('./services/firebaseService');

async function main() {
  const email = process.argv[2];
  const rewardString = process.argv[3];

  if (!email || !rewardString) {
    console.error('Usage: node src/reward_user.js <email> <amount>');
    process.exit(1);
  }

  const reward = Number(rewardString);
  if (isNaN(reward) || reward <= 0) {
    console.error('Reward must be a positive number');
    process.exit(1);
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    console.log(`Found user: ${userRecord.uid}`);
    
    const userRef = admin.firestore().collection('users').doc(userRecord.uid);
    
    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw new Error('User document not found in Firestore');
      }
      
      const data = snapshot.data();
      const currentBalance = Number(data.doge_balance || 0);
      const newBalance = currentBalance + reward;
      
      transaction.update(userRef, { doge_balance: newBalance });
      console.log(`Added ${reward} DOGE. Old Balance: ${currentBalance}, New Balance: ${newBalance}`);
    });

    console.log('Reward successfully added!');
    process.exit(0);
  } catch (error) {
    console.error('Error rewarding user:', error);
    process.exit(1);
  }
}

main();
