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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          if (isMobile) {
            return Stack(
              children: [
                SizedBox.expand(child: body ?? const SizedBox()),
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
                const PersistentSidebar(),
              ],
            );
          }
          return Row(
            children: [
              const PersistentSidebar(),
              Expanded(child: body ?? const SizedBox()),
            ],
          );
        },
      ),
    );
  }
}
