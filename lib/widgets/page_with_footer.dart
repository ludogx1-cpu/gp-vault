import 'app_footer.dart';
import 'package:flutter/material.dart';
import '../src/theme_provider.dart';

class PageWithFooter extends StatelessWidget {
  final Widget child;
  const PageWithFooter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? null : Colors.white,
            gradient: isDark ? themeProvider.darkModeGradient : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SafeArea(
                bottom: true,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Keep the page content first. When the content is
                        // shorter than the viewport the footer will be pushed
                        // to the bottom by the ConstrainedBox minHeight.
                        child,
                        const AppFooter(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
