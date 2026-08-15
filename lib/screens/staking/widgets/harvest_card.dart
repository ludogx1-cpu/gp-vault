import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/widgets.dart'; // For AnimatedHoverCard, LiveInterestDisplay
import '../../../src/theme_provider.dart';

class HarvestCard extends StatelessWidget {
  final double stakedBalance;
  final Timestamp? stakeTimestamp;
  final bool isDark;
  final ThemeProvider themeProvider;
  final VoidCallback onHarvest;

  const HarvestCard({
    super.key,
    required this.stakedBalance,
    required this.stakeTimestamp,
    required this.isDark,
    required this.themeProvider,
    required this.onHarvest,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      backgroundColor: isDark
          ? themeProvider.darkGreyBoxColor
          : Colors.amber.shade100,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.amber,
        width: 0.5,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Text(
                "Total Staked (Principal)",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              LiveInterestDisplay(
                stakedBalance: stakedBalance,
                stakeTimestamp: stakeTimestamp,
              ),
              const SizedBox(height: 8),
              Text(
                "💡 The more you stake, the faster your yield ticks up!",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white70
                      : Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 35,
                child: ElevatedButton.icon(
                  onPressed: stakedBalance > 0
                      ? onHarvest
                      : null,
                  icon: const Icon(
                    Icons.agriculture,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    "HARVEST REWARDS",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
