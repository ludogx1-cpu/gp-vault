import 'dart:math';
import 'package:flutter/material.dart';
import 'pet_depth_perspective.dart';

class SpeechBubbleWidget extends StatelessWidget {
  final String text;
  final double x;
  final double y;
  final double combinedPetScale;
  final PetDepthPerspective perspective;

  const SpeechBubbleWidget({
    super.key,
    required this.text,
    required this.x,
    required this.y,
    this.combinedPetScale = 1.0,
    this.perspective = PetDepthPerspective.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleScale = (0.76 + 0.28 * perspective.depth).clamp(0.74, 1.08);
    // Keep speech text readable even when far away by using gentler DoF on text
    final textPerspective = PetDepthPerspective(
      depth: perspective.depth,
      scale: bubbleScale,
      blurSigma: perspective.blurSigma * 0.42,
      opacity: max(0.86, perspective.opacity),
      shadowIntensity: perspective.shadowIntensity,
    );

    final headTopY = y + 100.0 - (142.0 * combinedPetScale);
    final bubbleLeft = (x + 50.0 - 85.0)
        .clamp(10.0, max(10.0, screenWidth - 180.0))
        .toDouble();
    final bubbleTop = max(10.0, headTopY - 56.0 * bubbleScale);

    return Positioned(
      left: bubbleLeft,
      top: bubbleTop,
      child: IgnorePointer(
        child: Transform.scale(
          scale: bubbleScale,
          alignment: Alignment.bottomCenter,
          child: textPerspective.applyOpticalDoF(
            Container(
              width: 170,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(2),
                ),
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
