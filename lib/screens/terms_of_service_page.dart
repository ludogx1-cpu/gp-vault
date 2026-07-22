import '../widgets/app_scaffold.dart';
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
                      "2. Earnings and Withdrawals\nBalances held within the Vault hold no real-world fiat value until successfully withdrawn to a third-party wallet.\n\n"
                      "3. Advertising Network\nFunds deposited into the Advertising Balance are strictly for the purchase of on-site ad campaigns. All ad purchases are final and non-refundable.",
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



