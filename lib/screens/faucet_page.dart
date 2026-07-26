import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/widgets.dart';
import '../widgets/pet_overlay_widget.dart';
import '../widgets/chat_box_widget.dart';
import '../widgets/newsletter_subscribe_widget.dart';
import '../widgets/universal_web_view/universal_web_view.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchDogePrice();
  }

  Future<void> _fetchDogePrice() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=DOGEUSDT',
        ),
      );
      if (res.statusCode == 200 && mounted) {
        setState(
          () => _currentDogePrice = double.parse(jsonDecode(res.body)['price']),
        );
      }
    } catch (e) {
      // ignore
    }
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 728,
                          height: 90,
                          child: UniversalWebView.create(viewType: 'adsterra-728x90', width: 728, height: 90),
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
                      const SizedBox(height: 20),

                      FaucetStatsCard(currentDogePrice: _currentDogePrice),
                      const SizedBox(height: 40),

                      const UpdatesBox(),
                      const SizedBox(height: 35),

                      const FaucetClaimCard(),
                      const SizedBox(height: 40),

                      const BonusTimersCard(),
                      const SizedBox(height: 20),

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
