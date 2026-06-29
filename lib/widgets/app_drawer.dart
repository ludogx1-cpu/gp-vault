import 'package:provider/provider.dart';
import '../src/user_provider.dart';
import '../screens/admin_dashboard_page.dart';
import '../screens/offerwall_hub_page.dart';
import '../screens/affiliate_links_page.dart';
import '../screens/ad_hub_page.dart';
import '../screens/referral_page.dart';
import '../screens/ptc_earn_page.dart';
import '../screens/dogeogotcha_instructions_page.dart';
import '../screens/suggestion_box_page.dart';
import '../screens/blog_page.dart';
import 'platform_indicator_level_text.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/theme_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // 🔒 HARDCODED ADMIN SECURITY CHECK
    final bool isAdmin = user != null && user.email == 'ludogx1@gmail.com';

    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        final Color titleColor = isDark ? Colors.white : Colors.black87;
        final Color subColor = isDark ? Colors.white70 : Colors.black87;
        final Color dividerColor = isDark
            ? themeProvider.darkGreyBorder
            : Colors.grey.shade300;

        return Drawer(
          backgroundColor: isDark
              ? themeProvider.darkGreyBoxColor
              : Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                // 👑 Softened the black to a deep charcoal (grey.shade900)
                decoration: BoxDecoration(color: Colors.grey.shade900),
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, authSnapshot) {
                    if (authSnapshot.hasData && authSnapshot.data != null) {
                      return Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          final data = userProvider.userData;
                          int xp = (data?['xp'] ?? 0).toInt();
                          int streak = (data?['streak_count'] ?? 0).toInt();

                          int level = sqrt(xp / 100).floor();
                          if (level > 100) level = 100;
                          int currentLevelXp = 100 * (level * level);
                          int nextLevelXp = level >= 100
                              ? currentLevelXp
                              : 100 * ((level + 1) * (level + 1));
                          double progress = level >= 100
                              ? 1.0
                              : (xp - currentLevelXp) /
                                    (nextLevelXp - currentLevelXp);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.amber,
                                    radius: 25,
                                    child: Text(
                                      level.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Golden Paw Rank",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department,
                                              color: Colors.deepOrange,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              "$streak Day Streak",
                                              style: const TextStyle(
                                                color: Colors.deepOrange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white24,
                                color: Colors.green.shade500,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              const SizedBox(height: 5),
                              PlatformIndicatorLevelText(
                                level: level,
                                xp: xp,
                                currentLevelXp: currentLevelXp,
                                nextLevelXp: nextLevelXp,
                              ),
                            ],
                          );
                        },
                      );
                    }

                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.pets, size: 50, color: Colors.amber),
                        SizedBox(height: 10),
                        Text(
                          "Golden Paw Menu",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Guest User - Log in to Level Up!",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mouse, color: Colors.green),
                title: Text(
                  'Earn DOGE (PTC)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Click ads to earn crypto',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const PtcEarnPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 0.05); // slight slide up
                        const end = Offset.zero;
                        const curve = Curves.easeOutCubic;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.pets, color: Colors.amber),
                title: Text(
                  'Dogeogotcha Guide',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'How to play & earn',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DogeogotchaInstructionsPage(),
                    ),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.group_add, color: Colors.purple),
                title: Text(
                  'Referral Program',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Earn 20% of friend claims',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReferralPage(),
                    ),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.campaign, color: Colors.blue),
                title: Text(
                  'Buy Ads / PTC',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Advertise your links here',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdHubPage()),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.green),
                title: Text(
                  'Bonus Partners',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Earn more crypto',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AffiliateLinksPage(),
                    ),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(
                  Icons.assignment_turned_in,
                  color: Colors.deepPurple,
                ),
                title: Text(
                  'Offerwalls',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Complete tasks to earn DOGE',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OfferwallHubPage(),
                    ),
                  );
                },
              ),

              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.lightbulb, color: Colors.yellow),
                title: Text(
                  'Suggestion Box',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Share your ideas!',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuggestionBoxPage(),
                    ),
                  );
                },
              ),

              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.article, color: Colors.teal),
                title: Text(
                  'Blog',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Read our latest posts',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlogPage(),
                    ),
                  );
                },
              ),

              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.orange),
                title: Text(
                  'VIP Premium',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  'Coming Soon...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white30 : Colors.grey,
                  ),
                ),
                onTap: () {},
              ),

              if (isAdmin) ...[
                const Divider(color: Colors.red, thickness: 2),
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: const Text(
                    'Boss Mode Activated',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardPage(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
