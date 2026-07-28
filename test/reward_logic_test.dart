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

    test('getStreakMultiplier calculates correct multipliers', () {
      expect(RewardLogic.getStreakMultiplier(0), equals(1.0));
      expect(RewardLogic.getStreakMultiplier(1), equals(1.0));
      expect(RewardLogic.getStreakMultiplier(2), equals(1.1));
      expect(RewardLogic.getStreakMultiplier(3), equals(1.2));
      expect(RewardLogic.getStreakMultiplier(4), equals(1.3));
      expect(RewardLogic.getStreakMultiplier(5), equals(1.4));
      expect(RewardLogic.getStreakMultiplier(6), equals(1.5));
      expect(RewardLogic.getStreakMultiplier(7), equals(1.6));
      expect(RewardLogic.getStreakMultiplier(10), equals(1.6));
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
