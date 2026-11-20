import 'package:flutter/material.dart';
import 'package:gp_faucet/src/brand_colors.dart';

/// One of the pet's needs (hunger, energy...). Shown in brand gold, turning
/// red when the need is low so it still stands out.
class PetStatBar extends StatelessWidget {
  static const double lowThreshold = 25;

  final String label;
  final double value;
  final IconData icon;

  const PetStatBar({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = value < lowThreshold ? Colors.redAccent : kGold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${value.toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
