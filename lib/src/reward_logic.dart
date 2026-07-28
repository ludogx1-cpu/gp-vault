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

  static double getStreakMultiplier(int streak) {
    if (streak < 1) return 1.0;
    if (streak == 2) return 1.1;
    if (streak == 3) return 1.2;
    if (streak == 4) return 1.3;
    if (streak == 5) return 1.4;
    if (streak == 6) return 1.5;
    if (streak >= 7) return 1.6;
    return 1.0;
  }

  static int getLevel(int xp) {
    int level = sqrt(xp / 100).floor();
    if (level > 100) return 100;
    return level;
  }
}
