import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'src/theme_provider.dart';
import 'src/firebase_service.dart';
import 'src/user_provider.dart';
import 'widgets/widgets.dart';
import 'screens/faucet_page.dart';
import 'screens/staking_page.dart';
import 'screens/account_page.dart';
import 'screens/walk_pet_page.dart';

// Router configuration
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
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
      ],
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 REGISTER VIEWS (CAPTCHAS & TENOR GIF)
  try {
    // 1. hCaptcha
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('hcaptcha-widget', (
      int viewId,
    ) {
      final div = web.HTMLDivElement();
      div.id = 'hcaptcha-target';
      div.setAttribute(
        'style',
        'display: flex; justify-content: center; align-items: center; width: 100%; height: 100%; transform: scale(0.85); transform-origin: center center;',
      );
      return div;
    });

    // 2. Turnstile
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('turnstile-widget', (
      int viewId,
    ) {
      final div = web.HTMLDivElement();
      div.id = 'turnstile-target';
      div.setAttribute(
        'style',
        'display: flex; justify-content: center; align-items: center; width: 100%; height: 100%; transform: scale(0.85); transform-origin: center center;',
      );
      return div;
    });

    // 3. Tenor Dogecoin Animated GIF View (Original Embed + Hover Blocked!)
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('tenor-gif-view', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      // pointer-events: none completely blocks the Tenor hover menu
      iframe.setAttribute(
        'style',
        'border: none; width: 100%; height: 100%; pointer-events: none;',
      );

      iframe.setAttribute('srcdoc', '''
          <!DOCTYPE html>
          <html>
            <head>
              <style>
                body { margin: 0; display: flex; justify-content: center; align-items: center; overflow: hidden; background: transparent; }
                .tenor-gif-embed { width: 100% !important; max-width: 120px; pointer-events: none; }
              </style>
            </head>
            <body>
              <div class="tenor-gif-embed" data-postid="4351659229197618111" data-share-method="host" data-aspect-ratio="1" data-width="100%">
                <a href="https://tenor.com/view/dogecoin-logo-animation-dogecoin-logo-animation-crypto-gif-4351659229197618111">Dogecoin Logo GIF</a>
              </div>
              <script type="text/javascript" async src="https://tenor.com/embed.js"></script>
            </body>
          </html>
        ''');
      return iframe;
    });

    // 4. A-Ads Left Ad Unit
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('aads-2437206', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('data-aa', '2437206');
      iframe.setAttribute('src', 'https://ad.a-ads.com/2437206/?size=300x250');
      iframe.setAttribute('style', 'width:300px; height:250px; border:0px; padding:0; overflow:hidden; background-color: transparent;');
      iframe.setAttribute('allowtransparency', 'true');
      iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
      return iframe;
    });

    // 5. A-Ads Right Ad Unit
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('aads-2437207', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('data-aa', '2437207');
      iframe.setAttribute('src', 'https://ad.a-ads.com/2437207/?size=300x250');
      iframe.setAttribute('style', 'width:300px; height:250px; border:0px; padding:0; overflow:hidden; background-color: transparent;');
      iframe.setAttribute('allowtransparency', 'true');
      iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
      return iframe;
    });

    // 6. A-Ads Long Banner Ad Unit
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('aads-2437203', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('data-aa', '2437203');
      iframe.setAttribute('src', 'https://ad.a-ads.com/2437203/?size=728x90');
      iframe.setAttribute('style', 'width:728px; height:90px; border:0px; padding:0; overflow:hidden; background-color: transparent; display: block; margin: auto;');
      iframe.setAttribute('allowtransparency', 'true');
      iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
      return iframe;
    });

    // 6. YouTube Short Embed
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('youtube-short', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://www.youtube.com/embed/_MjLuFCm21Q?autoplay=0&loop=1');
      iframe.setAttribute('style', 'border:none; width:100%; height:100%; border-radius: 15px;');
      iframe.setAttribute('allow', 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share');
      iframe.setAttribute('allowfullscreen', 'true');
      return iframe;
    });
  } catch (e) {
    // ignore: empty_catches
  }

  await FirebaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, child) => MaterialApp.router(
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
