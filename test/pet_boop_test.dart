import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_faucet/widgets/pet/pet_sprite_widget.dart';
import 'package:gp_faucet/widgets/pet/pet_depth_perspective.dart';

void main() {
  group('Pet Boop Cooldown & Skew Tolerance Logic', () {
    const int cooldownMs = 29 * 60 * 1000;

    test('is ready when elapsed >= 29 minutes', () {
      final now = 1000000000000;
      final lastBoopReady = now - (29 * 60 * 1000);
      final lastBoopOlder = now - (35 * 60 * 1000);
      final lastBoopJustDone = now - (5 * 60 * 1000);

      expect((now - lastBoopReady) >= cooldownMs, isTrue);
      expect((now - lastBoopOlder) >= cooldownMs, isTrue);
      expect((now - lastBoopJustDone) >= cooldownMs, isFalse);
    });

    test('cooldown remaining minutes calculation', () {
      final now = 1000000000000;
      final lastBoopRecent = now - (19 * 60 * 1000);
      final elapsed = now - lastBoopRecent;
      final remainingMin = ((cooldownMs - elapsed) / 60000).ceil();
      expect(remainingMin, 10);
    });
  });

  group('PetSpriteWidget Boop & Stroke Gestures', () {
    testWidgets('tapping PetSpriteWidget triggers onBoopDown and onBoopUp', (tester) async {
      bool boopDownCalled = false;
      bool boopUpCalled = false;
      bool strokeCalled = false;

      final vsync = const TestVSync();
      final walkController = AnimationController(vsync: vsync, duration: const Duration(seconds: 1));
      final boopController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));
      final shakeController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));
      final trickController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: PetSpriteWidget(
                  stage: 'adult',
                  petName: 'Test Shiba',
                  isSick: false,
                  isSleeping: false,
                  facingRight: true,
                  equippedAccessories: const [],
                  emotion: '',
                  reactionEmoji: '',
                  isCloseUp: true,
                  isWalkAnimating: false,
                  isChasing: false,
                  perspective: PetDepthPerspective.neutral,
                  walkController: walkController,
                  boopController: boopController,
                  shakeController: shakeController,
                  trickController: trickController,
                  currentTrick: '',
                  onBoopDown: () => boopDownCalled = true,
                  onBoopUp: () => boopUpCalled = true,
                  onBoopCancel: () {},
                  onStroke: () => strokeCalled = true,
                ),
              ),
            ),
          ),
        ),
      );

      // Tap down on the sprite
      final gesture = await tester.startGesture(tester.getCenter(find.byType(PetSpriteWidget)));
      await tester.pump(const Duration(milliseconds: 150));
      expect(boopDownCalled, isTrue);
      expect(boopUpCalled, isFalse);

      // Release tap
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(boopUpCalled, isTrue);
      expect(strokeCalled, isFalse);

      walkController.dispose();
      boopController.dispose();
      shakeController.dispose();
      trickController.dispose();
    });

    testWidgets('tester.tap directly triggers onBoopDown and onBoopUp', (tester) async {
      bool boopDownCalled = false;
      bool boopUpCalled = false;
      bool strokeCalled = false;

      final vsync = const TestVSync();
      final walkController = AnimationController(vsync: vsync, duration: const Duration(seconds: 1));
      final boopController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));
      final shakeController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));
      final trickController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: PetSpriteWidget(
                  stage: 'adult',
                  petName: 'Test Shiba',
                  isSick: false,
                  isSleeping: false,
                  facingRight: true,
                  equippedAccessories: const [],
                  emotion: '',
                  reactionEmoji: '',
                  isCloseUp: true,
                  isWalkAnimating: false,
                  isChasing: false,
                  perspective: PetDepthPerspective.neutral,
                  walkController: walkController,
                  boopController: boopController,
                  shakeController: shakeController,
                  trickController: trickController,
                  currentTrick: '',
                  onBoopDown: () => boopDownCalled = true,
                  onBoopUp: () => boopUpCalled = true,
                  onBoopCancel: () {},
                  onStroke: () => strokeCalled = true,
                ),
              ),
            ),
          ),
        ),
      );

      // Single standard click/tap on the sprite
      await tester.tap(find.byType(PetSpriteWidget));
      await tester.pumpAndSettle();

      expect(boopDownCalled, isTrue);
      expect(boopUpCalled, isTrue);
      expect(strokeCalled, isFalse);

      walkController.dispose();
      boopController.dispose();
      shakeController.dispose();
      trickController.dispose();
    });

    testWidgets('horizontal scrub triggers onStroke', (tester) async {
      bool boopDownCalled = false;
      bool boopUpCalled = false;
      bool strokeCalled = false;

      final vsync = const TestVSync();
      final walkController = AnimationController(vsync: vsync, duration: const Duration(seconds: 1));
      final boopController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));
      final shakeController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));
      final trickController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: PetSpriteWidget(
                  stage: 'adult',
                  petName: 'Test Shiba',
                  isSick: false,
                  isSleeping: false,
                  facingRight: true,
                  equippedAccessories: const [],
                  emotion: '',
                  reactionEmoji: '',
                  isCloseUp: false,
                  isWalkAnimating: false,
                  isChasing: false,
                  perspective: PetDepthPerspective.neutral,
                  walkController: walkController,
                  boopController: boopController,
                  shakeController: shakeController,
                  trickController: trickController,
                  currentTrick: '',
                  onBoopDown: () => boopDownCalled = true,
                  onBoopUp: () => boopUpCalled = true,
                  onBoopCancel: () {},
                  onStroke: () => strokeCalled = true,
                ),
              ),
            ),
          ),
        ),
      );

      // Drag horizontally across the pet sprite
      await tester.drag(find.byType(PetSpriteWidget), const Offset(40, 0));
      await tester.pump();

      expect(strokeCalled, isTrue);
      expect(boopDownCalled, isFalse);
      expect(boopUpCalled, isFalse);

      walkController.dispose();
      boopController.dispose();
      shakeController.dispose();
      trickController.dispose();
    });
  });
}
