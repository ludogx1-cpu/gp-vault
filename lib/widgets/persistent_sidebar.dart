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

class SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool isExpanded;
  
  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    required this.isExpanded,
  });

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color defaultIconColor = widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color activeIconColor = Colors.amber;
    final Color titleColor = widget.isDark ? Colors.white : Colors.black87;
    
    final bool isActive = _isHovered || _isPressed;
    final Color currentIconColor = isActive ? activeIconColor : defaultIconColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onHover: (hovering) => setState(() => _isHovered = hovering),
        splashColor: Colors.amber.withValues(alpha: 0.2),
        highlightColor: Colors.amber.withValues(alpha: 0.1),
        hoverColor: Colors.transparent, // Let the icon color change handle hover
        child: Container(
          height: 55, // Increased size
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.icon, 
                  key: ValueKey(isActive),
                  color: currentIconColor, 
                  size: 31, // Increased size
                ),
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.title,
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
      ),
    );
  }
}

class PersistentSidebar extends StatelessWidget {
  const PersistentSidebar({super.key});

  void _navigateTo(BuildContext context, Widget page) {
    if (MediaQuery.of(context).size.width < 600) {
      sidebarExpandedNotifier.value = false;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isAdmin = user != null && user.uid == 'P8iffVqbUgetAVA4MdHVZ1CfvUv1';
    final isDark = themeProvider.isDarkMode;
    
    // Header/Footer black color
    final Color sidebarColor = isDark ? Colors.black : Colors.white;

    return ValueListenableBuilder<bool>(
      valueListenable: sidebarExpandedNotifier,
      builder: (context, isExpanded, child) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final targetWidth = isMobile ? (isExpanded ? 242.0 : 0.0) : (isExpanded ? 242.0 : 62.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: targetWidth,
          decoration: BoxDecoration(
            color: sidebarColor,
            border: Border(
              right: BorderSide(
                color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: ClipRect(
            child: OverflowBox(
              minWidth: 0,
              maxWidth: 242,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: isExpanded ? 242 : 62,
                child: Column(
                  children: [
              // Scrollable Nav Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    SidebarNavItem(
                      icon: Icons.mouse,
                      title: 'Earn DOGE (PTC)',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () {
                        if (MediaQuery.of(context).size.width < 600) {
                          sidebarExpandedNotifier.value = false;
                        }
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
                    SidebarNavItem(
                      icon: Icons.install_mobile,
                      title: 'Install App to Device',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () {
                        if (MediaQuery.of(context).size.width < 600) {
                          sidebarExpandedNotifier.value = false;
                        }
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
                    SidebarNavItem(
                      icon: Icons.pets,
                      title: 'Dogeogotcha Guide',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const DogeogotchaInstructionsPage()),
                    ),
                    SidebarNavItem(
                      icon: Icons.leaderboard,
                      title: 'Weekly Leaderboard',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const LeaderboardPage()),
                    ),
                    SidebarNavItem(
                      icon: Icons.group_add,
                      title: 'Referral Program',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const ReferralPage()),
                    ),
                    SidebarNavItem(
                      icon: Icons.campaign,
                      title: 'Buy Ads / PTC',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const AdHubPage()),
                    ),
                    SidebarNavItem(
                      icon: Icons.link,
                      title: 'Bonus Partners',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const AffiliateLinksPage()),
                    ),
                    SidebarNavItem(
                      icon: Icons.star,
                      title: 'Daily Promo',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const PromoCodePage()),
                    ),
                    SidebarNavItem(
                      icon: Icons.assignment_turned_in,
                      title: 'Offerwalls',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const OfferwallHubPage()),
                    ),
                    SidebarNavItem(
                      icon: Icons.lightbulb,
                      title: 'Suggestion Box',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const SuggestionBoxPage()),
                    ),
                    SidebarNavItem(
                      icon: Icons.article,
                      title: 'Blog',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, const BlogPage()),
                    ),
                    
                    if (isAdmin) ...[
                      Divider(color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300),
                      SidebarNavItem(
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
              ),
            ),
          ),
        );
      },
    );
  }
}
