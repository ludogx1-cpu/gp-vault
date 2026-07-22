import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';

class Bitcotasks160x600AdWidget extends StatelessWidget {
  const Bitcotasks160x600AdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 160,
        height: 600,
        child: UniversalWebView.create(
          viewType: 'bitcotasks-160x600',
        ),
      ),
    );
  }
}
