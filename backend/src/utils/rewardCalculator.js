function calculateDogeReward(price) {
  if (price <= 0.05) {
    return 0.016;
  } else if (price >= 0.50) {
    return 0.004;
  } else {
    return 0.016 - ((price - 0.05) / 0.45) * 0.012;
  }
}

module.exports = {
  calculateDogeReward,
};
