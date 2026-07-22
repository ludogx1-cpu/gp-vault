import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';

class Bitcotasks300x100AdWidget extends StatelessWidget {
  const Bitcotasks300x100AdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 300,
        height: 100,
        child: UniversalWebView.create(
          viewType: 'bitcotasks-300x100',
        ),
      ),
    );
  }
}
