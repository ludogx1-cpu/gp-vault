import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../src/doge_price_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../widgets/universal_web_view/universal_web_view.dart';
import '../widgets/widgets.dart';
import '../widgets/pet_overlay_widget.dart';
import '../widgets/chat_box_widget.dart';
import '../widgets/newsletter_subscribe_widget.dart';
import '../repositories/user_repository.dart';
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

  final GlobalKey _keyStats = GlobalKey();
  final GlobalKey _keyClaim = GlobalKey();
  final GlobalKey _keyPet = GlobalKey();
  final GlobalKey _keyChat = GlobalKey();
  
  bool _isProfileSetupShowing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowProfileSetup();
    });
  }

  @override
  void dispose() {

    super.dispose();
  }

  Future<void> _checkAndShowProfileSetup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('profile_setup_skipped') == true) return;

        // Fetch chat username from Firestore via repository
        final data = await UserRepository.getUserData(user.uid, forceServer: true);
        String chatUsername = '';
        String petName = 'Golden Paw Shiba';
        bool hasUsername = false;
        bool hasPetName = false;

        if (data != null) {
          // Primary check: setupComplete flag written by dialog on successful save
          if (data['setupComplete'] == true) return;
          
          final uName = data['username']?.toString() ?? '';
          final cName = data['chat_username']?.toString() ?? '';
          hasUsername = (uName.isNotEmpty && uName != 'Anonymous') || 
                        (cName.isNotEmpty && cName != 'Anonymous');
                        
          // Bypass setup for users who already completed it in the past (have a username)
          if (hasUsername) return;

          hasPetName = data.containsKey('pet_name') || data.containsKey('setupComplete');

          chatUsername = uName.isNotEmpty ? uName : cName;
          petName = data['pet_name']?.toString() ?? 'Golden Paw Shiba';
        }

        if (!hasUsername || !hasPetName) {
          if (mounted) {
            setState(() { _isProfileSetupShowing = true; });
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => ProfileSetupDialog(
                currentUsername: chatUsername,
                currentPetName: petName,
              ),
            );
            if (mounted) {
              setState(() { _isProfileSetupShowing = false; });
            }

            if (result == true && mounted) {
              // Dialog saved successfully, re-fetch to update state
              _checkAndShowProfileSetup();
            }
          }
        }

      }
      
      _startTourIfNeed();
    } catch (e) {
      // Ignore errors so we don't break the page load
    }
  }

  Future<void> _startTourIfNeed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('has_seen_tour') != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          ShowcaseView.get().startShowCase([_keyStats, _keyClaim, _keyPet, _keyChat]);
        } catch (e) {
          // ignore
        }
      });
      await prefs.setBool('has_seen_tour', true);
    }
  }


  @override
  Widget build(BuildContext context) {
    final dogePriceProvider = context.watch<DogePriceProvider>();
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
                      if (!_isProfileSetupShowing) ...[
                        if (kIsWeb)
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

                        if (kIsWeb) const SizedBox(height: 20),
                        if (kIsWeb) const BitcotasksAdWidget(),
                        if (kIsWeb) const SizedBox(height: 20),
                      ],

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

                      Showcase(
                        key: _keyStats,
                        description: 'Here you can see your DOGE balance, current level, and pet stats.',
                        child: FaucetStatsCard(
                          currentDogePrice: dogePriceProvider.currentDogePrice,
                          isPriceStale: dogePriceProvider.isPriceStale,
                        ),
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

                      Showcase(
                        key: _keyClaim,
                        description: 'Click here to claim your free DOGE from the Vault!',
                        child: const FaucetClaimCard(),
                      ),
                      const SizedBox(height: 25),

                      const BonusTimersCard(),
                      const SizedBox(height: 25),

                      if (!_isProfileSetupShowing && kIsWeb) ...[
                        const Bitcotasks160x600AdWidget(),
                        const SizedBox(height: 20),
                      ],

                      const NewsletterSubscribeWidget(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
            Showcase(
              key: _keyPet,
              description: 'This is your pet Shiba! Feed and play with them to boost your earnings.',
              child: const PetOverlayWidget(),
            ),
            Showcase(
              key: _keyChat,
              description: 'Chat with other users and catch Rain events here!',
              child: const ChatBoxWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
