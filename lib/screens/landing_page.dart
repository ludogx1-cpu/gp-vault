import '../widgets/page_with_footer.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/feature_card.dart';
import '../src/theme_provider.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  final void Function(BuildContext, bool) onAuthTrigger;

  const LandingPage({super.key, required this.onAuthTrigger});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlobalAppBar(
        centerTitle: false,
        showWallet: false,
        actions: [
          // --- LOG IN BUTTON ---
          TextButton(
            onPressed: () => onAuthTrigger(context, true),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
            ),
            child: Text(
              "LOG IN",
              style: TextStyle(
                color: kTextColorOnBlack,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 13 : 16,
              ),
            ),
          ),

          // --- SIGN UP BUTTON ---
          isMobile
              ? TextButton(
                  onPressed: () => onAuthTrigger(context, false),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    "SIGN UP",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ElevatedButton(
                    onPressed: () => onAuthTrigger(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "SIGN UP",
                      style: TextStyle(
                        color: Colors.brown,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: PageWithFooter(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/logo_landing.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 25),
                  ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, child) {
                      return Text(
                        "The Smartest Way to\nEarn Dogecoin",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Arial Black',
                          fontSize: isMobile ? 26 : 33,
                          letterSpacing: -1.0,
                          fontWeight: FontWeight.w900,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.brown.shade900.withValues(alpha: 0.9),
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: themeProvider.isDarkMode
                                  ? Colors.black
                                  : Colors.white.withValues(alpha: 0.9),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, child) {
                      return Text(
                        "Claim free DOGE every 5 minutes, earn 8.5% interest in The Vault,\nand grow your wealth with our automated ecosystem.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 18,
                          color: themeProvider.isDarkMode
                              ? Colors.white70
                              : Colors.brown.shade800,
                          height: 1.5,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: themeProvider.isDarkMode
                                  ? Colors.black
                                  : Colors.white.withValues(alpha: 0.9),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 250,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => onAuthTrigger(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        shadowColor: Colors.amber.withValues(alpha: 0.5),
                      ),
                      child: const Text(
                        "CREATE FREE ACCOUNT",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ListenableBuilder(
              listenable: themeProvider,
              builder: (context, child) {
                return Text(
                  "How it Works",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.brown,
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 30,
              runSpacing: 30,
              children: [
                FeatureCard(
                  icon: Icons.water_drop,
                  title: "Instant Faucet",
                  desc:
                      "Visit every 5 minutes to claim free Dogecoin. No hidden limits, just pure rewards.",
                  color: Colors.blue,
                ),
                FeatureCard(
                  icon: Icons.bolt,
                  title: "The Vault Staking",
                  desc:
                      "Lock your Doge in The Vault and earn 8.5% APY interest, calculated every single second.",
                  color: Colors.green,
                ),
                FeatureCard(
                  icon: Icons.group_add,
                  title: "20% Referrals",
                  desc:
                      "Invite your friends and earn 20% of every claim they make, for life. Passive income simplified.",
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
