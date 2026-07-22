import 'package:flutter/material.dart';
import 'persistent_sidebar.dart';

class AppScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    this.body,
    this.appBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: Row(
        children: [
          const PersistentSidebar(),
          Expanded(child: body ?? const SizedBox()),
        ],
      ),
    );
  }
}
