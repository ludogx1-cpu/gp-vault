const fs = require('fs');
const path = require('path');

const srcPath = path.join(__dirname, '../src/services/petService.js');
const carePath = path.join(__dirname, '../src/services/petCareService.js');
const invPath = path.join(__dirname, '../src/services/petInventoryService.js');

let content = fs.readFileSync(srcPath, 'utf8');

const headerRegex = /([\s\S]*?)module\.exports\s*=\s*\{/;
const headerMatch = content.match(headerRegex);
const header = headerMatch ? headerMatch[1] : '';

const careFuncs = ['petStatus', 'petFeed', 'petPlay', 'petSleep', 'petStroke', 'petWalkSync', 'petCleanPoo', 'petBoop'];
const invFuncs = ['petRename', 'petAdminAgeUp', 'petBuyAccessory', 'petEquipAccessory', 'petBuyTrick', 'petTrick', 'petBuyConsumable', 'petUseConsumable', 'petBuyBall', 'petEquipBall', 'petFetch'];

function extractFunction(name) {
  // Regex to match "async function <name>(req) { ... }" handling nested braces
  // This is hard to do with pure regex safely, but since the functions are top-level we can look for the next "async function " or end of file
  const regex = new RegExp(`async function ${name}\\(.*?\\)\\s*\\{[\\s\\S]*?(?=\\nasync function |$)`);
  const match = content.match(regex);
  return match ? match[0] : '';
}

let careContent = header + '\n\nmodule.exports = {\n  ' + careFuncs.join(',\n  ') + '\n};\n\n';
careFuncs.forEach(func => {
  careContent += extractFunction(func) + '\n\n';
});

let invContent = header + '\n\nmodule.exports = {\n  ' + invFuncs.join(',\n  ') + '\n};\n\n';
invFuncs.forEach(func => {
  invContent += extractFunction(func) + '\n\n';
});

fs.writeFileSync(carePath, careContent);
fs.writeFileSync(invPath, invContent);

const indexContent = `
const petCare = require('./petCareService');
const petInv = require('./petInventoryService');

module.exports = {
  ...petCare,
  ...petInv,
  ensureXP: function() {}, // Stub if exported
  calculateXPGain: function() {} // Stub if exported
};
`;
fs.writeFileSync(srcPath, indexContent);
console.log('Successfully split petService.js');
