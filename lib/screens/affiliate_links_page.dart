import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class PartnerData {
  final String title, sub, reward, url;
  final IconData icon;
  final Color color;
  final String category; // 🚀 Crucial for Categorization!
  PartnerData(
    this.title,
    this.sub,
    this.reward,
    this.icon,
    this.color,
    this.url,
    this.category,
  );
}

final partnerList = [
  PartnerData(
    "FaucetPay",
    "The ultimate crypto micro-wallet. Collect earnings with low fees.",
    "Best Micro-Wallet",
    Icons.account_balance_wallet,
    Colors.blue,
    "https://faucetpay.io/?r=5173106",
    "Wallets",
  ),
  PartnerData(
    "Cointiply",
    "The highest-paying Bitcoin rewards site. Play games, watch videos.",
    "Huge Survey Payouts",
    Icons.monetization_on,
    Colors.red,
    "https://cointiply.mobi/W6PYqv",
    "Faucets",
  ),
  PartnerData(
    "CoinPayU",
    "Earn free crypto by viewing advertisements and completing offers.",
    "Earn for Viewing Ads",
    Icons.ads_click,
    Colors.orange,
    "https://www.coinpayu.com/?r=ludogx1",
    "PTC",
  ),
  PartnerData(
    "AdBTC",
    "Get paid in Bitcoin for surfing the web. A trusted PTC platform.",
    "Bitcoin Web Surfing",
    Icons.currency_bitcoin,
    Colors.amber,
    "https://r.adbtc.top/2107663",
    "PTC",
  ),
  PartnerData(
    "DutchyCorp",
    "Automated faucet that lets you claim dozens of cryptos at once.",
    "Automated Claims",
    Icons.autorenew,
    Colors.teal,
    "https://autofaucet.dutchycorp.space/?r=woo270",
    "Faucets",
  ),
  PartnerData(
    "Contract-Miner",
    "Virtual cloud mining simulator. Earn real crypto passively.",
    "Simulated Cloud Mining",
    Icons.cloud_sync,
    Colors.indigo,
    "https://www.contract-miner.com/?r=91714744460d2dde189cc5",
    "Mining",
  ),
  PartnerData(
    "FireFaucet",
    "Level up and earn crypto automatically with daily bonuses.",
    "Level Up & Earn",
    Icons.local_fire_department,
    Colors.deepOrange,
    "https://firefaucet.win/ref/505709",
    "Faucets",
  ),
  PartnerData(
    "VieFaucet",
    "Fast crypto faucet. Complete shortlinks, PTC ads, and claims.",
    "Fast Shortlink Payouts",
    Icons.bolt,
    Colors.yellow.shade800,
    "https://viefaucet.com?r=637313decfe45da7ea2d376e",
    "Faucets",
  ),
  PartnerData(
    "CoinAdster",
    "Claim bits every hour! Features a reliable faucet and offerwalls.",
    "Hourly Crypto Faucet",
    Icons.watch_later,
    Colors.cyan,
    "https://coinadster.com/?ref=186362",
    "Faucets",
  ),
  PartnerData(
    "EarnBitMoon",
    "Claim crypto every 5 minutes. Watch ads and build bonuses.",
    "5-Minute Claims",
    Icons.nightlight_round,
    Colors.blueGrey,
    "https://earnbitmoon.club/?ref=59132",
    "Faucets",
  ),
  PartnerData(
    "Coinpayz",
    "Multi-coin faucet with instant payouts to your wallet.",
    "Instant Payouts",
    Icons.account_balance,
    Colors.green.shade700,
    "https://coinpayz.xyz/?r=784813",
    "Faucets",
  ),
  PartnerData(
    "Honeygain",
    "Earn passive income by sharing unused internet bandwidth.",
    "Passive Income",
    Icons.wifi_tethering,
    Colors.blueAccent,
    "https://join.honeygain.com/LUDOG88986",
    "Other",
  ),
];


class AffiliateLinksPage extends StatefulWidget {
  const AffiliateLinksPage({super.key});
  @override
  State<AffiliateLinksPage> createState() => _AffiliateLinksPageState();
}

class _AffiliateLinksPageState extends State<AffiliateLinksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    'Wallets',
    'PTC',
    'Faucets',
    'Mining',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getAdminIcon(String name) {
    switch (name) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'ptc':
        return Icons.ads_click;
      case 'faucet':
        return Icons.water_drop;
      case 'mining':
        return Icons.cloud_sync;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: Column(
        children: [
          const SizedBox(height: 15),
          const Text(
            "Earn More Crypto",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Text(
              "Sign up for our trusted partner sites below to maximize your daily crypto earnings.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              labelColor: Colors.brown.shade900,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: _categories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),
          const SizedBox(height: 15),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                var staticPartners = partnerList
                    .where((p) => p.category == category)
                    .toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('partners')
                      .where('category', isEqualTo: category)
                      .snapshots(),
                  builder: (context, snapshot) {
                    var dynamicDocs = snapshot.hasData
                        ? snapshot.data!.docs
                        : [];
                    if (staticPartners.isEmpty && dynamicDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No partners in this category yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      children: [
                        ...staticPartners.map(
                          (p) => _buildCompactCard(
                            title: p.title,
                            sub: p.sub,
                            reward: p.reward,
                            icon: p.icon,
                            color: p.color,
                            url: p.url,
                          ),
                        ),
                        ...dynamicDocs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          Color iconColor = Color(
                            int.tryParse(data['colorHex'] ?? '0xFF000000') ??
                                0xFF000000,
                          );
                          return _buildCompactCard(
                            title: data['title'] ?? '',
                            sub: data['sub'] ?? '',
                            reward: data['reward'] ?? '',
                            icon: _getAdminIcon(data['iconName'] ?? ''),
                            color: iconColor,
                            url: data['url'] ?? '',
                          );
                        }),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard({
    required String title,
    required String sub,
    required String reward,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reward,
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(60, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => web.window.open(url, '_blank'),
              child: const Text(
                "JOIN",
                style: TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🌟 UPDATED REFERRAL DASHBOARD 🌟
// ==========================================

