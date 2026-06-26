function calculateDogeReward(price) {
  if (price <= 0.02) {
    return 0.002;
  } else if (price >= 0.20) {
    return 0.0002;
  } else {
    return 0.002 - ((price - 0.02) / 0.18) * 0.0018;
  }
}

module.exports = {
  calculateDogeReward,
};
