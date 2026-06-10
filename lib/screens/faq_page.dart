import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../src/app_widgets.dart';

Future<Map<String, String>> _authHeaders() async {
  final headers = {'Content-Type': 'application/json'};
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final token = await user.getIdToken(true);
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}

// --- GLOBAL THEME CONSTANTS 🚀 ---
const kAppBarColor = Colors.black87;
const kAppBarIconColor = Colors.amber;
const kAppBarLogoColor = Colors.white;
const kTextColorOnBlack = Colors.white;

Color gpBrownText(BuildContext context, {Color darkColor = Colors.white70}) {
  return themeProvider.isDarkMode ? darkColor : Colors.brown;
}

// --- CAPTCHA JS BINDINGS ---
@JS('renderHCaptcha')
external void renderHCaptcha();

@JS('renderTurnstile')
external void renderTurnstile();

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
  } catch (e) {
    // ignore: empty_catches
  }

  await FirebaseService.initialize();

  runApp(
    ListenableBuilder(
      listenable: themeProvider,
      builder: (context, child) => MaterialApp(
        title: 'Golden Paw',
        home: const RootGatekeeper(),
        debugShowCheckedModeBanner: false,
        theme: themeProvider.lightTheme,
        darkTheme: themeProvider.darkTheme,
        themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      ),
    ),
  );
}

// ==========================================
// 1. THE SHELL
// ==========================================

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const ExpansionTile(
                  title: Text(
                    "What is Golden Paw?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "Golden Paw is a premier Dogecoin reward platform and advertising network. Users can earn free DOGE by claiming from our faucet or viewing sponsored PTC (Paid-To-Click) ads. Advertisers can purchase high-quality crypto traffic.",
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  title: Text(
                    "How do I withdraw my earnings?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "Once you reach the minimum withdrawal threshold of 0.001 DOGE in your Vault, you can navigate to your Profile, enter your FaucetPay Dogecoin address, and initiate an instant withdrawal.",
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  title: Text(
                    "Can I use a VPN or Proxy?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "Absolutely not. The use of VPNs, Proxies, Tor nodes, or automated claiming bots is strictly prohibited. Our security systems will automatically flag and permanently ban any accounts caught using these methods.",
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  title: Text(
                    "How does Staking work?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "You can lock your available DOGE into the Vault to earn an 8.5% Annual Percentage Yield (APY). Interest is calculated and distributed every single second.",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


