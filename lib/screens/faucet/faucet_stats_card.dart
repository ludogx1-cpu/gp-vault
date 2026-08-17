import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../src/user_provider.dart';
import '../../src/theme_provider.dart';
import '../../src/reward_logic.dart';
import '../../widgets/shiba_pet_widget.dart';
import 'leaderboard_preview.dart';

class FaucetStatsCard extends StatelessWidget {
  final double currentDogePrice;
  final bool isPriceStale;

  const FaucetStatsCard({
    super.key,
    required this.currentDogePrice,
    this.isPriceStale = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          return Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final data = userProvider.userData;
              int xp = (data?['xp'] ?? 0).toInt();
              int streak = (data?['streak_count'] ?? 0).toInt();
              
              int levelBonus = RewardLogic.getLevel(xp);
              double streakBonus = RewardLogic.getStreakBonusPercent(streak);
              double totalBonusPercent = levelBonus + streakBonus;
              double baseReward = RewardLogic.getBaseReward(currentDogePrice);
              double expectedReward =
                  baseReward * (1 + (totalBonusPercent / 100));

              return Column(
                children: [
                  const ShibaPetWidget(),
                  const SizedBox(height: 20),
                  const LeaderboardPreview(),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, _) {
                      final isDark = themeProvider.isDarkMode;
                      final boxColor = isDark ? themeProvider.darkGreyBoxColor : Colors.green.shade50;
                      final borderColor = isDark ? Colors.amber.withValues(alpha: 0.5) : Colors.green.shade300;
                      final primaryTextColor = isDark ? Colors.amber.shade300 : Colors.green.shade900;
                      final secondaryTextColor = isDark ? Colors.white70 : Colors.green.shade800;

                      return Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black26 : Colors.green.shade100,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stars, color: primaryTextColor),
                                const SizedBox(width: 8),
                                Text(
                                  "Your Reward Boosts",
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Boost Breakdown
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildBoostRow("Level $levelBonus Bonus", "+$levelBonus%", Icons.trending_up, secondaryTextColor),
                                  const SizedBox(height: 8),
                                  _buildBoostRow("Day $streak Streak", "+${streakBonus.toStringAsFixed(0)}%", Icons.local_fire_department, Colors.orange),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(height: 1, thickness: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Global Multiplier",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryTextColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "+${totalBonusPercent.toStringAsFixed(0)}%",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            Text(
                              "Your +${totalBonusPercent.toStringAsFixed(0)}% boost is automatically applied to all Faucet claims, PTC ads, and Staking yields!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 16),
                            
                            // Faucet Specific Output
                            Column(
                              children: [
                                Text(
                                  "Next Faucet Claim",
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "+${expectedReward.toStringAsFixed(6)} DOGE & +10 XP",
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "(Base: ${baseReward.toStringAsFixed(6)} DOGE)",
                                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                                ),
                              ],
                            ),

                            if (isPriceStale) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: isDark ? Colors.red.shade400 : Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "DOGE price data is stale. Wait for an update before claiming.",
                                        style: TextStyle(
                                          color: isDark ? Colors.red.shade400 : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black12 : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Streak Rules: Earn +1% per day (Max 10%). Missing a day resets your streak to 0!",
                                          style: TextStyle(color: secondaryTextColor, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Dynamic Scaling: Rewards increase as the USD value of DOGE drops.",
                                          style: TextStyle(color: secondaryTextColor, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        } else {
          return ListenableBuilder(
            listenable: themeProvider,
            builder: (context, _) {
              final isDark = themeProvider.isDarkMode;
              return Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? themeProvider.darkGreyBoxColor
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Current Base Reward: ${RewardLogic.getBaseReward(currentDogePrice).toStringAsFixed(6)} DOGE\n(Log in to unlock XP & Multipliers!)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.amber.shade300
                            : Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Rewards scale dynamically between 0.001 and 0.01. If the USD value of DOGE drops, you earn more DOGE!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : Colors.green.shade900,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildBoostRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: iconColor.withValues(alpha: 0.9), // Ensures valid text color in both themes
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: iconColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
