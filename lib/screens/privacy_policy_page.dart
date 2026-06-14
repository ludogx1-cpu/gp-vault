import 'package:flutter/material.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListenableBuilder(
              listenable: themeProvider,
              builder: (context, _) {
                final isDark = themeProvider.isDarkMode;
                final titleColor = isDark ? Colors.white : Colors.brown;
                final textColor = isDark ? Colors.white : Colors.black87;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Privacy Policy",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "1. Data We Collect\nWhen you register, we collect your email address. When you withdraw, we collect your FaucetPay linked Dogecoin address.\n\n"
                      "2. Third-Party Services\nWe utilize Google Firebase for secure authentication and database management. We use Cloudflare and hCaptcha for bot mitigation.",
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


