import 'package:flutter/material.dart';
import 'universal_web_view/universal_web_view.dart';

class Bitcotasks728x90AdWidget extends StatelessWidget {
  const Bitcotasks728x90AdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 728,
        height: 90,
        child: UniversalWebView.create(
          viewType: 'bitcotasks-728x90',
        ),
      ),
    );
  }
}
