import 'package:flutter/material.dart';
import 'sprite_animation.dart';

class RunningPetWidget extends StatefulWidget {
  const RunningPetWidget({super.key});

  @override
  State<RunningPetWidget> createState() => _RunningPetWidgetState();
}

class _RunningPetWidgetState extends State<RunningPetWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // It takes 8 seconds to run across the screen
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // We use a Stack so we can freely position it.
        // We calculate exactly how far to translate so it starts fully offscreen left
        // and ends fully offscreen right.
        return SizedBox(
          width: constraints.maxWidth,
          height: 200, // Fixed height for the running pet
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Align(
                // Alignment goes from -1.5 (left offscreen) to 1.5 (right offscreen)
                alignment: Alignment(-1.5 + (_controller.value * 3.0), 0),
                child: child,
              );
            },
            child: const SpriteAnimationWidget(
              imagePath: 'assets/pets/puppy/corgi puppy trans running happily.webp',
              columns: 11,
              rows: 11,
              frameCount: 121,
              fps: 12,
              width: 200,
              height: 200,
            ),
          ),
        );
      },
    );
  }
}
