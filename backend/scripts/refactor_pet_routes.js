const fs = require('fs');

let code = fs.readFileSync('backend/src/routes/faucetRoutes.js', 'utf8');

// Replace:
// const snapshot = await transaction.get(userRef);
// if (!snapshot.exists) {
//   throw new Error('User profile not found');
// }
// const data = snapshot.data();
// WITH:
// const petRef = userRef.collection('pet').doc('status');
// const snapshot = await transaction.get(userRef);
// if (!snapshot.exists) {
//   throw new Error('User profile not found');
// }
// const data = snapshot.data();
// const petSnapshot = await transaction.get(petRef);
// Object.assign(data, petSnapshot.data() || {});

code = code.replace(/const snapshot = await transaction\.get\(userRef\);\s*if \(!snapshot\.exists\) \{\s*throw new Error\('User profile not found'\);\s*\}\s*(const data = snapshot\.data\(\);)/g, (match, dataLine) => {
    return `const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw new Error('User profile not found');
      }
      ${dataLine}
      const petSnapshot = await transaction.get(petRef);
      Object.assign(data, petSnapshot.data() || {});`;
});


// Replace:
// const snapshot = await transaction.get(userRef);
// let data = snapshot.data() || {};
// let isNewUser = false;
// WITH:
// const petRef = userRef.collection('pet').doc('status');
// const snapshot = await transaction.get(userRef);
// let data = snapshot.data() || {};
// const petSnapshot = await transaction.get(petRef);
// Object.assign(data, petSnapshot.data() || {});
// let isNewUser = false;

code = code.replace(/const snapshot = await transaction\.get\(userRef\);\s*let data = snapshot\.data\(\) \|\| \{\};\s*let isNewUser = false;/g, () => {
    return `const petRef = userRef.collection('pet').doc('status');
      const snapshot = await transaction.get(userRef);
      let data = snapshot.data() || {};
      const petSnapshot = await transaction.get(petRef);
      Object.assign(data, petSnapshot.data() || {});
      let isNewUser = false;`;
});

fs.writeFileSync('backend/src/routes/faucetRoutes.js', code, 'utf8');
console.log('Fixed faucetRoutes.js reads');
