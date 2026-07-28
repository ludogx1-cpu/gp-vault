import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/platform_registry/platform_registry.dart' if (dart.library.html) 'src/platform_registry/platform_registry_web.dart';
import 'package:go_router/go_router.dart';
import 'src/theme_provider.dart';
import 'src/firebase_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'src/user_provider.dart';
import 'widgets/widgets.dart';
import 'screens/faucet_page.dart';
import 'screens/staking_page.dart';
import 'screens/account_page.dart';
import 'screens/walk_pet_page.dart';
import 'screens/not_found_page.dart';
import 'src/notification_service.dart';
import 'src/firebase_messaging_web_hack.dart' if (dart.library.io) 'src/firebase_messaging_web_hack_stub.dart';

import 'screens/admin_dashboard_page.dart';
import 'screens/offerwall_hub_page.dart';
import 'screens/affiliate_links_page.dart';
import 'screens/ad_hub_page.dart';
import 'screens/referral_page.dart';
import 'screens/ptc_earn_page.dart';
import 'screens/dogeogotcha_instructions_page.dart';
import 'screens/leaderboard_page.dart';
import 'screens/suggestion_box_page.dart';
import 'screens/blog_page.dart';
import 'screens/promo_code_page.dart';
// Router configuration
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
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
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
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
        GoRoute(path: '/admin', pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboardPage())),
        GoRoute(path: '/offerwalls', pageBuilder: (context, state) => const NoTransitionPage(child: OfferwallHubPage())),
        GoRoute(path: '/bonus-partners', pageBuilder: (context, state) => const NoTransitionPage(child: AffiliateLinksPage())),
        GoRoute(path: '/ads', pageBuilder: (context, state) => const NoTransitionPage(child: AdHubPage())),
        GoRoute(path: '/referral', pageBuilder: (context, state) => const NoTransitionPage(child: ReferralPage())),
        GoRoute(path: '/ptc', pageBuilder: (context, state) => const NoTransitionPage(child: PtcEarnPage())),
        GoRoute(path: '/guide', pageBuilder: (context, state) => const NoTransitionPage(child: DogeogotchaInstructionsPage())),
        GoRoute(path: '/leaderboard', pageBuilder: (context, state) => const NoTransitionPage(child: LeaderboardPage())),
        GoRoute(path: '/suggestions', pageBuilder: (context, state) => const NoTransitionPage(child: SuggestionBoxPage())),
        GoRoute(path: '/blog', pageBuilder: (context, state) => const NoTransitionPage(child: BlogPage())),
        GoRoute(path: '/promo', pageBuilder: (context, state) => const NoTransitionPage(child: PromoCodePage())),
      ],
    ),
  ],
);

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  registerWebViews();
  if (kIsWeb) {
    registerFirebaseMessagingWeb();
  }

  await FirebaseService.initialize();
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, child) => MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'Golden Paw',
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          theme: theme.lightTheme,
          darkTheme: theme.darkTheme,
          themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    ),
  );
}

// ==========================================
// 1. THE SHELL
// ==========================================
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

// ==========================================
// 2. THE FAUCET PAGE
// ==========================================
