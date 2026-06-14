import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool _isRegistered = false;

class TrustpilotWidget extends StatefulWidget {
  const TrustpilotWidget({super.key});

  @override
  State<TrustpilotWidget> createState() => _TrustpilotWidgetState();
}

class _TrustpilotWidgetState extends State<TrustpilotWidget> {
  @override
  void initState() {
    super.initState();
    if (!_isRegistered) {
      ui_web.platformViewRegistry.registerViewFactory('trustpilot-widget', (int viewId) {
        final div = web.document.createElement('div') as web.HTMLDivElement;
        div.className = 'trustpilot-widget';
        div.setAttribute('data-locale', 'en-US');
        div.setAttribute('data-template-id', '56278e9abfbbba0bdcd568bc');
        div.setAttribute('data-businessunit-id', '6a1dccd0a3d62f26192ecf20');
        div.setAttribute('data-style-height', '52px');
        div.setAttribute('data-style-width', '100%');
        div.setAttribute('data-token', 'c72b1282-1e67-4cde-a10e-59a91bf3216f');
        
        final a = web.document.createElement('a') as web.HTMLAnchorElement;
        a.href = 'https://www.trustpilot.com/review/goldenpaw.dog';
        a.target = '_blank';
        a.rel = 'noopener';
        a.text = 'Trustpilot';
        
        div.appendChild(a);
        
        // Wait for the DOM to insert it, then ask Trustpilot to load
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
             final windowObj = web.window as JSObject;
             if (windowObj.has('Trustpilot')) {
               final tp = windowObj.getProperty('Trustpilot'.toJS) as JSObject;
               tp.callMethod('loadFromElement'.toJS, div);
             }
          } catch (e) {
             debugPrint("Trustpilot load error: $e");
          }
        });

        return div;
      });
      _isRegistered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: const HtmlElementView(viewType: 'trustpilot-widget'),
    );
  }
}
