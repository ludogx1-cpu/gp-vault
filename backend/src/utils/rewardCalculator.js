function calculateDogeReward(price) {
  if (price <= 0.02) {
    return 0.01;
  } else if (price >= 0.20) {
    return 0.001;
  } else {
    return 0.01 - ((price - 0.02) / 0.18) * 0.009;
  }
}

module.exports = {
  calculateDogeReward,
};
