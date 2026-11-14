import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';

/// The full policy lives at goldenpaw.dog/privacy/ so the website, the app and
/// the Chrome extension all point to one document.
const String fullPrivacyPolicyUrl = 'https://goldenpaw.dog/privacy/';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicySummaryPage(
      title: "Privacy Policy",
      summary:
          "Golden Paw is only for people aged 18 and over.\n\n"
          "• We collect your email (and name and photo if you use Google sign-in) to run your account.\n"
          "• We keep your balances, pet and reward history, and your payout address so we can pay your rewards.\n"
          "• Captchas from Cloudflare, hCaptcha and Google check that claims are made by people, not bots.\n"
          "• Analytics and advertising cookies are only used on the website if you agree to them in the cookie banner.\n"
          "• Pet walks use your location on your phone only. We just receive the distance walked.\n"
          "• We never sell your personal data.\n\n"
          "You can ask to see, correct or delete your data at any time by emailing goldenpaw.dogeadmin@gmail.com.",
    );
  }
}

/// Shared layout for the in-app policy pages: a short summary plus a button
/// that opens the full policy.
class PolicySummaryPage extends StatelessWidget {
  final String title;
  final String summary;
  final String buttonLabel;
  final String url;

  const PolicySummaryPage({
    super.key,
    required this.title,
    required this.summary,
    this.buttonLabel = "Read the full Privacy Policy",
    this.url = fullPrivacyPolicyUrl,
  });

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
                final textColor = isDark ? Colors.white : Colors.black87;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      summary,
                      style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(buttonLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
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
