import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'persistent_sidebar.dart';

class AppScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final bool showSidebar;

  const AppScaffold({
    super.key,
    this.body,
    this.appBar,
    this.backgroundColor,
    this.showSidebar = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLogged = FirebaseAuth.instance.currentUser != null;
    final bool effectiveShowSidebar = showSidebar && isLogged;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          if (isMobile) {
            return Stack(
              children: [
                SizedBox.expand(child: body ?? const SizedBox()),
                if (effectiveShowSidebar)
                  ValueListenableBuilder<bool>(
                    valueListenable: sidebarExpandedNotifier,
                    builder: (context, isExpanded, child) {
                      if (!isExpanded) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () => sidebarExpandedNotifier.value = false,
                        child: Container(
                          color: Colors.black54,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      );
                    },
                  ),
                if (effectiveShowSidebar) const PersistentSidebar(),
              ],
            );
          }
          return Row(
            children: [
              if (effectiveShowSidebar) const PersistentSidebar(),
              Expanded(child: body ?? const SizedBox()),
            ],
          );
        },
      ),
    );
  }
}
