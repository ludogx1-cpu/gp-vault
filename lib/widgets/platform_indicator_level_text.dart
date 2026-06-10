import 'package:flutter/material.dart';

class PlatformIndicatorLevelText extends StatelessWidget {
  const PlatformIndicatorLevelText({
    super.key,
    required this.level,
    required this.xp,
    required this.currentLevelXp,
    required this.nextLevelXp,
  });

  final int level;
  final int xp;
  final int currentLevelXp;
  final int nextLevelXp;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        level >= 100
            ? "MAX LEVEL"
            : "${xp - currentLevelXp} / ${nextLevelXp - currentLevelXp} XP to Level ${level + 1}",
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
