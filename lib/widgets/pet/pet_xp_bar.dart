import 'package:flutter/material.dart';

class PetXpBar extends StatelessWidget {
  final int xp;
  final int nextStageXp;

  const PetXpBar({
    super.key,
    required this.xp,
    required this.nextStageXp,
  });

  @override
  Widget build(BuildContext context) {
    double progress = nextStageXp > 0 ? (xp / nextStageXp) * 100 : 100;
    if (progress > 100) progress = 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, size: 14, color: Colors.purple),
            const SizedBox(width: 4),
            const Text("XP (Next Stage)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('$xp / $nextStageXp', style: const TextStyle(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.purple.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
