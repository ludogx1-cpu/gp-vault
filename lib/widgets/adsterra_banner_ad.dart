import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'smart_fallback_ad.dart';

class AdsterraBannerAd extends StatefulWidget {
  const AdsterraBannerAd({super.key});

  @override
  State<AdsterraBannerAd> createState() => _AdsterraBannerAdState();
}

class _AdsterraBannerAdState extends State<AdsterraBannerAd> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    // Unique ID for each ad unit on the page
    _viewId = 'adsterra-banner-${Random().nextInt(100000)}';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..src = '/adsterra_728x90.html';

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 728),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 728,
            height: 90,
            child: Stack(
              children: [
                const SmartFallbackAd(width: 728, height: 90),
                HtmlElementView(viewType: _viewId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
