import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

/// Read-only view of a player's offerwall and Doge Bank balances.
/// The Bank no longer accepts deposits or transfers (Golden Paw does not
/// store DOGE for players), and both balances wait for offerwall payouts
/// to reopen.
class AccountBankCard extends StatelessWidget {
  final bool isDark;
  final double bankBalance;
  final double vaultBalance;
  final double offerwallBalance;

  const AccountBankCard({
    super.key,
    required this.isDark,
    required this.bankBalance,
    required this.vaultBalance,
    required this.offerwallBalance,
  });

  Widget _balanceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "${amount.toStringAsFixed(6)} DOGE",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      backgroundColor: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.amber, width: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
                ),
                const SizedBox(width: 10),
                Text(
                  "Offerwall Rewards",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _balanceRow("Offerwall Balance:", offerwallBalance),
            if (bankBalance > 0) _balanceRow("Doge Bank Balance:", bankBalance),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white60,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Offerwall withdrawals are temporarily paused until our offerwall partner payouts are set up. "
                      "Your balances stay recorded. The Doge Bank no longer accepts deposits or transfers; "
                      "any Bank balance will be paid out alongside offerwall rewards. Check the updates board for news.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
