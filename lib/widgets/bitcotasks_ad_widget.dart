import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';

class BitcotasksAdWidget extends StatelessWidget {
  const BitcotasksAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double adWidth = 300;
    double adHeight = 250;
    if (screenWidth >= 1200) {
      adWidth = 728;
      adHeight = 90;
    } else if (screenWidth >= 992) {
      adWidth = 468;
      adHeight = 60;
    } else if (screenWidth >= 768) {
      adWidth = 300;
      adHeight = 100;
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: adWidth,
          height: adHeight,
          child: UniversalWebView.create(
            viewType: 'bitcotasks-ad',
            width: adWidth,
            height: adHeight,
          ),
        ),
      ),
    );
  }
}
