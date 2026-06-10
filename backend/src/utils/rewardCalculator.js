function calculateDogeReward(price) {
  if (price <= 0.05) {
    return 0.0008;
  } else if (price >= 0.50) {
    return 0.0002;
  } else {
    return 0.0008 - ((price - 0.05) / 0.45) * 0.0006;
  }
}

module.exports = {
  calculateDogeReward,
};
