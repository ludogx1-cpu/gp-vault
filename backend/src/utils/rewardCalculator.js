function calculateDogeReward(price) {
  if (price <= 0.05) {
    return 0.0016;
  } else if (price >= 0.50) {
    return 0.0004;
  } else {
    return 0.0016 - ((price - 0.05) / 0.45) * 0.0012;
  }
}

module.exports = {
  calculateDogeReward,
};
