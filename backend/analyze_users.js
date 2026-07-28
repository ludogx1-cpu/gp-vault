const { admin } = require('./src/services/firebaseService');

async function run() {
  const snapshot = await admin.firestore().collection('users').get();
  
  let maxDoge = 0;
  let maxDogeUser = null;
  
  let maxBank = 0;
  let maxBankUser = null;

  let maxOfferwall = 0;
  let maxOfferwallUser = null;
  
  let maxCombined = 0;
  let maxCombinedUser = null;
  
  let maxXP = 0;
  let maxXPUser = null;

  snapshot.forEach(doc => {
    const data = doc.data();
    const doge = Number(data.doge_balance) || 0;
    const bank = Number(data.bank_balance) || 0;
    const offerwall = Number(data.offerwall_balance) || 0;
    const staked = Number(data.staked_balance) || 0;
    const combined = doge + bank + offerwall + staked;
    const xp = Number(data.xp) || 0;

    if (doge > maxDoge) { maxDoge = doge; maxDogeUser = data.email; }
    if (bank > maxBank) { maxBank = bank; maxBankUser = data.email; }
    if (offerwall > maxOfferwall) { maxOfferwall = offerwall; maxOfferwallUser = data.email; }
    if (combined > maxCombined) { maxCombined = combined; maxCombinedUser = data.email; }
    if (xp > maxXP) { maxXP = xp; maxXPUser = data.email; }
  });

  console.log('Max combined balance:', maxCombined, 'User:', maxCombinedUser);
  console.log('Max Doge balance:', maxDoge, 'User:', maxDogeUser);
  console.log('Max Bank balance:', maxBank, 'User:', maxBankUser);
  console.log('Max Offerwall balance:', maxOfferwall, 'User:', maxOfferwallUser);
  console.log('Max XP:', maxXP, 'User:', maxXPUser);
  
  process.exit(0);
}
run();
