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

    return Container(
      color: kAppBarColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LiveReferralTracker(),
            AppBar(
              primary: false,
              toolbarHeight: 70,
              backgroundColor: kAppBarColor,
              surfaceTintColor: Colors.transparent,
              elevation: 10,
              shadowColor: Colors.black45,
              centerTitle: isMobile ? false : centerTitle,
              iconTheme: const IconThemeData(color: kAppBarIconColor),
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
                            sidebarExpandedNotifier.value = !sidebarExpandedNotifier.value;
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
                      'assets/logo_landing.png',
                      height: isMobile ? 36 : 42,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Image.asset(
                        'assets/Golen Paw Title.png',
                        height: isMobile ? ((showBackArrow || showMenuIcon) ? 44 : 52) : 52,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (actions != null) ...actions!,
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
