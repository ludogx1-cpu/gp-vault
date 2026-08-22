
const petCare = require('./petCareService');
const petInv = require('./petInventoryService');

module.exports = {
  ...petCare,
  ...petInv,
  ensureXP: function() {}, // Stub if exported
  calculateXPGain: function() {} // Stub if exported
};
