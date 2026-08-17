import 'package:flutter_test/flutter_test.dart';
import 'package:gp_faucet/src/reward_logic.dart';

void main() {
  group('RewardLogic', () {
    test('getBaseReward calculates correct reward for low price', () {
      expect(RewardLogic.getBaseReward(0.01), equals(0.01));
      expect(RewardLogic.getBaseReward(0.02), equals(0.01));
    });

    test('getBaseReward calculates correct reward for high price', () {
      expect(RewardLogic.getBaseReward(0.20), equals(0.001));
      expect(RewardLogic.getBaseReward(0.30), equals(0.001));
    });

    test('getBaseReward calculates interpolated reward correctly', () {
      // 0.11 is halfway between 0.02 and 0.20
      // So reward should be halfway between 0.01 and 0.001 -> 0.0055
      expect(RewardLogic.getBaseReward(0.11), closeTo(0.0055, 0.00001));
    });

    test('getStreakBonusPercent calculates multipliers correctly', () {
      expect(RewardLogic.getStreakBonusPercent(0), 0.0);
      expect(RewardLogic.getStreakBonusPercent(1), 1.0);
      expect(RewardLogic.getStreakBonusPercent(2), 2.0);
      expect(RewardLogic.getStreakBonusPercent(3), 3.0);
      expect(RewardLogic.getStreakBonusPercent(4), 4.0);
      expect(RewardLogic.getStreakBonusPercent(5), 5.0);
      expect(RewardLogic.getStreakBonusPercent(10), 10.0);
      expect(RewardLogic.getStreakBonusPercent(11), 10.0);
    });

    test('getLevel calculates correct level based on xp', () {
      expect(RewardLogic.getLevel(0), equals(0));
      expect(RewardLogic.getLevel(100), equals(1));
      expect(RewardLogic.getLevel(400), equals(2));
      expect(RewardLogic.getLevel(900), equals(3));
      expect(RewardLogic.getLevel(10000), equals(10));
      expect(RewardLogic.getLevel(1000000), equals(100));
      expect(RewardLogic.getLevel(2000000), equals(100)); // Max cap at 100
    });
  });
}
