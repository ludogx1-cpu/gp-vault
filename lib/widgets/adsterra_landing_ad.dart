import 'dart:math';
import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';
import 'smart_fallback_ad.dart';

class AdsterraLandingAd extends StatefulWidget {
  const AdsterraLandingAd({super.key});

  @override
  State<AdsterraLandingAd> createState() => _AdsterraLandingAdState();
}

class _AdsterraLandingAdState extends State<AdsterraLandingAd> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    // Unique ID for each ad unit on the page
    _viewId = 'adsterra-landing-${Random().nextInt(100000)}';
  }

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
                UniversalWebView.create(viewType: _viewId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
