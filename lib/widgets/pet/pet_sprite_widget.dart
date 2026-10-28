import 'package:flutter/material.dart';
import 'dart:math';

class PetSpriteWidget extends StatelessWidget {
  final String stage;
  final String petName;
  final bool isSick;
  final bool facingRight;
  final List<String> equippedAccessories;
  final String emotion;
  final String reactionEmoji;
  final bool isCloseUp;
  final bool isWalkAnimating;
  final bool isChasing;

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
    required this.facingRight,
    required this.equippedAccessories,
    required this.emotion,
    this.reactionEmoji = '',
    required this.isCloseUp,
    required this.isWalkAnimating,
    required this.isChasing,
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
        return 'assets/shiba_baby.png';
      case 'puppy':
        return 'assets/shiba_puppy.png';
      case 'child':
        return 'assets/shiba_child.png';
      case 'teen':
        return 'assets/shiba_teen.png';
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

  double _getScaleForStage() {
    switch (stage) {
      case 'egg':
        return 0.7;
      case 'baby':
        return 0.75;
      case 'toddler':
        return 0.85;
      case 'puppy':
        return 0.95;
      case 'child':
        return 1.0;
      case 'teen':
        return 1.1;
      case 'young_adult':
        return 1.2;
      case 'adult':
        return 1.35;
      case 'old_dog':
        return 1.45;
      default:
        return 0.85;
    }
  }

  /// Renders the Shiba + equipped accessories stack so both the wandering
  /// overlay and the Pet Care dashboard card can share the exact same dressed-up Shiba.
  static Widget buildDressedShiba({
    required String stage,
    required bool isSick,
    required List<String> equippedAccessories,
    double size = 100,
  }) {
    final scaleFactor = size / 100.0;
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
              getImageAssetForStage(stage),
              fit: BoxFit.contain,
            ),
          ),
          if (isSick)
            Positioned(
              top: -20 * scaleFactor,
              right: -20 * scaleFactor,
              child: Text("🤢", style: TextStyle(fontSize: 32 * scaleFactor)),
            ),
          if (equippedAccessories.contains('coat_basic'))
            Positioned(
              top: 20 * scaleFactor,
              left: 10 * scaleFactor,
              child: Image.asset(
                'assets/shiba_coat_basic.png',
                width: 80 * scaleFactor,
              ),
            ),
          if (equippedAccessories.contains('coat_rain'))
            Positioned(
              top: 20 * scaleFactor,
              left: 10 * scaleFactor,
              child: Image.asset(
                'assets/shiba_coat_rain.png',
                width: 80 * scaleFactor,
              ),
            ),
          if (equippedAccessories.contains('coat_winter'))
            Positioned(
              top: 20 * scaleFactor,
              left: 10 * scaleFactor,
              child: Image.asset(
                'assets/shiba_coat_winter.png',
                width: 80 * scaleFactor,
              ),
            ),
          if (equippedAccessories.contains('coat_luxury'))
            Positioned(
              top: 20 * scaleFactor,
              left: 10 * scaleFactor,
              child: Image.asset(
                'assets/shiba_coat_luxury.png',
                width: 80 * scaleFactor,
              ),
            ),
          if (equippedAccessories.contains('gold_chain'))
            Positioned(
              top: 55 * scaleFactor,
              left: 25 * scaleFactor,
              child: Image.asset(
                'assets/shiba_gold_chain.png',
                width: 50 * scaleFactor,
              ),
            ),
          if (equippedAccessories.contains('diamond_watch'))
            Positioned(
              top: 55 * scaleFactor,
              left: 25 * scaleFactor,
              child: Image.asset(
                'assets/shiba_diamond_watch.png',
                width: 50 * scaleFactor,
              ),
            ),
          if (equippedAccessories.contains('sunglasses'))
            Positioned(
              top: 25 * scaleFactor,
              left: 20 * scaleFactor,
              child: Image.asset(
                'assets/shiba_sunglasses.png',
                width: 45 * scaleFactor,
              ),
            ),
          if (equippedAccessories.contains('top_hat'))
            Positioned(
              top: -15 * scaleFactor,
              left: 30 * scaleFactor,
              child: Image.asset(
                'assets/shiba_top_hat.png',
                width: 40 * scaleFactor,
              ),
            ),
          if (equippedAccessories.contains('crown'))
            Positioned(
              top: -10 * scaleFactor,
              left: 25 * scaleFactor,
              child: Image.asset(
                'assets/shiba_crown.png',
                width: 50 * scaleFactor,
              ),
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
        double shakeX = 0;
        double walkY = 0;
        double waddleAngle = 0;
        double breatheScaleX = 1.0;
        double breatheScaleY = 1.0;

        // Shake (stroke / egg wobble)
        if (shakeController.isAnimating) {
          shakeX = sin(shakeController.value * pi * 4) * 6;
          waddleAngle = sin(shakeController.value * pi * 4) * 0.08;
        }

        // Walking / Chasing bounce & waddle
        if (walkController.isAnimating) {
          final t = walkController.value;
          walkY = -sin(t * pi).abs() * (isChasing ? 16 : 11);
          waddleAngle += cos(t * pi) * (isChasing ? 0.11 : 0.07);
          // Squash & stretch at the bottom/top of the hop
          breatheScaleY = 1.0 + (sin(t * pi).abs() * 0.06) - 0.02;
          breatheScaleX = 1.0 - (sin(t * pi).abs() * 0.04) + 0.02;
        } else if (idleController != null) {
          // Continuous lively idle breathing & gentle tail/body sway
          final idleT = idleController!.value;
          final breathWave = sin(idleT * pi * 2);
          breatheScaleY = 1.0 + (breathWave * 0.038);
          breatheScaleX = 1.0 - (breathWave * 0.024);
          walkY = -breathWave.abs() * 2.5;
          if (stage != 'egg' && !isSick) {
            waddleAngle += sin(idleT * pi * 2) * 0.032;
          }
        }

        double baseScale = _getScaleForStage();
        double boopFactor = 1.0 - (boopController.value * 0.16);

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

        final totalLift = (walkY + trickYOffset).clamp(-100.0, 20.0);
        final shadowScale = (1.0 - (totalLift.abs() / 120.0)).clamp(0.45, 1.0);

        return Transform.translate(
          offset: Offset(shakeX + trickXOffset, 0),
          child: AnimatedScale(
            scale: isCloseUp ? 2.3 : 1.0,
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutBack,
            child: Transform.scale(
              scale: baseScale * boopFactor,
              child: GestureDetector(
                onTapDown: (_) => onBoopDown(),
                onTapUp: (_) => onBoopUp(),
                onTapCancel: onBoopCancel,
                onPanUpdate: (_) => onStroke(),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Dynamic ground shadow beneath paws
                    Positioned(
                      bottom: -4,
                      child: Transform.scale(
                        scaleX: shadowScale * breatheScaleX,
                        scaleY: shadowScale,
                        child: Container(
                          width: 68,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.22 * shadowScale,
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ),

                    // Animated Shiba body (translation + rotation + squash/stretch)
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
                            transform: Matrix4.rotationY(facingRight ? pi : 0),
                            child: buildDressedShiba(
                              stage: stage,
                              isSick: isSick,
                              equippedAccessories: equippedAccessories,
                              size: 100,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Name, Stage & Mood Indicator
                    if (emotion.isNotEmpty || stage != 'egg')
                      Positioned(
                        top: -48 + (walkY * 0.4),
                        child: Column(
                          children: [
                            if (stage != 'egg')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.6),
                                    width: 0.8,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      petName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
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

                    // Boop Prompt Badge
                    if (isCloseUp && !walkController.isAnimating && !isChasing)
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
