import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/root_gatekeeper.dart';
import 'screens/account_page.dart';
import 'screens/ad_hub_page.dart';
import 'screens/admin_dashboard_page.dart';
import 'screens/affiliate_links_page.dart';
import 'screens/blog_page.dart';
import 'screens/dogeogotcha_instructions_page.dart';
import 'screens/faucet_page.dart';
import 'screens/leaderboard_page.dart';
import 'screens/not_found_page.dart';
import 'screens/offerwall_hub_page.dart';
import 'screens/privacy_policy_page.dart';
import 'screens/promo_code_page.dart';
import 'screens/ptc_earn_page.dart';
import 'screens/referral_page.dart';
import 'screens/staking_page.dart';
import 'screens/suggestion_box_page.dart';
import 'screens/terms_of_service_page.dart';
import 'screens/walk_pet_page.dart';
import 'screens/reward_history_page.dart';
import 'src/theme_provider.dart';

import 'package:firebase_analytics/firebase_analytics.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  observers: [
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
  ],
  errorBuilder: (context, state) => const NotFoundPage(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RootGatekeeper(),
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/faucet',
          pageBuilder: (context, state) => const NoTransitionPage(child: FaucetPage()),
        ),
        GoRoute(
          path: '/staking',
          pageBuilder: (context, state) => const NoTransitionPage(child: StakingPage()),
        ),
        GoRoute(
          path: '/account',
          pageBuilder: (context, state) => const NoTransitionPage(child: AccountPage()),
        ),
        GoRoute(
          path: '/walk-pet',
          pageBuilder: (context, state) => const NoTransitionPage(child: WalkPetPage()),
        ),
        GoRoute(
          path: '/admin',
          pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboardPage()),
        ),
        GoRoute(
          path: '/offerwalls',
          pageBuilder: (context, state) => const NoTransitionPage(child: OfferwallHubPage()),
        ),
        GoRoute(
          path: '/bonus-partners',
          pageBuilder: (context, state) => const NoTransitionPage(child: AffiliateLinksPage()),
        ),
        GoRoute(
          path: '/ads',
          pageBuilder: (context, state) => const NoTransitionPage(child: AdHubPage()),
        ),
        GoRoute(
          path: '/referral',
          pageBuilder: (context, state) => const NoTransitionPage(child: ReferralPage()),
        ),
        GoRoute(
          path: '/ptc',
          pageBuilder: (context, state) => const NoTransitionPage(child: PtcEarnPage()),
        ),
        GoRoute(
          path: '/guide',
          pageBuilder: (context, state) => const NoTransitionPage(child: DogeogotchaInstructionsPage()),
        ),
        GoRoute(
          path: '/leaderboard',
          pageBuilder: (context, state) => const NoTransitionPage(child: LeaderboardPage()),
        ),
        GoRoute(
          path: '/suggestions',
          pageBuilder: (context, state) => const NoTransitionPage(child: SuggestionBoxPage()),
        ),
        GoRoute(
          path: '/blog',
          pageBuilder: (context, state) => const NoTransitionPage(child: BlogPage()),
        ),
        GoRoute(
          path: '/promo',
          pageBuilder: (context, state) => const NoTransitionPage(child: PromoCodePage()),
        ),
        GoRoute(
          path: '/privacy',
          pageBuilder: (context, state) => const NoTransitionPage(child: PrivacyPolicyPage()),
        ),
        GoRoute(
          path: '/terms',
          pageBuilder: (context, state) => const NoTransitionPage(child: TermsOfServicePage()),
        ),
        GoRoute(
          path: '/reward-history',
          pageBuilder: (context, state) => const NoTransitionPage(child: RewardHistoryPage()),
        ),
      ],
    ),
  ],
);

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/faucet')) return 0;
    if (location.startsWith('/staking')) return 1;
    if (location.startsWith('/account')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/faucet');
        break;
      case 1:
        context.go('/staking');
        break;
      case 2:
        context.go('/account');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        backgroundColor: kAppBarColor,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Faucet',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Staking'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
