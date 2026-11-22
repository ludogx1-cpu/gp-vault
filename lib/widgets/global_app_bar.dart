import 'wallet_dropdown_button.dart';
import 'live_referral_tracker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../src/theme_provider.dart';
import 'persistent_sidebar.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackArrow;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showWallet;
  final bool showMenuIcon;

  const GlobalAppBar({
    super.key,
    this.showBackArrow = false,
    this.actions,
    this.centerTitle = false,
    this.showWallet = true,
    this.showMenuIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final Color chrome = gpChromeColor(context);
    final Color gold = gpChromeGold(context);
    final String? sectionLabel = sectionForPath(_currentPath(context));

    return Container(
      color: chrome,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LiveReferralTracker(),
            AppBar(
              primary: false,
              toolbarHeight: 70,
              backgroundColor: chrome,
              surfaceTintColor: Colors.transparent,
              elevation: 10,
              shadowColor: themeProvider.isDarkMode
                  ? Colors.black45
                  : Colors.black26,
              centerTitle: isMobile ? false : centerTitle,
              iconTheme: IconThemeData(color: gold),
              titleSpacing: showBackArrow ? 0 : 16,
              automaticallyImplyLeading: false,
              leading: showBackArrow
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    )
                  : showMenuIcon
                  ? IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        sidebarExpandedNotifier.value =
                            !sidebarExpandedNotifier.value;
                      },
                    )
                  : const SizedBox.shrink(),
              leadingWidth: (showBackArrow || showMenuIcon) ? 56.0 : 0.0,
              title: InkWell(
                onTap: () => context.go('/'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/paw_logo_gold.png',
                      height: isMobile ? 34 : 40,
                      fit: BoxFit.contain,
                      semanticLabel: 'Golden Paw',
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _TitleWithSection(
                        isMobile: isMobile,
                        section: sectionLabel,
                        gold: gold,
                        title: ShaderMask(
                          // Solid brand gold (no shine), matching the paw logo.
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [gold, gold],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: Text(
                            'Golden Paw',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Outfit',
                              fontSize: isMobile ? 24 : 28,
                              fontWeight: FontWeight.w700,
                              fontVariations: const [
                                FontVariation('wght', 700),
                              ],
                              letterSpacing: 3.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ...?actions,
                // Dark / light mode switch (moved here from the footer).
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: gold,
                  ),
                  tooltip: themeProvider.isDarkMode
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  onPressed: themeProvider.toggleTheme,
                ),
                if (showWallet)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: WalletDropdownButton(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(140);
}

String _currentPath(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } catch (_) {
    return '';
  }
}

/// The small word shown next to "Golden Paw" for each part of the app,
/// like a "you are here" sign. Null on the home page.
String? sectionForPath(String path) {
  const sections = <String, String>{
    '/faucet': 'Faucet',
    '/book-of-dog': 'Book Of Dog',
    '/staking': 'Bonus Vault',
    '/account': 'Account',
    '/walk-pet': 'Walk',
    '/admin': 'Admin',
    '/offerwalls': 'Offerwalls',
    '/bonus-partners': 'Bonus Partners',
    '/ads': 'Ads',
    '/referral': 'Referrals',
    '/ptc': 'Earn',
    '/guide': 'Guide',
    '/leaderboard': 'Leaderboard',
    '/suggestions': 'Suggestions',
    '/blog': 'Blog',
    '/promo': 'Daily Promo',
    '/privacy': 'Privacy',
    '/terms': 'Terms',
    '/reward-history': 'Rewards',
  };
  for (final e in sections.entries) {
    if (path == e.key || path.startsWith('${e.key}/')) return e.value;
  }
  return null;
}

/// "Golden Paw" with the section name: beside it on wide screens (with a
/// small dot between), underneath it on phones.
class _TitleWithSection extends StatelessWidget {
  final bool isMobile;
  final String? section;
  final Color gold;
  final Widget title;

  const _TitleWithSection({
    required this.isMobile,
    required this.section,
    required this.gold,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (section == null) return title;
    final label = Text(
      section!,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: TextStyle(
        color: gold.withValues(alpha: 0.8),
        fontFamily: 'Outfit',
        fontSize: isMobile ? 12 : 17,
        fontWeight: FontWeight.w300,
        fontVariations: const [FontVariation('wght', 300)],
        letterSpacing: isMobile ? 1.6 : 2.0,
      ),
    );
    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, label],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '·',
            style: TextStyle(color: gold.withValues(alpha: 0.6), fontSize: 22),
          ),
        ),
        Flexible(child: label),
      ],
    );
  }
}
