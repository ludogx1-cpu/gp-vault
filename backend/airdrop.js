require('dotenv').config();
const { admin } = require('./src/services/firebaseService');
const { faucetPaySend } = require('./src/services/faucetPayService');

// Delay helper to prevent hitting FaucetPay rate limits
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function runFaucetPayAirdrop() {
  // ⚠️ CHANGE THIS AMOUNT TO WHAT YOU WANT TO SEND (e.g. 0.05 DOGE)
  const AIRDROP_AMOUNT = 0.0003; 

  console.log(`Starting real FaucetPay airdrop of ${AIRDROP_AMOUNT} DOGE to all users...`);
  
  try {
    const usersSnapshot = await admin.firestore().collection('users').get();
    
    if (usersSnapshot.empty) {
      console.log('No users found in database.');
      process.exit(0);
    }

    console.log(`Found ${usersSnapshot.size} users. Processing FaucetPay API calls...`);

    let successCount = 0;
    let failCount = 0;

    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const userEmail = userData.email;

      if (!userEmail) {
        continue; // Skip users with no email
      }

      try {
        // Attempt to send directly to their email via FaucetPay API
        const response = await faucetPaySend(userEmail, AIRDROP_AMOUNT);
        
        if (response.status === 200) {
          successCount++;
          console.log(`✅ Sent ${AIRDROP_AMOUNT} DOGE to ${userEmail}`);
        } else {
          failCount++;
          console.log(`❌ Failed to send to ${userEmail}: ${response.message}`);
        }
      } catch (err) {
        failCount++;
        console.log(`❌ Error sending to ${userEmail}: ${err.response?.data?.message || err.message}`);
      }

      // Sleep for 500ms between API calls to avoid FaucetPay rate limits
      await sleep(500);
    }

    console.log(`\n🎉 Airdrop finished!`);
    console.log(`✅ Successful Transfers: ${successCount}`);
    console.log(`❌ Failed Transfers (likely don't have FaucetPay accounts under this email): ${failCount}`);
    console.log(`💸 Total DOGE sent: ${(successCount * AIRDROP_AMOUNT).toFixed(2)} DOGE`);
    
    process.exit(0);

  } catch (error) {
    console.error('Fatal error running airdrop:', error);
    process.exit(1);
  }
}

runFaucetPayAirdrop();
