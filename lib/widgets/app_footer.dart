import '../screens/contact_page.dart';
import '../screens/faq_page.dart';
import '../screens/cookie_policy_page.dart';
import '../screens/blog_page.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../src/theme_provider.dart';
import 'universal_web_view/universal_web_view.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

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
          const SizedBox(height: 20),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BlogPage()),
                ),
                child: const Text(
                  "Blog",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/terms'),
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
                onPressed: () => context.push('/privacy'),
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
                  final Uri url = Uri.parse(
                    'https://www.trustpilot.com/review/goldenpaw.dog',
                  );
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
              TextButton(
                onPressed: () async {
                  final Uri url = Uri.parse(
                    'https://www.patreon.com/cw/goldenpawhub',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: const Text(
                  "Support us on Patreon",
                  style: TextStyle(
                    color: Color(0xFFFF424D),
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
                  launchUrl(Uri.parse('https://discord.com'));
                },
                tooltip: 'Join our Discord',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () {
                  launchUrl(Uri.parse('https://x.com/ludogx101'));
                },
                tooltip: 'Follow us on X',
              ),
              IconButton(
                icon: const Icon(Icons.facebook, color: Colors.blue),
                onPressed: () {
                  launchUrl(
                    Uri.parse('https://www.facebook.com/GoldenPawDogeHub'),
                  );
                },
                tooltip: 'Follow us on Facebook',
              ),
              IconButton(
                icon: const Icon(Icons.tiktok, color: Colors.white),
                onPressed: () {
                  launchUrl(Uri.parse('https://www.tiktok.com/@ludogx1'));
                },
                tooltip: 'Follow us on TikTok',
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SizedBox(
                  width: 114,
                  height: 32,
                  child: UniversalWebView.create(
                    viewType: 'github-sponsors-iframe',
                    width: 114,
                    height: 32,
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
              const PulsatingSecurityText(),
              const SizedBox(height: 12),
              const Text(
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

class PulsatingSecurityText extends StatefulWidget {
  const PulsatingSecurityText({super.key});

  @override
  State<PulsatingSecurityText> createState() => _PulsatingSecurityTextState();
}

class _PulsatingSecurityTextState extends State<PulsatingSecurityText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 14,
              color: Colors.greenAccent.withValues(alpha: 0.5 + (0.5 * value)),
              shadows: [
                Shadow(
                  color: Colors.greenAccent.withValues(alpha: 0.8 * value),
                  blurRadius: 10 * value,
                ),
              ],
            ),
            const SizedBox(width: 6),
            Text(
              '256-Bit SSL Encryption • Secured by Cloudflare',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.greenAccent.withValues(
                  alpha: 0.7 + (0.3 * value),
                ),
                shadows: [
                  Shadow(
                    color: Colors.greenAccent.withValues(alpha: 0.6 * value),
                    blurRadius: 8 * value,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
