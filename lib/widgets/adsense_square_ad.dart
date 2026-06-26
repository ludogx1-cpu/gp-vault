import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'smart_fallback_ad.dart';

class AdsenseSquareAd extends StatefulWidget {
  final String adSlot;

  const AdsenseSquareAd({super.key, this.adSlot = '6054324338'});

  @override
  State<AdsenseSquareAd> createState() => _AdsenseSquareAdState();
}

class _AdsenseSquareAdState extends State<AdsenseSquareAd> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    // Unique ID for each ad unit on the page
    _viewId = 'adsense-square-${Random().nextInt(100000)}';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final div = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%';

      final ins = web.HTMLElement.tag('ins') as web.HTMLElement
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..setAttribute('data-ad-client', 'ca-pub-2047805482197197')
        ..setAttribute('data-ad-slot', widget.adSlot)
        ..setAttribute('data-ad-format', 'auto')
        ..setAttribute('data-full-width-responsive', 'true');

      div.append(ins);

      // Push the ad to the adsbygoogle array
      final script = web.HTMLScriptElement()
        ..type = 'text/javascript'
        ..text = '(adsbygoogle = window.adsbygoogle || []).push({});';
      
      div.append(script);

      return div;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 250,
      child: Stack(
        children: [
          // Fallback Ad sits in the background
          const SmartFallbackAd(width: 300, height: 250),
          // Adsense is overlaid on top. If Adsense fails/is empty, fallback is visible.
          HtmlElementView(viewType: _viewId),
        ],
      ),
    );
  }
}
