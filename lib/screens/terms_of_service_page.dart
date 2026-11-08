import 'package:flutter/material.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListenableBuilder(
              listenable: themeProvider,
              builder: (context, _) {
                final isDark = themeProvider.isDarkMode;
                final titleColor = isDark ? Colors.white : Colors.black87;
                final textColor = isDark ? Colors.white : Colors.black87;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Terms of Service",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "1. User Conduct & Fair Play\nUsers are permitted strictly ONE account per person. The use of automated claiming scripts, bots, VPNs, or VPS services is strictly prohibited.\n\n"
                      "2. Age\nGolden Paw is only for people aged 18 and over. By using Golden Paw you confirm you are 18 or older.\n\n"
                      "3. Entertainment, Not Investment\nGolden Paw is a game. Rewards are small, are not guaranteed, and are not a way to make money. Golden Paw is not a bank, does not take deposits, is not an investment product and is not authorised or regulated by the Financial Conduct Authority (FCA). Nothing in Golden Paw is financial advice. The value of Dogecoin can go down as well as up.\n\n"
                      "4. Rewards, Bonus Vault and Withdrawals\nRewards are collected by playing and are recorded in your Vault balance until you withdraw them to your own FaucetPay account. The Bonus Vault is a game feature: you can only add DOGE you collected by playing, and the bonus is not interest. We may change reward amounts, bonus rates or features, or end them, at any time. We do not store DOGE for players beyond rewards awaiting withdrawal, and you should withdraw your rewards regularly.\n\n"
                      "5. Leaderboards\nLeaderboards only show real players. Weekly prizes go to the top real players.\n\n"
                      "6. Advertising Network\nFunds deposited into the Advertising Balance are strictly for the purchase of on-site ad campaigns. All ad purchases are final and non-refundable.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: textColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}



