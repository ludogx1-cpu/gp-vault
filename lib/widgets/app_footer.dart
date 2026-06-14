import '../screens/contact_page.dart';
import '../screens/faq_page.dart';
import '../screens/cookie_policy_page.dart';
import '../screens/privacy_policy_page.dart';
import '../screens/terms_of_service_page.dart';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../src/theme_provider.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  void _showDonateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Support Golden Paw 🐾",
          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Your donations help keep the faucet filled and rewards high for the whole community!",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "Our Dogecoin (DOGE) Address:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const SelectableText(
                "DDcrrGX7SzzdExq3pFo7fayrWfuvrPgX9d",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "(Long press to copy address)",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 12.0),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.amber.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: const Text(
                  "GOLDEN PAW DOGE",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.amber,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: themeProvider,
                builder: (context, child) => IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Colors.amber,
                    size: 20,
                  ),
                  tooltip: "Toggle Dark/Light Mode",
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServicePage(),
                  ),
                ),
                child: const Text(
                  "Terms of Service",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                ),
                child: const Text(
                  "Privacy Policy",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CookiePolicyPage(),
                  ),
                ),
                child: const Text(
                  "Cookie Policy",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FAQPage()),
                ),
                child: const Text(
                  "FAQ",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactPage()),
                ),
                child: const Text(
                  "Contact / Help Desk",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final Uri url = Uri.parse('https://www.trustpilot.com/review/goldenpaw.dog');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: const Text(
                  "Trustpilot Reviews",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.discord, color: Colors.indigo),
                onPressed: () {
                  web.window.open('https://discord.com', '_blank');
                },
                tooltip: 'Join our Discord',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () {
                  web.window.open('https://twitter.com', '_blank');
                },
                tooltip: 'Follow us on X',
              ),
              IconButton(
                icon: const Icon(Icons.facebook, color: Colors.blue),
                onPressed: () {
                  web.window.open('https://facebook.com', '_blank');
                },
                tooltip: 'Follow us on Facebook',
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.pink),
                onPressed: () {
                  web.window.open('https://instagram.com', '_blank');
                },
                tooltip: 'Follow us on Instagram',
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = constraints.maxWidth > 300
                  ? 280.0
                  : constraints.maxWidth * 0.92;
              final fontSize = buttonWidth < 200 ? 12.0 : 13.0;
              return Center(
                child: SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDonateDialog(context),
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "SUPPORT THE PROJECT (DONATE)",
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.brown,
                      side: const BorderSide(color: Colors.brown, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Container(height: 1, width: 250, color: Colors.amber.shade700),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "© 2026 Golden Paw. All rights reserved.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              SizedBox(height: 4),
              Text(
                "Made with ❤️ by Luke in England, UK",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "In loving memory of Butch the Pug & Jack the Jack",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.amber.shade200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
