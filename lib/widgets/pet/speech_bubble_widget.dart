import 'package:flutter/material.dart';

class SpeechBubbleWidget extends StatelessWidget {
  final String text;
  final double x;
  final double y;
  final bool isChasing;
  final bool isReturning;

  const SpeechBubbleWidget({
    super.key,
    required this.text,
    required this.x,
    required this.y,
    required this.isChasing,
    required this.isReturning,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: Duration(seconds: isChasing ? 1 : (isReturning ? 2 : 4)),
      curve: Curves.easeInOut,
      left: x - 80,
      top: y - 80,
      child: IgnorePointer(
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(0), // Points to pet
            ),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
