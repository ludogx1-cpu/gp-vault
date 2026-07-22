import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';

class Bitcotasks300x250AdWidget extends StatelessWidget {
  const Bitcotasks300x250AdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 300,
        height: 250,
        child: UniversalWebView.create(
          viewType: 'bitcotasks-300x250',
        ),
      ),
    );
  }
}
