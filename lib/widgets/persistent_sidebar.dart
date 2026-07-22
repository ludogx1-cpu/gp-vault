import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:js_interop';
import '../screens/admin_dashboard_page.dart';
import '../screens/offerwall_hub_page.dart';
import '../screens/affiliate_links_page.dart';
import '../screens/ad_hub_page.dart';
import '../screens/referral_page.dart';
import '../screens/ptc_earn_page.dart';
import '../screens/dogeogotcha_instructions_page.dart';
import '../screens/leaderboard_page.dart';
import '../screens/suggestion_box_page.dart';
import '../screens/blog_page.dart';
import '../screens/promo_code_page.dart';

@JS('canInstallPwa')
external JSBoolean _canInstallPwaJS();

@JS('triggerPwaInstall')
external void _triggerPwaInstallJS();

final ValueNotifier<bool> sidebarExpandedNotifier = ValueNotifier(false);

class PersistentSidebar extends StatelessWidget {
  const PersistentSidebar({super.key});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    required bool isExpanded,
  }) {
    final Color iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color titleColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            if (isExpanded) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isAdmin = user != null && user.email == 'ludogx1@gmail.com';
    final isDark = themeProvider.isDarkMode;
    
    // Header/Footer black color
    final Color sidebarColor = isDark ? Colors.black : Colors.white;

    return ValueListenableBuilder<bool>(
      valueListenable: sidebarExpandedNotifier,
      builder: (context, isExpanded, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isExpanded ? 242 : 62,
          decoration: BoxDecoration(
            color: sidebarColor,
            border: Border(
              right: BorderSide(
                color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Scrollable Nav Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.mouse,
                      title: 'Earn DOGE (PTC)',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const PtcEarnPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(0.0, 0.05);
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
                    _buildNavItem(
                      context,
                      icon: Icons.install_mobile,
                      title: 'Install App to Device',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () {
                        if (kIsWeb) {
                          try {
                            bool canPrompt = _canInstallPwaJS().toDart;
                            if (canPrompt) {
                              _triggerPwaInstallJS();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("To install: tap your browser menu (⋮ or Share) and select 'Add to Home screen' or 'Install App'!"),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("To install: tap your browser menu (⋮ or Share) and select 'Add to Home screen' or 'Install App'!"),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.pets,
                      title: 'Dogeogotcha Guide',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const DogeogotchaInstructionsPage()),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.leaderboard,
                      title: 'Weekly Leaderboard',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const LeaderboardPage()),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.group_add,
                      title: 'Referral Program',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const ReferralPage()),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.campaign,
                      title: 'Buy Ads / PTC',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const AdHubPage()),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.link,
                      title: 'Bonus Partners',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const AffiliateLinksPage()),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.star,
                      title: 'Daily Promo',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const PromoCodePage()),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.assignment_turned_in,
                      title: 'Offerwalls',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const OfferwallHubPage()),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.lightbulb,
                      title: 'Suggestion Box',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const SuggestionBoxPage()),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.article,
                      title: 'Blog',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const BlogPage()),
                    ),
                    
                    if (isAdmin) ...[
                      Divider(color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300),
                      _buildNavItem(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Dashboard',
                        isDark: isDark,
                        isExpanded: isExpanded,
                        onTap: () => _navigateTo(context, const AdminDashboardPage()),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
