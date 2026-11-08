import 'package:flutter/material.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});
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
                final titleColor = isDark ? Colors.amber : Colors.amber.shade700;
                final textColor = isDark ? Colors.white70 : Colors.black87;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Frequently Asked Questions",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ExpansionTile(
                        collapsedIconColor: titleColor,
                        iconColor: titleColor,
                        title: Text(
                          "What is Golden Paw?",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              "Golden Paw is a virtual pet game for adults (18+) with small Dogecoin rewards. You can collect rewards from the faucet or by viewing sponsored ads. Golden Paw is entertainment, not an investment, and rewards are not a way to make money. The value of DOGE goes up and down.",
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        collapsedIconColor: titleColor,
                        iconColor: titleColor,
                        title: Text(
                          "How do I withdraw my earnings?",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              "Once you reach the minimum withdrawal threshold of 1 DOGE in your Vault, you can navigate to your Profile, enter your FaucetPay Dogecoin address, and initiate an instant withdrawal.",
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        collapsedIconColor: titleColor,
                        iconColor: titleColor,
                        title: Text(
                          "Can I use a VPN or Proxy?",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              "Absolutely not. The use of VPNs, Proxies, Tor nodes, or automated claiming bots is strictly prohibited. Our security systems will automatically flag and permanently ban any accounts caught using these methods.",
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        collapsedIconColor: titleColor,
                        iconColor: titleColor,
                        title: Text(
                          "How does the Bonus Vault work?",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              "The Bonus Vault is a game feature. You can move DOGE you've collected from playing into it and a small bonus builds up over time. You can't deposit your own money into it. The bonus is not interest, is not guaranteed, and we may change or end it at any time.",
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}



