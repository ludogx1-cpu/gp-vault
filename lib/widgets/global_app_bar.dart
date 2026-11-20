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
              shadowColor: themeProvider.isDarkMode ? Colors.black45 : Colors.black26,
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
                      child: ShaderMask(
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
                            fontVariations: const [FontVariation('wght', 700)],
                            letterSpacing: 3.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ...?actions,
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
