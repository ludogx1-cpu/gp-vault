import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'app_router.dart';
import 'src/theme_provider.dart';
import 'src/firebase_service.dart';
import 'src/presence_service.dart';
import 'src/user_provider.dart';
import 'src/doge_price_provider.dart';
import 'src/notification_service.dart';
import 'src/firebase_messaging_web_hack.dart' if (dart.library.io) 'src/firebase_messaging_web_hack_stub.dart';
import 'src/platform_registry/platform_registry.dart' if (dart.library.html) 'src/platform_registry/platform_registry_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  registerWebViews();
  if (kIsWeb) {
    registerFirebaseMessagingWeb();
  }

  await FirebaseService.initialize();
  await NotificationService().init();
  PresenceService().initialize();
  ShowcaseView.register();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DogePriceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, child) => MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'Golden Paw',
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
          theme: theme.lightTheme,
          darkTheme: theme.darkTheme,
          themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
