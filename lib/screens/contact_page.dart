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

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.support_agent, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "Need Help?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "If you have questions about a withdrawal, an ad campaign, or need to report a bug, please reach out!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: const Column(
                  children: [
                    Text(
                      "Email Support",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "support@goldenpaw.com",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "We aim to respond to all inquiries within 24-48 hours.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Back",
                  style: TextStyle(
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ⏱️ PTC AD TIMER DIALOG
// ==========================================

