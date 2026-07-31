import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/universal_web_view/universal_web_view.dart';
import '../widgets/widgets.dart';
import '../widgets/pet_overlay_widget.dart';
import '../widgets/chat_box_widget.dart';
import '../widgets/newsletter_subscribe_widget.dart';
import '../widgets/profile_setup_dialog.dart';
import 'faucet/welcome_banner.dart';
import 'faucet/updates_box.dart';
import 'faucet/faucet_claim_card.dart';
import 'faucet/faucet_stats_card.dart';
import 'faucet/bonus_timers_card.dart';

class FaucetPage extends StatefulWidget {
  const FaucetPage({super.key});

  @override
  State<FaucetPage> createState() => _FaucetPageState();
}

class _FaucetPageState extends State<FaucetPage> {
  double _currentDogePrice = 0.15;
  DateTime? _lastPriceUpdate;
  Timer? _priceTimer;

  @override
  void initState() {
    super.initState();
    _fetchDogePrice();
    _priceTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchDogePrice();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowProfileSetup();
    });
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndShowProfileSetup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch chat username from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String chatUsername = '';
        String petName = 'Golden Paw Shiba';
        bool hasUsername = false;
        bool hasPetName = false;

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          
          final uName = data['username']?.toString() ?? '';
          final cName = data['chat_username']?.toString() ?? '';
          hasUsername = (uName.isNotEmpty && uName != 'Anonymous') || 
                        (cName.isNotEmpty && cName != 'Anonymous');
          hasPetName = data.containsKey('pet_name');

          chatUsername = uName.isNotEmpty ? uName : cName;
          petName = data['pet_name']?.toString() ?? 'Golden Paw Shiba';
        }

        if (!hasUsername || !hasPetName) {
          if (mounted) {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => ProfileSetupDialog(
                currentUsername: chatUsername,
                currentPetName: petName,
              ),
            );

            if (result == true && mounted) {
              // Dialog saved successfully, re-fetch to update state
              _checkAndShowProfileSetup();
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors so we don't break the page load
    }
  }

  Future<void> _fetchDogePrice() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=DOGEUSDT',
        ),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _currentDogePrice = double.parse(jsonDecode(res.body)['price']);
          _lastPriceUpdate = DateTime.now();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  bool get _isPriceStale {
    if (_lastPriceUpdate == null) return true;
    return DateTime.now().difference(_lastPriceUpdate!).inMinutes >= 10;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(),
      body: MouseRegion(
        onHover: (event) {
          globalMouseX = event.position.dx;
          globalMouseY = event.position.dy;
        },
        hitTestBehavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            PageWithFooter(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.textScalerOf(context).scale(1.0) * 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 728,
                          height: 90,
                          child: UniversalWebView.create(
                            viewType: 'adsterra-728x90',
                            width: 728,
                            height: 90,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 728,
                          height: 90,
                          child: UniversalWebView.create(
                            viewType: 'ccnsad-728x90',
                            width: 728,
                            height: 90,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const BitcotasksAdWidget(),
                      const SizedBox(height: 20),

                      const SizedBox(
                        width: 120,
                        height: 120,
                        child: Image(
                          image: AssetImage('assets/logo_landing.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const WelcomeBanner(),
                      const SizedBox(height: 25),

                      FaucetStatsCard(
                        currentDogePrice: _currentDogePrice,
                        isPriceStale: _isPriceStale,
                      ),
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Tip: If you're having trouble clicking the left menu tabs, please scroll down slightly so no ads are in view, then try again.",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const UpdatesBox(),
                      const SizedBox(height: 25),

                      const FaucetClaimCard(),
                      const SizedBox(height: 25),

                      const BonusTimersCard(),
                      const SizedBox(height: 25),

                      const Bitcotasks160x600AdWidget(),
                      const SizedBox(height: 20),

                      const NewsletterSubscribeWidget(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
            const PetOverlayWidget(),
            const ChatBoxWidget(),
          ],
        ),
      ),
    );
  }
}
