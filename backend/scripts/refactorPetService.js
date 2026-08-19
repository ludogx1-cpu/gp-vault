const fs = require('fs');

const path = './backend/src/services/petService.js';
let content = fs.readFileSync(path, 'utf8');

if (!content.includes("const { syncUserBalances, syncPetStats } = require('../utils/dataConnectSync');")) {
    content = content.replace("const { getDogePrice } = require('./priceService');", "const { getDogePrice } = require('./priceService');\nconst { syncUserBalances, syncPetStats } = require('../utils/dataConnectSync');");
}

// Regex to find all `await admin.firestore().runTransaction` and assign to `txResult`
const endpoints = [
    'petStatus', 'petFeed', 'petPlay', 'petSleep', 'petStroke', 'petWalkSync', 
    'petCleanPoo', 'petBoop', 'petAdminAgeUp', 'petBuyAccessory', 'petEquipAccessory',
    'petBuyTrick', 'petTrick', 'petBuyConsumable', 'petUseConsumable', 'petBuyBall',
    'petEquipBall', 'petFetch'
];

// Instead of regex, I'll just write a loop to do string replacements for each one carefully.
// This is a bit tricky with plain regex. I'll run this script and see what happens.
// Wait, I can just use AST or simple replacement.

for (let func of endpoints) {
    let regex = new RegExp(`(async function ${func}\\(req\\) \\{\\s*try \\{[\\s\\S]*?)await admin\\.firestore\\(\\)\\.runTransaction\\(async \\(transaction\\) => \\{`, 'g');
    content = content.replace(regex, `$1const txResult = await admin.firestore().runTransaction(async (transaction) => {`);
}

// Find all `const { userUpdates, petUpdates } = splitUpdates(updates);` and insert `return { data, updates };` at the end of the transaction
content = content.replace(/const \{ userUpdates, petUpdates \} = splitUpdates\(updates\);\s*if \(Object\.keys\(userUpdates\)\.length > 0\) transaction\.update\(userRef, userUpdates\);\s*if \(Object\.keys\(petUpdates\)\.length > 0\) transaction\.set\(petRef, petUpdates, \{ merge: true \}\);/g, 
`const { userUpdates, petUpdates } = splitUpdates(updates);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
      return { data, updates };`);

content = content.replace(/const \{ userUpdates, petUpdates \} = splitUpdates\(initData\);\s*if \(Object\.keys\(userUpdates\)\.length > 0\) transaction\.update\(userRef, userUpdates\);\s*if \(Object\.keys\(petUpdates\)\.length > 0\) transaction\.set\(petRef, petUpdates, \{ merge: true \}\);/g, 
`const { userUpdates, petUpdates } = splitUpdates(initData);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
      return { data, updates: initData };`);

content = content.replace(/const \{ userUpdates, petUpdates \} = splitUpdates\(updatePayload\);\s*if \(Object\.keys\(userUpdates\)\.length > 0\) transaction\.update\(userRef, userUpdates\);\s*if \(Object\.keys\(petUpdates\)\.length > 0\) transaction\.set\(petRef, petUpdates, \{ merge: true \}\);/g, 
`const { userUpdates, petUpdates } = splitUpdates(updatePayload);
      if (Object.keys(userUpdates).length > 0) transaction.update(userRef, userUpdates);
      if (Object.keys(petUpdates).length > 0) transaction.set(petRef, petUpdates, { merge: true });
      return { data, updates: updatePayload };`);

// For petStatus `petStats = {` we need to insert the return AFTER `petStats = { ... };` since it's the end of transaction
// Actually, it's easier to inject the dual write logic after the transaction block `});`
content = content.replace(/\n    \}\);\n\n    return \{/g, 
`
    });

    if (txResult) {
      syncUserBalances(req.user.uid, txResult.data, txResult.updates).catch(console.error);
      syncPetStats(req.user.uid, txResult.data, txResult.updates).catch(console.error);
    }

    return {`);
    
content = content.replace(/\n    \}\);\n\n    const msg/g, 
`
    });

    if (txResult) {
      syncUserBalances(req.user.uid, txResult.data, txResult.updates).catch(console.error);
      syncPetStats(req.user.uid, txResult.data, txResult.updates).catch(console.error);
    }

    const msg`);

fs.writeFileSync(path, content);
console.log('Done replacing!');
