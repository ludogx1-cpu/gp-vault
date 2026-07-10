import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../src/theme_provider.dart';
import '../src/user_provider.dart';

class WalletDropdownButton extends StatelessWidget {
  const WalletDropdownButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: Icon(Icons.account_balance_wallet, color: Colors.grey),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final data = userProvider.userData;
        final double mainBal = (data?['doge_balance'] ?? 0.0).toDouble();
        final double offerwallBal = (data?['offerwall_balance'] ?? 0.0).toDouble();
        final double bankBal = (data?['bank_balance'] ?? 0.0).toDouble();

        return Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_balance_wallet,
              color: kAppBarIconColor,
              size: 28,
            ),
            tooltip: "View Balances",
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            offset: const Offset(0, 50),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Main Wallet",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Faucet & Staking rewards — stakable",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.monetization_on,
                            color: Colors.amber.shade800,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${mainBal.toStringAsFixed(6)} DOGE",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Offerwall Wallet",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Task rewards — withdrawable only",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.assignment_turned_in,
                            color: Colors.purple.shade800,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${offerwallBal.toStringAsFixed(6)} DOGE",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Doge Bank Wallet",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Storage only — no staking",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: Colors.blue.shade800,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${bankBal.toStringAsFixed(6)} DOGE",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
    );
  }
}
