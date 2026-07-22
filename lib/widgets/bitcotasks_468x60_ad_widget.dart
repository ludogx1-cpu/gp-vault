import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';

class Bitcotasks468x60AdWidget extends StatelessWidget {
  const Bitcotasks468x60AdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 468,
        height: 60,
        child: UniversalWebView.create(
          viewType: 'bitcotasks-468x60',
        ),
      ),
    );
  }
}
