require('dotenv').config();
const { faucetPaySend } = require('./src/services/faucetPayService');

async function test() {
  try {
    const { admin } = require('./src/services/firebaseService');
    const userSnapshot = await admin.firestore().collection('users').doc('P8iffVqbUgetAVA4MdHVZ1CfvUv1').get();
    
    // Check if user has an address saved or just use a valid test one
    const address = userSnapshot.data().faucetpay_address || 'D8HkZ3sM6qXh8nB4A5d8yQhL2vTj1K9mP'; 
    console.log("User FaucetPay address:", address);
    
    // We will test with a very small amount, like 0.00001 DOGE if possible, or just 1 DOGE if min is 1
    // Actually, maybe let's just make a bad request on purpose to see the real error with the valid API key?
    // Let's use a clearly invalid address to see if the API key is working.
    console.log("Attempting to send to an invalid address to check API key status:");
    try {
      await faucetPaySend('invalid_address_123', "1");
    } catch(e) {
      console.log("Error from FaucetPay:", e.message);
    }
  } catch (error) {
    console.error("Script Error:", error);
  }
  process.exit(0);
}
test();
