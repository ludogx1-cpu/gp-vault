import 'wallet_dropdown_button.dart';
import 'live_referral_tracker.dart';
import 'package:flutter/material.dart';
import '../src/theme_provider.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackArrow;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showWallet;

  const GlobalAppBar({
    super.key,
    this.showBackArrow = false,
    this.actions,
    this.centerTitle = false,
    this.showWallet = true,
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
              elevation: 10,
              shadowColor: Colors.black45,
              centerTitle: isMobile ? false : centerTitle,
              iconTheme: const IconThemeData(color: kAppBarIconColor),
              titleSpacing: showBackArrow ? 0 : 16,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/logo2.png',
                    height: isMobile ? 36 : 42,
                    fit: BoxFit.contain,
                  ),
                  Transform.translate(
                    offset: const Offset(-4, 0),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0.5),
                      child: Text(
                        'Doge Hub',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              leading: showBackArrow
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
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
