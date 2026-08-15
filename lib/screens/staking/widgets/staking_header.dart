import 'package:flutter/material.dart';
import '../../../widgets/widgets.dart'; // For AnimatedHoverCard
import '../../../src/theme_provider.dart';

class StakingHeader extends StatelessWidget {
  final bool isDark;
  final ThemeProvider themeProvider;
  final double dogeBalance;

  const StakingHeader({
    super.key,
    required this.isDark,
    required this.themeProvider,
    required this.dogeBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/Bank.png', height: 100, width: 100),
        const SizedBox(height: 15),
        Text(
          "Earn 8.5% APY on your DOGE",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? themeProvider.darkGreyBoxColor
                : Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
            border: isDark
                ? Border.all(
                    color: themeProvider.darkGreyBorder,
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.update,
                size: 20,
                color: isDark
                    ? Colors.amber
                    : Colors.green.shade800,
              ),
              const SizedBox(width: 5),
              Text(
                "Interest paid every second",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.amber
                      : Colors.green.shade800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 4.0,
              bottom: 8.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.amber.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Available Stakable Balance",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedHoverCard(
          backgroundColor: isDark
              ? themeProvider.darkGreyBoxColor
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.amber,
            width: 0.5,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 20,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${dogeBalance.toStringAsFixed(8)} DOGE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? Colors.amber : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              "⚠️ Note: Offerwall rewards cannot be staked.",
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
