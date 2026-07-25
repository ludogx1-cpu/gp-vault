import 'package:flutter/material.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';

// --- GLOBAL THEME CONSTANTS 🚀 ---

// --- CAPTCHA JS BINDINGS ---

// ==========================================
// 1. THE SHELL
// ==========================================

class CookiePolicyPage extends StatelessWidget {
  const CookiePolicyPage({super.key});
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
                      "Cookie Policy",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Last Updated: May 2026\n\nGolden Paw uses minimal cookies and local storage to ensure the basic functionality and security of our platform.\n\n"
                      "1. Essential Storage\nWe use secure local browser storage to remember your FaucetPay address and maintain your login session.\n\n"
                      "2. Security Cookies\nOur anti-bot providers (Cloudflare Turnstile and hCaptcha) may place temporary session cookies on your device to verify that you are a human.",
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

