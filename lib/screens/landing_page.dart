import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../src/theme_provider.dart';
import '../widgets/trustpilot_widget.dart';
import '../widgets/newsletter_subscribe_widget.dart';
import '../widgets/widgets.dart';
import 'blog_page.dart';
import '../widgets/universal_web_view/universal_web_view.dart';

class LandingPage extends StatefulWidget {
  final void Function(BuildContext, bool) onAuthTrigger;

  const LandingPage({super.key, required this.onAuthTrigger});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return AppScaffold(
      showSidebar: false,
      backgroundColor: Colors.transparent,
      appBar: GlobalAppBar(
        showMenuIcon: false,
        centerTitle: false,
        showWallet: false,
        actions: [
          // --- BLOG BUTTON ---
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BlogPage()),
              );
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
            ),
            child: Text(
              "BLOG",
              style: TextStyle(
                color: kTextColorOnBlack,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 13 : 16,
              ),
            ),
          ),

          // --- LOG IN BUTTON ---
          TextButton(
            onPressed: () => widget.onAuthTrigger(context, true),
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
                  onPressed: () => widget.onAuthTrigger(context, false),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    "SIGN UP",
                    style: TextStyle(
                      color: Colors.white,
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
                    onPressed: () => widget.onAuthTrigger(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "SIGN UP",
                      style: TextStyle(
                        color: Colors.white,
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
            if (kIsWeb) const SizedBox(height: 80), // Push ads below the app header
            if (kIsWeb)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 728,
                  height: 90,
                  child: UniversalWebView.create(viewType: 'adsterra-728x90', width: 728, height: 90),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                        "Golden Paw",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Arial Black',
                          fontSize: isMobile ? 36 : 48,
                          letterSpacing: -1.0,
                          fontWeight: FontWeight.w900,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87.withValues(alpha: 0.9),
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
                  const SizedBox(height: 10),
                  ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, child) {
                      return Text(
                        "The Ultimate Dogecoin Ecosystem",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Arial Black',
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, child) {
                      return Text(
                        "Golden Paw is a crypto-reward application designed to help you earn and grow Dogecoin. Our purpose is to provide a fun, zero-investment platform where users can claim free DOGE every 5 minutes, stake earnings in our 33% APY Vault, and raise a virtual pet.\n\nBy signing in with your Google account, you can securely save your balance, protect your progress, and access your account across all your devices.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          color: themeProvider.isDarkMode
                              ? Colors.white70
                              : Colors.black87,
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
                      onPressed: () => widget.onAuthTrigger(context, false),
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
                        : Colors.black87,
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
                      "Lock your Doge in The Vault and earn 33% APY interest, calculated every single second.",
                  color: Colors.green,
                ),
                FeatureCard(
                  icon: Icons.group_add,
                  title: "20% Referrals",
                  desc:
                      "Invite your friends and earn 20% of every claim they make, for life. Passive income simplified.",
                  color: Colors.purple,
                ),
                FeatureCard(
                  icon: Icons.pets,
                  title: "Dogeogotcha",
                  desc:
                      "Raise your very own virtual Shiba Inu! Play, feed, and equip items to boost your faucet earnings by up to 150%.",
                  color: Colors.orange,
                ),
              ],
            ),
            if (kIsWeb) const SizedBox(height: 50),
            if (kIsWeb) const Bitcotasks468x60AdWidget(),
            const SizedBox(height: 50),
            const TrustpilotWidget(),
            const SizedBox(height: 60),
            _buildAboutStudiosSection(context),
            if (kIsWeb) const SizedBox(height: 60),
            if (kIsWeb) const Bitcotasks300x600AdWidget(),
            const SizedBox(height: 60),
            const NewsletterSubscribeWidget(),
            const SizedBox(height: 50),
            const PwaInstallWidget(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutStudiosSection(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white70 : Colors.black87;
        final subtextColor = isDark ? Colors.white60 : Colors.black54;

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 880),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(isMobile ? 24 : 36),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141926) : Colors.amber.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.amber.withValues(alpha: 0.3) : Colors.amber.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: isDark ? 0.08 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  "✦ GOLDEN PAW STUDIOS ✦",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Our Vision & Community",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 30,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Golden Paw Studios is an independent game and app development studio with a passion for creating fun, rewarding, and easy-to-use mobile experiences.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 17,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Our flagship project, Golden Paw, brings together the joy of caring for a virtual pet with the opportunity to earn real Dogecoin through instant faucet rewards and automated crypto staking vaults.\n\nWe believe earning rewards should be simple, fair, and accessible to everyone. That's why we're focused on building experiences that don't require an upfront investment, put transparency first, and make Web3 more approachable.\n\nAt Golden Paw Studios, it's all about combining entertainment, real rewards, and a growing community of players who share our vision.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: subtextColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 4,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://goldenpaw.dog/studios'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.public, size: 18),
                    label: const Text(
                      "Visit Studios Website ↗",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://x.com/ludogx101'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("X (@ludogx101)"),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.instagram.com/goldenpawdoge'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          center: Alignment(-0.8, 0.8),
                          radius: 1.2,
                          colors: [
                            Color(0xFFFFDC80),
                            Color(0xFFF77737),
                            Color(0xFFFD1D1D),
                            Color(0xFFE1306C),
                            Color(0xFF833AB4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt, size: 12, color: Colors.white),
                      ),
                    ),
                    label: const Text("Instagram"),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.tiktok.com/@goldenpawstudios'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.tiktok, size: 16),
                    label: const Text("TikTok"),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.facebook.com/GoldenPawDogeHub'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.facebook, size: 16, color: Colors.blue),
                    label: const Text("Facebook"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

