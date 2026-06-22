function calculateDogeReward(price) {
  if (price <= 0.02) {
    return 0.016;
  } else if (price >= 0.20) {
    return 0.004;
  } else {
    return 0.016 - ((price - 0.02) / 0.18) * 0.012;
  }
}

module.exports = {
  calculateDogeReward,
};
