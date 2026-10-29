import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';
import 'smart_fallback_ad.dart';

class AdsterraLandingAd extends StatelessWidget {
  const AdsterraLandingAd({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 468),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 468,
            height: 60,
            child: Stack(
              children: [
                const SmartFallbackAd(width: 468, height: 60),
                UniversalWebView.create(
                  viewType: 'adsterra-468x60',
                  width: 468,
                  height: 60,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
