import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/root_gatekeeper.dart';
import 'screens/account_page.dart';
import 'screens/ad_hub_page.dart';
import 'screens/admin_dashboard_page.dart';
import 'screens/affiliate_links_page.dart';
import 'screens/blog_page.dart';
import 'screens/book_of_dog/book_of_dog_page.dart';
import 'screens/book_of_dog/book_of_dog_rules_page.dart';
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

import 'src/analytics.dart';
import 'package:gp_faucet/src/brand_colors.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Shows The Book Of Dog in the bottom bar. Turn on once photo storage is
/// set up in Firebase (the page itself is reachable at /book-of-dog anyway).
const bool kBookOfDogTab = true;

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  observers: [
    ConsentAwareAnalyticsObserver(),
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
          path: '/book-of-dog',
          pageBuilder: (context, state) => const NoTransitionPage(child: BookOfDogPage()),
        ),
        GoRoute(
          path: '/book-of-dog/rules',
          pageBuilder: (context, state) => const NoTransitionPage(child: BookOfDogRulesPage()),
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

  static const List<(String, IconData, String)> _tabs = [
    ('/faucet', Icons.water_drop, 'Faucet'),
    if (kBookOfDogTab) ('/book-of-dog', Icons.pets, 'Book Of Dog'),
    ('/staking', Icons.bolt, 'Bonus Vault'),
    ('/account', Icons.person, 'Account'),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return index < 0 ? 0 : index;
  }

  void _onItemTapped(int index, BuildContext context) {
    context.go(_tabs[index].$1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        backgroundColor: kAppBarColor,
        selectedItemColor: kGold,
        unselectedItemColor: Colors.grey,
        items: [
          for (final t in _tabs) BottomNavigationBarItem(icon: Icon(t.$2), label: t.$3),
        ],
      ),
    );
  }
}
