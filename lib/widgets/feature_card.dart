import 'package:flutter/material.dart';
import '../src/theme_provider.dart';
import 'animated_hover_card.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color color;
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        return AnimatedHoverCard(
          padding: const EdgeInsets.all(30),
          backgroundColor: isDark ? Colors.black54 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.amber.withValues(alpha: 0.3)
                : Colors.grey.shade100,
          ),
          child: SizedBox(
            width: 240,
            child: Column(
              children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.brown,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}
