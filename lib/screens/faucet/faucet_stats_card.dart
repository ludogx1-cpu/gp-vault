import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../src/user_provider.dart';
import '../../src/theme_provider.dart';
import '../../widgets/shiba_pet_widget.dart';
import 'leaderboard_preview.dart';

class FaucetStatsCard extends StatelessWidget {
  final double currentDogePrice;

  const FaucetStatsCard({
    super.key,
    required this.currentDogePrice,
  });

  double _getBaseReward(double price) {
    if (price <= 0.02) {
      return 0.01;
    }
    if (price >= 0.20) {
      return 0.001;
    }
    return 0.01 - ((price - 0.02) / 0.18) * 0.009;
  }

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
              if (streak < 1) { streak = 1; }
              
              double streakMultiplier = 1.0;
              if (streak == 2) {
                streakMultiplier = 1.1;
              } else if (streak == 3) { streakMultiplier = 1.2; }
              else if (streak == 4) { streakMultiplier = 1.3; }
              else if (streak == 5) { streakMultiplier = 1.4; }
              else if (streak == 6) { streakMultiplier = 1.5; }
              else if (streak >= 7) { streakMultiplier = 1.6; }
              
              int level = sqrt(xp / 100).floor();
              if (level > 100) { level = 100; }
              int levelBonus = level;
              int streakBonus = streak;
              int totalBonusPercent = levelBonus + streakBonus;
              double baseReward = _getBaseReward(currentDogePrice);
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
                      return Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          maxWidth: 800,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? themeProvider.darkGreyBoxColor
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: isDark
                              ? Border.all(
                                  color: themeProvider.darkGreyBorder,
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Text(
                                  "Current Vault Reward: +${expectedReward.toStringAsFixed(6)} DOGE  &  +10 XP",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.amber.shade300
                                        : Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Base: ${baseReward.toStringAsFixed(6)}  |  Lvl Bonus: +$levelBonus%  |  Streak: Day $streak (${streakMultiplier}x)",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.amber.shade200
                                    : Colors.green.shade800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              color: isDark
                                  ? Colors.amber.withValues(alpha: 0.5)
                                  : Colors.green,
                              height: 2,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Earn 10 XP per claim to level up and boost your daily multipliers!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.green.shade900,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Your base reward scales dynamically against the USD value of DOGE between 0.001 and 0.01. The cheaper DOGE gets, the more you earn!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white60
                                    : Colors.green.shade800,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
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
                  border: isDark
                      ? Border.all(
                          color: themeProvider.darkGreyBorder,
                          width: 1,
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Current Base Reward: ${_getBaseReward(currentDogePrice).toStringAsFixed(6)} DOGE\n(Log in to unlock XP & Multipliers!)",
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
}
