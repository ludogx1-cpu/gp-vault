import '../api_constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/theme_provider.dart';
import 'package:flutter/foundation.dart';
import '../src/pwa_interop.dart' if (dart.library.html) '../src/pwa_interop_web.dart';
import 'package:go_router/go_router.dart';

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

  void _navigateTo(BuildContext context, String path) {
    if (MediaQuery.of(context).size.width < 600) {
      sidebarExpandedNotifier.value = false;
    }
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isAdmin = user != null && user.uid == ApiConstants.adminUid;
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
                        context.go('/ptc');
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
                            bool canPrompt = canInstallPwa();
                            if (canPrompt) {
                              triggerPwaInstall();
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
                      onTap: () => _navigateTo(context, '/guide'),
                    ),
                    SidebarNavItem(
                      icon: Icons.leaderboard,
                      title: 'Weekly Leaderboard',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, '/leaderboard'),
                    ),
                    SidebarNavItem(
                      icon: Icons.group_add,
                      title: 'Referral Program',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, '/referral'),
                    ),
                    SidebarNavItem(
                      icon: Icons.campaign,
                      title: 'Buy Ads / PTC',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, '/ads'),
                    ),
                    SidebarNavItem(
                      icon: Icons.link,
                      title: 'Bonus Partners',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, '/bonus-partners'),
                    ),
                    SidebarNavItem(
                      icon: Icons.star,
                      title: 'Daily Promo',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, '/promo'),
                    ),
                    SidebarNavItem(
                      icon: Icons.assignment_turned_in,
                      title: 'Offerwalls',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, '/offerwalls'),
                    ),
                    SidebarNavItem(
                      icon: Icons.lightbulb,
                      title: 'Suggestion Box',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, '/suggestions'),
                    ),
                    SidebarNavItem(
                      icon: Icons.article,
                      title: 'Blog',
                      isDark: isDark,
                      isExpanded: isExpanded,
                      onTap: () => _navigateTo(context, '/blog'),
                    ),
                    
                    if (isAdmin) ...[
                      Divider(color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300),
                      SidebarNavItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Dashboard',
                        isDark: isDark,
                        isExpanded: isExpanded,
                        onTap: () => _navigateTo(context, '/admin'),
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
