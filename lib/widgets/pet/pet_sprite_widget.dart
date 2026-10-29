import 'dart:math';
import 'package:flutter/material.dart';
import 'pet_collar_painter.dart';
import 'pet_depth_perspective.dart';

class PetSpriteWidget extends StatelessWidget {
  final String stage;
  final String petName;
  final bool isSick;
  final bool isSleeping;
  final bool facingRight;
  final List<String> equippedAccessories;
  final String emotion;
  final String reactionEmoji;
  final bool isCloseUp;
  final bool isWalkAnimating;
  final bool isChasing;
  final PetDepthPerspective perspective;

  final AnimationController shakeController;
  final AnimationController walkController;
  final AnimationController boopController;
  final AnimationController trickController;
  final AnimationController? idleController;
  final AnimationController? reactionController;

  final String currentTrick;
  final VoidCallback onBoopDown;
  final VoidCallback onBoopUp;
  final VoidCallback onBoopCancel;
  final VoidCallback onStroke;

  const PetSpriteWidget({
    super.key,
    required this.stage,
    required this.petName,
    required this.isSick,
    this.isSleeping = false,
    required this.facingRight,
    required this.equippedAccessories,
    required this.emotion,
    this.reactionEmoji = '',
    required this.isCloseUp,
    required this.isWalkAnimating,
    required this.isChasing,
    this.perspective = PetDepthPerspective.neutral,
    required this.shakeController,
    required this.walkController,
    required this.boopController,
    required this.trickController,
    this.idleController,
    this.reactionController,
    required this.currentTrick,
    required this.onBoopDown,
    required this.onBoopUp,
    required this.onBoopCancel,
    required this.onStroke,
  });

  static String getImageAssetForStage(String stage) {
    switch (stage) {
      case 'egg':
        return 'assets/shiba_egg.png';
      case 'baby':
        return 'assets/shiba_baby.png';
      case 'toddler':
        return 'assets/shiba_teen.png';
      case 'puppy':
        return 'assets/shiba_puppy.png';
      case 'child':
        return 'assets/shiba_child.png';
      case 'teen':
        return 'assets/shiba_young_adult.png';
      case 'young_adult':
        return 'assets/shiba_young_adult.png';
      case 'adult':
        return 'assets/shiba_adult.png';
      case 'old_dog':
        return 'assets/old_dog.png';
      default:
        return 'assets/shiba_puppy.png';
    }
  }

  static double stageScaleFor(String stage) {
    switch (stage) {
      case 'egg':
        return 0.72;
      case 'baby':
        return 0.78;
      case 'toddler':
        return 0.86;
      case 'puppy':
        return 0.94;
      case 'child':
        return 1.02;
      case 'teen':
        return 1.10;
      case 'young_adult':
        return 1.18;
      case 'adult':
        return 1.28;
      case 'old_dog':
        return 1.34;
      default:
        return 0.90;
    }
  }

  double _getScaleForStage() => stageScaleFor(stage);

  /// Computes organic natural blink amount (0.0 = open, 1.0 = closed), including
  /// occasional cute double-blinks, using wall-clock time whenever any animation ticks.
  static double computeNaturalBlink(int nowMs) {
    final cycle = nowMs ~/ 4200;
    final elapsed = nowMs % 4200;
    if (elapsed < 150) {
      return sin((elapsed / 150.0) * pi);
    }
    if (cycle % 3 == 0 && elapsed >= 230 && elapsed < 370) {
      return sin(((elapsed - 230) / 140.0) * pi);
    }
    return 0.0;
  }

  /// Computes an organic curious Shiba head-tilt angle when standing idle.
  static double computeCuriousHeadTilt(int nowMs) {
    final cycle = nowMs ~/ 7400;
    final elapsed = nowMs % 7400;
    if (elapsed < 1200) {
      final dir = (cycle % 2 == 0) ? 1.0 : -1.0;
      // Smooth ease-in, hold, ease-out
      double env;
      if (elapsed < 260) {
        env = sin((elapsed / 260.0) * (pi / 2));
      } else if (elapsed < 940) {
        env = 1.0;
      } else {
        env = cos(((elapsed - 940) / 260.0) * (pi / 2));
      }
      return dir * 0.072 * env;
    }
    return 0.0;
  }

  /// Periodic playful wag burst when idle so the dog occasionally wags its tail cheerfully.
  static bool isPeriodicWagActive(int nowMs) {
    final elapsed = nowMs % 9500;
    return elapsed > 2200 && elapsed < 3800;
  }

  /// Renders the Shiba + animated face/FX (blinking, ^ ^ happy eyes, blush, tail wag,
  /// paw dust puffs) + custom per-stage calibrated Collar & swinging charm!
  static Widget buildDressedShiba({
    required String stage,
    required bool isSick,
    required List<String> equippedAccessories,
    double size = 100,
    bool isSleeping = false,
    bool isHappy = false,
    bool isWalking = false,
    bool isWagging = false,
    double collarSwingAngle = 0.0,
    double motionPhase = 0.0,
  }) {
    final scaleFactor = size / 100.0;
    final assetPath = getImageAssetForStage(stage);
    final rig = PetStageRig.forAsset(assetPath);
    final collar = (stage == 'egg')
        ? null
        : PetCollars.resolveActiveCollar(equippedAccessories);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final blink = (isSleeping || isHappy) ? 0.0 : computeNaturalBlink(nowMs);
    final shimmerPhase = (nowMs % 2200) / 2200.0;
    final effectiveWag =
        !isSick &&
        !isSleeping &&
        (isWagging || isHappy || isWalking || isPeriodicWagActive(nowMs));
    final wagPhase = isWalking ? motionPhase : ((nowMs % 600) / 600.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
          if (rig != null)
            Positioned.fill(
              child: CustomPaint(
                painter: PetFaceAndFxPainter(
                  rig: rig,
                  blinkAmount: blink,
                  isHappy: isHappy && !isSick,
                  isSleeping: isSleeping,
                  isWagging: effectiveWag,
                  isWalking: isWalking,
                  motionPhase: wagPhase,
                ),
              ),
            ),
          if (rig != null && collar != null)
            Positioned.fill(
              child: CustomPaint(
                painter: PetCollarPainter(
                  rig: rig,
                  collar: collar,
                  swingAngle: collarSwingAngle,
                  shimmerPhase: shimmerPhase,
                ),
              ),
            ),
          if (isSick)
            Positioned(
              top: -12 * scaleFactor,
              right: -10 * scaleFactor,
              child: Text("🤢", style: TextStyle(fontSize: 26 * scaleFactor)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[
      shakeController,
      walkController,
      boopController,
      trickController,
      ?idleController,
      ?reactionController,
    ];

    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, child) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        double shakeX = 0;
        double walkY = 0;
        double waddleAngle = 0;
        double breatheScaleX = 1.0;
        double breatheScaleY = 1.0;
        double collarSwing = 0.0;

        // Shake (stroke / egg wobble)
        if (shakeController.isAnimating) {
          shakeX = sin(shakeController.value * pi * 4) * 6;
          waddleAngle = sin(shakeController.value * pi * 4) * 0.08;
          collarSwing += sin(shakeController.value * pi * 6) * 0.28;
        }

        // Walking / Chasing bounce & waddle
        if (walkController.isAnimating) {
          final t = walkController.value;
          walkY = -sin(t * pi).abs() * (isChasing ? 16 : 11);
          waddleAngle += cos(t * pi) * (isChasing ? 0.11 : 0.07);
          breatheScaleY = 1.0 + (sin(t * pi).abs() * 0.06) - 0.02;
          breatheScaleX = 1.0 - (sin(t * pi).abs() * 0.04) + 0.02;
          collarSwing += sin(t * pi * 2) * (isChasing ? 0.32 : 0.20);
        } else if (idleController != null) {
          // Continuous lively idle breathing + curious head tilt + gentle charm sway
          final idleT = idleController!.value;
          final breathWave = sin(idleT * pi * 2);
          breatheScaleY = isSleeping
              ? 1.0 + (breathWave * 0.020)
              : 1.0 + (breathWave * 0.038);
          breatheScaleX = isSleeping
              ? 1.0 - (breathWave * 0.014)
              : 1.0 - (breathWave * 0.024);
          walkY = isSleeping ? 0.0 : -breathWave.abs() * 2.5;
          if (stage != 'egg' && !isSick && !isSleeping) {
            final curiousTilt = computeCuriousHeadTilt(nowMs);
            waddleAngle += (sin(idleT * pi * 2) * 0.026) + curiousTilt;
            collarSwing += (cos(idleT * pi * 2) * 0.08) - (curiousTilt * 1.4);
          }
        }

        double baseScale = _getScaleForStage();
        double boopFactor = 1.0 - (boopController.value * 0.16);
        if (boopController.isAnimating) {
          collarSwing += sin(boopController.value * pi * 2) * 0.25;
        }

        // Trick animations
        double trickRotation = 0;
        double trickYOffset = 0;
        double trickXOffset = 0;

        if (currentTrick == 'Spin') {
          trickRotation = trickController.value * pi * 2;
          trickYOffset = sin(trickController.value * pi) * -20;
        } else if (currentTrick == 'Jump') {
          trickYOffset = sin(trickController.value * pi) * -60;
        } else if (currentTrick == 'Roll Over') {
          trickRotation = trickController.value * pi * 2;
          trickYOffset = sin(trickController.value * pi) * 20;
        } else if (currentTrick == 'Backflip') {
          trickRotation = trickController.value * pi * 2 * -1;
          trickYOffset = sin(trickController.value * pi) * -85;
        } else if (currentTrick == 'Moonwalk') {
          double direction = facingRight ? -1.0 : 1.0;
          double slideDist = sin(trickController.value * pi) * 65;
          trickXOffset = slideDist * direction;
        }

        final isHappyNow =
            !isSick &&
            !isSleeping &&
            (shakeController.isAnimating ||
                boopController.isAnimating ||
                trickController.isAnimating ||
                (reactionController != null &&
                    reactionController!.isAnimating) ||
                emotion == '❤️');

        final totalLift = (walkY + trickYOffset).clamp(-100.0, 20.0);
        final shadowScale = (1.0 - (totalLift.abs() / 120.0)).clamp(0.45, 1.0);
        final activeCollar = PetCollars.resolveActiveCollar(
          equippedAccessories,
        );
        final effectivePerspectiveScale =
            (isCloseUp && identical(perspective, PetDepthPerspective.neutral))
            ? 2.25
            : perspective.scale;

        return Transform.translate(
          offset: Offset(shakeX + trickXOffset, 0),
          child: Transform.scale(
            alignment: Alignment.bottomCenter,
            scale: effectivePerspectiveScale * baseScale * boopFactor,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => onBoopDown(),
                onTapUp: (_) => onBoopUp(),
                onTapCancel: onBoopCancel,
                onHorizontalDragUpdate: (details) {
                  if (details.primaryDelta != null &&
                      details.primaryDelta!.abs() > 4.0) {
                    onStroke();
                  }
                },
                child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Dynamic ground shadow beneath paws (intensifies up close, softens in distance)
                  Positioned(
                    bottom: 2,
                    child: Transform.scale(
                      scaleX: shadowScale * breatheScaleX,
                      scaleY: shadowScale,
                      child: Container(
                        width: 68,
                        height: 13,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha:
                                (0.22 *
                                        shadowScale *
                                        perspective.shadowIntensity)
                                    .clamp(0.05, 0.36),
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                  ),

                  // Animated Shiba body with optical Depth-of-Field applied cleanly to the sprite
                  Transform.translate(
                    offset: Offset(0, walkY + trickYOffset),
                    child: Transform.rotate(
                      angle: waddleAngle + trickRotation,
                      child: Transform.scale(
                        scaleX: breatheScaleX,
                        scaleY: breatheScaleY,
                        alignment: Alignment.bottomCenter,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(facingRight ? 0 : pi),
                          child: perspective.applyOpticalDoF(
                            buildDressedShiba(
                              stage: stage,
                              isSick: isSick,
                              equippedAccessories: equippedAccessories,
                              size: 100,
                              isSleeping: isSleeping || emotion == '💤',
                              isHappy: isHappyNow,
                              isWalking: walkController.isAnimating,
                              isWagging: isChasing || isHappyNow,
                              collarSwingAngle: collarSwing,
                              motionPhase: walkController.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Name, Stage & Equipped Collar Indicator (kept outside ImageFiltered so it is never clipped)
                  if (emotion.isNotEmpty || stage != 'egg')
                    Positioned(
                      top: -46 + (walkY * 0.4),
                      child: Opacity(
                        opacity: perspective.opacity,
                        child: Column(
                          children: [
                            if (stage != 'egg')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.58),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: (activeCollar?.primaryColor ??
                                            Colors.amber)
                                        .withValues(alpha: 0.75),
                                    width: 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (activeCollar != null) ...[
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: activeCollar.primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white70,
                                                width: 0.8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          petName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      stage.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (emotion.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  emotion,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Floating Reaction Particle (❤️, 🍖, ✨, 🎾)
                  if (reactionEmoji.isNotEmpty &&
                      reactionController != null &&
                      reactionController!.isAnimating)
                    Positioned(
                      top: -55 - (reactionController!.value * 45),
                      child: Opacity(
                        opacity: (1.0 - reactionController!.value).clamp(
                          0.0,
                          1.0,
                        ),
                        child: Transform.scale(
                          scale: 0.8 + (reactionController!.value * 0.6),
                          child: Text(
                            reactionEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),

                  // Boop Prompt Badge once the Shiba has arrived up close
                  if (isCloseUp &&
                      !isChasing &&
                      effectivePerspectiveScale >= 1.90)
                    Positioned(
                      top: -28,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Text(
                          "🐾 Tap to Boop! (+0.004 DOGE)",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}
