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

class PersistentSidebar extends StatefulWidget {
  const PersistentSidebar({super.key});

  @override
  State<PersistentSidebar> createState() => _PersistentSidebarState();
}

class _PersistentSidebarState extends State<PersistentSidebar> {
  bool _isExpanded = false;

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final Color iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color titleColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            if (_isExpanded) ...[
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _isExpanded ? 240 : 60,
      decoration: BoxDecoration(
        color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with toggle button
          Container(
            height: 60,
            alignment: _isExpanded ? Alignment.centerRight : Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 8 : 0),
            child: IconButton(
              icon: const Icon(Icons.menu),
              color: isDark ? Colors.white : Colors.black87,
              onPressed: _toggleSidebar,
              tooltip: 'Toggle Menu',
            ),
          ),
          Divider(
            color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
            height: 1,
          ),
          // Scrollable Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.mouse,
                  title: 'Earn DOGE (PTC)',
                  isDark: isDark,
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
                  icon: Icons.install_mobile,
                  title: 'Install App to Device',
                  isDark: isDark,
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
                  icon: Icons.pets,
                  title: 'Dogeogotcha Guide',
                  isDark: isDark,
                  onTap: () => _navigateTo(const DogeogotchaInstructionsPage()),
                ),
                _buildNavItem(
                  icon: Icons.leaderboard,
                  title: 'Weekly Leaderboard',
                  isDark: isDark,
                  onTap: () => _navigateTo(const LeaderboardPage()),
                ),
                _buildNavItem(
                  icon: Icons.group_add,
                  title: 'Referral Program',
                  isDark: isDark,
                  onTap: () => _navigateTo(const ReferralPage()),
                ),
                _buildNavItem(
                  icon: Icons.campaign,
                  title: 'Buy Ads / PTC',
                  isDark: isDark,
                  onTap: () => _navigateTo(const AdHubPage()),
                ),
                _buildNavItem(
                  icon: Icons.link,
                  title: 'Bonus Partners',
                  isDark: isDark,
                  onTap: () => _navigateTo(const AffiliateLinksPage()),
                ),
                _buildNavItem(
                  icon: Icons.star,
                  title: 'Daily Promo',
                  isDark: isDark,
                  onTap: () => _navigateTo(const PromoCodePage()),
                ),
                _buildNavItem(
                  icon: Icons.assignment_turned_in,
                  title: 'Offerwalls',
                  isDark: isDark,
                  onTap: () => _navigateTo(const OfferwallHubPage()),
                ),
                _buildNavItem(
                  icon: Icons.lightbulb,
                  title: 'Suggestion Box',
                  isDark: isDark,
                  onTap: () => _navigateTo(const SuggestionBoxPage()),
                ),
                _buildNavItem(
                  icon: Icons.article,
                  title: 'Blog',
                  isDark: isDark,
                  onTap: () => _navigateTo(const BlogPage()),
                ),
                
                if (isAdmin) ...[
                  Divider(color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300),
                  _buildNavItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Dashboard',
                    isDark: isDark,
                    onTap: () => _navigateTo(const AdminDashboardPage()),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
