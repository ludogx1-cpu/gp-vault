import 'package:flutter/material.dart';
import 'pet_depth_perspective.dart';

class FetchBallWidget extends StatelessWidget {
  final double ballX;
  final double ballY;
  final String equippedBall;
  final PetDepthPerspective perspective;
  final Function(DragStartDetails)? onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final VoidCallback? onPanCancel;
  final VoidCallback? onTap;
  final bool isDragging;

  const FetchBallWidget({
    super.key,
    required this.ballX,
    required this.ballY,
    required this.equippedBall,
    this.perspective = PetDepthPerspective.neutral,
    this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.onPanCancel,
    this.onTap,
    this.isDragging = false,
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
    final ballScale = perspective.scale.clamp(0.55, 1.50);

    return Positioned(
      left: ballX,
      top: ballY,
      child: Transform.scale(
        scale: ballScale,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onPanCancel: onPanCancel,
          child: MouseRegion(
            cursor: isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
            child: Padding(
              // Generous 12px touch target so grabbing and flinging is effortless
              padding: const EdgeInsets.all(12.0),
              child: perspective.applyOpticalDoF(
                SizedBox(
                  width: 36,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Ground contact shadow beneath the ball
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 26,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: (0.28 * perspective.shadowIntensity)
                                  .clamp(0.10, 0.42),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      // Interactive ready-to-throw indicator ring when held
                      if (isDragging)
                        Positioned(
                          top: -2,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.85),
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),

                      // 3D shaded fetch ball
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.35, -0.35),
                            radius: 0.85,
                            colors: [
                              Color.lerp(baseColor, Colors.white, 0.60) ??
                                  baseColor,
                              baseColor,
                              Color.lerp(baseColor, Colors.black, 0.32) ??
                                  baseColor,
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF1F120C),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: baseColor.withValues(alpha: 0.40),
                              blurRadius: isDragging ? 10 : 4,
                              spreadRadius: isDragging ? 3 : 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
