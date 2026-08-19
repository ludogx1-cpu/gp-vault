const fs = require('fs');
const path = './backend/src/services/petService.js';
let content = fs.readFileSync(path, 'utf8');

if (!content.includes("const { syncUserBalances, syncPetStats } = require('../utils/dataConnectSync');")) {
    content = content.replace("const { getDogePrice } = require('./priceService');", "const { getDogePrice } = require('./priceService');\nconst { syncUserBalances, syncPetStats } = require('../utils/dataConnectSync');");
}

const endpoints = [
    'petStatus', 'petFeed', 'petPlay', 'petSleep', 'petStroke', 'petWalkSync', 
    'petCleanPoo', 'petBoop', 'petAdminAgeUp', 'petBuyAccessory', 'petEquipAccessory',
    'petBuyTrick', 'petTrick', 'petBuyConsumable', 'petUseConsumable', 'petBuyBall',
    'petEquipBall', 'petFetch'
];

for (let func of endpoints) {
    let regex = new RegExp(`(async function ${func}\\(req\\) \\{\\s*try \\{[\\s\\S]*?)await admin\\.firestore\\(\\)\\.runTransaction\\(async \\(transaction\\) => \\{`, 'g');
    content = content.replace(regex, `$1
    let dualWriteUpdates = {};
    let initialData = {};
    await admin.firestore().runTransaction(async (transaction) => {`);
}

content = content.replace(/const \{ userUpdates, petUpdates \} = splitUpdates\(updates\);/g, 
`Object.assign(dualWriteUpdates, updates);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updates);`);

content = content.replace(/const \{ userUpdates, petUpdates \} = splitUpdates\(initData\);/g, 
`Object.assign(dualWriteUpdates, initData);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(initData);`);

content = content.replace(/const \{ userUpdates, petUpdates \} = splitUpdates\(updatePayload\);/g, 
`Object.assign(dualWriteUpdates, updatePayload);
      initialData = data || {};
      const { userUpdates, petUpdates } = splitUpdates(updatePayload);`);

// For petRename, it uses `await userRef.set({ pet_name: newName }, { merge: true });`
content = content.replace(/await userRef\.set\(\{\n\s*pet_name: newName\n\s*\}, \{ merge: true \}\);/g, 
`await userRef.set({ pet_name: newName }, { merge: true });
    // Assuming pet_name is not synced to Data Connect balances right now, but if it is we'd sync here.`);

// Add sync block after the transaction
content = content.replace(/\n    \}\);\n\n    return \{/g, 
`
    });

    if (Object.keys(dualWriteUpdates).length > 0) {
      syncUserBalances(req.user.uid, initialData, dualWriteUpdates).catch(console.error);
      syncPetStats(req.user.uid, initialData, dualWriteUpdates).catch(console.error);
    }

    return {`);
    
content = content.replace(/\n    \}\);\n\n    const msg/g, 
`
    });

    if (Object.keys(dualWriteUpdates).length > 0) {
      syncUserBalances(req.user.uid, initialData, dualWriteUpdates).catch(console.error);
      syncPetStats(req.user.uid, initialData, dualWriteUpdates).catch(console.error);
    }

    const msg`);

fs.writeFileSync(path, content);
console.log('Done replacing!');
