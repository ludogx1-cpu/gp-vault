import 'dart:math';

class RewardLogic {
  static double getBaseReward(double price) {
    if (price <= 0.02) {
      return 0.01;
    }
    if (price >= 0.20) {
      return 0.001;
    }
    return 0.01 - ((price - 0.02) / 0.18) * 0.009;
  }

  static double getStreakBonusPercent(int streak) {
    if (streak <= 0) return 0.0;
    return (streak > 10 ? 10 : streak).toDouble();
  }

  static int getLevel(int xp) {
    int level = sqrt(xp / 100).floor();
    if (level > 100) return 100;
    return level;
  }
}
