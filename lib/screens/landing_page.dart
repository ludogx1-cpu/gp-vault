import '../widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
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
      backgroundColor: Colors.transparent,
      appBar: GlobalAppBar(
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
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 728,
                height: 90,
                child: UniversalWebView.create(viewType: 'adsterra-728x90', width: 728, height: 90),
              ),
            ),
            const PwaInstallWidget(),
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
                        "Welcome to Golden Paw!\nThe Ultimate Dogecoin Ecosystem",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Arial Black',
                          fontSize: isMobile ? 28 : 40,
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
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, child) {
                      return Text(
                        "Claim free DOGE every 5 minutes, stake your earnings in the 8.5% APY Vault, and level up your virtual pet.\nStart growing your crypto portfolio today with zero investment required!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 20,
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
                FeatureCard(
                  icon: Icons.pets,
                  title: "Dogeogotcha",
                  desc:
                      "Raise your very own virtual Shiba Inu! Play, feed, and equip items to boost your faucet earnings by up to 150%.",
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 50),
            const TrustpilotWidget(),
            const SizedBox(height: 80),

            // --- YOUTUBE EMBED ---
            Container(
              width: isMobile ? double.infinity : 560,
              constraints: const BoxConstraints(maxWidth: 560),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    child: HtmlElementView(viewType: 'youtube-promo'),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
            const NewsletterSubscribeWidget(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

