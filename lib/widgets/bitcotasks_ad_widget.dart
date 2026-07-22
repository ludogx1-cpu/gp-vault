import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';

class BitcotasksAdWidget extends StatelessWidget {
  const BitcotasksAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // The sizes are up to 728x90, so we should allow some height.
    // The responsive script adapts height to 250, 90, 60, or 100 based on width.
    // We'll give it a max height of 250 so it never gets clipped.
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 250),
      child: UniversalWebView.create(
        viewType: 'bitcotasks-ad',
      ),
    );
  }
}
