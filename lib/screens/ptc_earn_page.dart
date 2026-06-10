import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---




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

class PtcEarnPage extends StatefulWidget {
  const PtcEarnPage({super.key});

  @override
  State<PtcEarnPage> createState() => _PtcEarnPageState();
}

class _PtcEarnPageState extends State<PtcEarnPage> {
  Stream<DocumentSnapshot>? _userStream;
  Stream<QuerySnapshot>? _clicksStream;
  Stream<QuerySnapshot>? _adsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 🔑 Initialize streams exactly ONCE to prevent Firebase Web crashes
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
      _clicksStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ptc_clicks')
          .snapshots();
      _adsStream = FirebaseFirestore.instance
          .collection('ptc_ads')
          .where('clicks_remaining', isGreaterThan: 0)
          .snapshots();
    }
  }

  void _watchAd(
    BuildContext context,
    String adId,
    String targetUrl,
    int duration,
  ) {
    web.window.open(targetUrl, '_blank');
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => PtcTimerDialog(adId: adId, duration: duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        _userStream == null ||
        _clicksStream == null ||
        _adsStream == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'EARN DOGE (PTC)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          backgroundColor: Colors.amber,
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            "You must log in to earn from PTC ads!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.brown,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, userDocSnapshot) {
          bool canClaimBonus = true;
          int minutesLeft = 0;
          if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
            var uData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
            Timestamp? lastClaim =
                uData?['last_bonus_sponsor_claim'] as Timestamp?;
            if (lastClaim != null) {
              final now = DateTime.now();
              final difference = now.difference(lastClaim.toDate());
              if (difference.inHours < 3) {
                canClaimBonus = false;
                minutesLeft = 180 - difference.inMinutes;
              }
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _clicksStream,
            builder: (context, userClicksSnapshot) {
              List<String> clickedLast24h = [];
              if (userClicksSnapshot.hasData) {
                final now = DateTime.now();
                for (var doc in userClicksSnapshot.data!.docs) {
                  final clickData = doc.data() as Map<String, dynamic>?;
                  Timestamp? ts = clickData?['timestamp'] as Timestamp?;
                  if (ts != null && now.difference(ts.toDate()).inHours < 24) {
                    clickedLast24h.add(doc.id);
                  }
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _adsStream,
                builder: (context, adsSnapshot) {
                  if (adsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    );
                  }

                  var allAds = adsSnapshot.data?.docs ?? [];
                  var availableAds = allAds
                      .where((doc) => !clickedLast24h.contains(doc.id))
                      .toList();

                  // 👑 WRAP THE REST OF THE PAGE IN THE THEME BUILDER
                  return ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, _) {
                      final isDark = themeProvider.isDarkMode;

                      Widget adContent;
                      if (allAds.isEmpty) {
                        adContent = const Center(
                          child: Text(
                            "No ads available right now. Check back later!",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      } else if (availableAds.isEmpty) {
                        adContent = Center(
                          child: Text(
                            "You have clicked all available ads today!\nCome back tomorrow for more.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else {
                        adContent = Column(
                          children: availableAds.map((doc) {
                            final adData =
                                doc.data() as Map<String, dynamic>? ?? {};

                            int duration = adData['duration'] as int? ?? 10;
                            double reward = (adData['reward'] as num? ?? 0.001)
                                .toDouble();
                            String title =
                                adData['title'] as String? ??
                                "Sponsored Website";
                            String targetUrl =
                                adData['target_url'] as String? ?? "";

                            return Card(
                              // THEMED AD CARDS
                              color: isDark
                                  ? themeProvider.darkGreyBoxColor
                                  : Colors.white,
                              elevation: isDark ? 0 : 3,
                              margin: const EdgeInsets.only(bottom: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: isDark
                                      ? themeProvider.darkGreyBorder
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(15),
                                leading: const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 40,
                                ),
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.brown,
                                  ),
                                ),
                                subtitle: Text(
                                  "Reward: +${reward.toStringAsFixed(4)} DOGE\nTimer: $duration Seconds",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () => _watchAd(
                                    context,
                                    doc.id,
                                    targetUrl,
                                    duration,
                                  ),
                                  child: const Text(
                                    "VIEW",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              // THEMED SUPPORT BOX
                              color: isDark
                                  ? themeProvider.darkGreyBoxColor
                                  : (canClaimBonus
                                        ? Colors.amber.shade100
                                        : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isDark
                                    ? themeProvider.darkGreyBorder
                                    : (canClaimBonus
                                          ? Colors.amber.shade400
                                          : Colors.grey.shade400),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "🌟 Support Golden Paw & Earn DOGE 🌟",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.brown,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  "Stay on the page for 30 seconds to earn\n0.003 DOGE & 30 XP!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canClaimBonus
                                          ? Colors.amber
                                          : Colors.grey,
                                      foregroundColor: canClaimBonus
                                          ? Colors.brown.shade900
                                          : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: Icon(
                                      canClaimBonus
                                          ? Icons.card_giftcard
                                          : Icons.lock_clock,
                                    ),
                                    label: Text(
                                      canClaimBonus
                                          ? 'VIEW BONUS SPONSORS'
                                          : 'COOLDOWN: $minutesLeft MIN',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    onPressed: canClaimBonus
                                        ? () {
                                            web.window.open(
                                              '/sponsors.html',
                                              '_blank',
                                            );
                                            showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (context) =>
                                                  const BonusTimerDialog(),
                                            );
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          adContent,
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 🚀 SECRET ADMIN DASHBOARD 🚀
// ==========================================

