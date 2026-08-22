import 'package:flutter/material.dart';
import 'dart:math';

class PetSpriteWidget extends StatelessWidget {
  final String stage;
  final String petName;
  final bool isSick;
  final bool facingRight;
  final List<String> equippedAccessories;
  final String emotion;
  final bool isCloseUp;
  final bool isWalkAnimating;
  final bool isChasing;
  
  final AnimationController shakeController;
  final AnimationController walkController;
  final AnimationController boopController;
  final AnimationController trickController;
  
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
    required this.isCloseUp,
    required this.isWalkAnimating,
    required this.isChasing,
    required this.shakeController,
    required this.walkController,
    required this.boopController,
    required this.trickController,
    required this.currentTrick,
    required this.onBoopDown,
    required this.onBoopUp,
    required this.onBoopCancel,
    required this.onStroke,
  });

  String _getImageAsset() {
    switch (stage) {
      case 'baby':
        return 'assets/shiba_baby.png';
      case 'toddler':
        return 'assets/shiba_baby.png'; 
      case 'puppy':
        return 'assets/shiba_teen.png'; 
      case 'child':
        return 'assets/shiba_child.png';
      case 'teen':
        return 'assets/shiba_puppy.png'; 
      case 'young_adult':
        return 'assets/shiba_young_adult.png';
      case 'adult':
        return 'assets/shiba_adult.png';
      case 'old_dog':
        return 'assets/old_dog.png';
      default:
        return 'assets/shiba_baby.png';
    }
  }

  double _getScaleForStage() {
    switch (stage) {
      case 'baby': return 0.75; 
      case 'toddler': return 0.85; 
      case 'puppy': return 0.95; 
      case 'child': return 1.0; 
      case 'teen': return 1.1; 
      case 'young_adult': return 1.2; 
      case 'adult': return 1.4; 
      case 'old_dog': return 1.5;
      default: return 0.7;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        shakeController,
        walkController,
        boopController,
      ]),
      builder: (context, child) {
        double eggOffset = 0;
        double walkOffset = 0;

        if (stage == 'baby') {
          eggOffset = sin(shakeController.value * pi * 4) * 10;
        } else if (walkController.isAnimating) {
          walkOffset = sin(walkController.value * pi) * -10;
        }

        double baseScale = _getScaleForStage();
        double boopScale = baseScale - (boopController.value * 0.15 * baseScale);

        return Transform.translate(
          offset: Offset(eggOffset, walkOffset),
          child: AnimatedScale(
            scale: isCloseUp ? 2.5 : 1.0, 
            duration: const Duration(seconds: 4),
            curve: Curves.easeInOut,
            child: Transform.scale(
              scale: boopScale,
              child: AnimatedBuilder(
                animation: trickController,
                builder: (context, child) {
                  double trickRotation = 0;
                  double trickScale = 1.0;
                  double trickYOffset = 0;

                  if (currentTrick == 'Spin') {
                    trickRotation = trickController.value * pi * 2;
                  } else if (currentTrick == 'Jump') {
                    trickYOffset = sin(trickController.value * pi) * -50;
                  } else if (currentTrick == 'Roll Over') {
                    trickRotation = trickController.value * pi * 2;
                    trickYOffset = sin(trickController.value * pi) * 20; 
                  } else if (currentTrick == 'Backflip') {
                    trickRotation = trickController.value * pi * 2 * -1; 
                    trickYOffset = sin(trickController.value * pi) * -80; 
                  }

                  double trickXOffset = 0;
                  if (currentTrick == 'Moonwalk') {
                    double direction = facingRight ? -1.0 : 1.0;
                    double slideDist = sin(trickController.value * pi) * 60;
                    trickXOffset = slideDist * direction;
                  }

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.translationValues(
                          trickXOffset,
                          trickYOffset,
                          0.0,
                        ) *
                        Matrix4.rotationZ(trickRotation) *
                        Matrix4.diagonal3Values(
                          trickScale,
                          trickScale,
                          1.0,
                        ),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTapDown: (_) => onBoopDown(),
                  onTapUp: (_) => onBoopUp(),
                  onTapCancel: onBoopCancel,
                  onPanUpdate: (details) => onStroke(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(facingRight ? pi : 0), 
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.asset(_getImageAsset()),
                            ),
                            if (isSick)
                              const Positioned(
                                top: -20,
                                right: -20,
                                child: Text("🤢", style: TextStyle(fontSize: 32)),
                              ),
                            if (equippedAccessories.contains('top_hat'))
                              Positioned(
                                top: -15,
                                left: 30,
                                child: Image.asset('assets/shiba_top_hat.png', width: 40),
                              ),
                            if (equippedAccessories.contains('crown'))
                              Positioned(
                                top: -10,
                                left: 25,
                                child: Image.asset('assets/shiba_crown.png', width: 50),
                              ),
                            if (equippedAccessories.contains('sunglasses'))
                              Positioned(
                                top: 25,
                                left: 20,
                                child: Image.asset('assets/shiba_sunglasses.png', width: 45),
                              ),
                            if (equippedAccessories.contains('gold_chain'))
                              Positioned(
                                top: 55,
                                left: 25,
                                child: Image.asset('assets/shiba_gold_chain.png', width: 50),
                              ),
                            if (equippedAccessories.contains('coat_basic'))
                              Positioned(
                                top: 20,
                                left: 10,
                                child: Image.asset('assets/shiba_coat_basic.png', width: 80),
                              ),
                            if (equippedAccessories.contains('coat_rain'))
                              Positioned(
                                top: 20,
                                left: 10,
                                child: Image.asset('assets/shiba_coat_rain.png', width: 80),
                              ),
                            if (equippedAccessories.contains('coat_winter'))
                              Positioned(
                                top: 20,
                                left: 10,
                                child: Image.asset('assets/shiba_coat_winter.png', width: 80),
                              ),
                            if (equippedAccessories.contains('coat_luxury'))
                              Positioned(
                                top: 20,
                                left: 10,
                                child: Image.asset('assets/shiba_coat_luxury.png', width: 80),
                              ),
                            if (equippedAccessories.contains('diamond_watch'))
                              Positioned(
                                top: 55,
                                left: 25,
                                child: Image.asset('assets/shiba_diamond_watch.png', width: 50),
                              ),
                          ],
                        ),
                      ),
                      if (emotion.isNotEmpty || stage != 'egg')
                        Positioned(
                          top: -45,
                          child: Column(
                            children: [
                              if (stage != 'egg')
                                Column(
                                  children: [
                                    Text(
                                      petName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                        shadows: [
                                          Shadow(color: Colors.black, blurRadius: 2),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      stage.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                        shadows: [
                                          Shadow(color: Colors.black, blurRadius: 2),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              if (emotion.isNotEmpty)
                                AnimatedOpacity(
                                  opacity: emotion.isNotEmpty ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 500),
                                  child: Text(emotion, style: const TextStyle(fontSize: 24)),
                                ),
                            ],
                          ),
                        ),
                      if (isCloseUp && !walkController.isAnimating && !isChasing)
                        const Positioned(
                          top: -25,
                          child: Text(
                            "Boop!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                              shadows: [Shadow(color: Colors.white, blurRadius: 4)],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
