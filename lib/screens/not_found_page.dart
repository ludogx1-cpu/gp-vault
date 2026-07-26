import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(),
      body: PageWithFooter(
        child: ListenableBuilder(
          listenable: themeProvider,
          builder: (context, _) {
            final isDark = themeProvider.isDarkMode;
            final titleColor = isDark ? Colors.white : Colors.black87;
            final textColor = isDark ? Colors.white70 : Colors.grey;

            return Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 100, color: Colors.amber),
                  const SizedBox(height: 20),
                  Text(
                    "404 - Page Not Found",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Oops! Looks like your Shiba got lost tracing a scent.\nThe page you're looking for doesn't exist.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => context.go('/faucet'),
                    icon: const Icon(Icons.home, color: Colors.black87),
                    label: const Text(
                      "Go Home",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
