import 'package:flutter/material.dart';
import 'pet_depth_perspective.dart';

class FetchBallWidget extends StatelessWidget {
  final double ballX;
  final double ballY;
  final String equippedBall;
  final PetDepthPerspective perspective;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const FetchBallWidget({
    super.key,
    required this.ballX,
    required this.ballY,
    required this.equippedBall,
    this.perspective = PetDepthPerspective.neutral,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  Color _getBallColor(String colorString) {
    switch (colorString) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'indigo':
        return Colors.indigo;
      case 'violet':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getBallColor(equippedBall);
    final ballScale = perspective.scale.clamp(0.52, 1.50);

    return Positioned(
      left: ballX,
      top: ballY,
      child: Transform.scale(
        scale: ballScale,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          child: Padding(
            // Generous touch target even when ball is small in the distance
            padding: const EdgeInsets.all(6.0),
            child: perspective.applyOpticalDoF(
              SizedBox(
                width: 32,
                height: 36,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Ground contact shadow beneath the ball
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 24,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: (0.24 * perspective.shadowIntensity).clamp(
                              0.08,
                              0.36,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // 3D shaded fetch ball
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.35),
                          radius: 0.85,
                          colors: [
                            Color.lerp(baseColor, Colors.white, 0.55) ??
                                baseColor,
                            baseColor,
                            Color.lerp(baseColor, Colors.black, 0.28) ??
                                baseColor,
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF1F120C),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
