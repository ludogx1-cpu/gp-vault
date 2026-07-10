import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';

class TrustpilotWidget extends StatelessWidget {
  const TrustpilotWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: UniversalWebView.create(viewType: 'trustpilot-widget'),
    );
  }
}
