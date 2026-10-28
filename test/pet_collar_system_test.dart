import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_faucet/widgets/pet/pet_collar_painter.dart';
import 'package:gp_faucet/widgets/pet/pet_depth_perspective.dart';
import 'package:gp_faucet/widgets/pet/pet_sprite_widget.dart';
import 'package:gp_faucet/widgets/pet/pet_tabs_widget.dart';

void main() {
  group('PetCollars & PetStageRig calibration', () {
    test('defines 9 coloured collars and migrates legacy accessory IDs', () {
      expect(PetCollars.all.length, 9);
      expect(PetCollars.normalizeId('top_hat'), 'collar_red');
      expect(PetCollars.normalizeId('crown'), 'collar_diamond');
      expect(
        PetCollars.normalizeList(['top_hat', 'collar_red', 'coat_luxury']),
        ['collar_red', 'collar_gold'],
      );

      final resolved = PetCollars.resolveActiveCollar(['crown']);
      expect(resolved, isNotNull);
      expect(resolved!.id, 'collar_diamond');
      expect(resolved.bonusPercent, 100);
    });

    test('every hatched growth stage maps to a calibrated PetStageRig', () {
      const stages = [
        'baby',
        'toddler',
        'puppy',
        'child',
        'teen',
        'young_adult',
        'adult',
        'old_dog',
      ];
      for (final stage in stages) {
        final asset = PetSpriteWidget.getImageAssetForStage(stage);
        final rig = PetStageRig.forAsset(asset);
        expect(
          rig,
          isNotNull,
          reason: 'Missing PetStageRig for stage $stage ($asset)',
        );
      }
      expect(
        PetStageRig.forAsset(PetSpriteWidget.getImageAssetForStage('egg')),
        isNull,
      );
    });

    test('2.5D PetDepthPerspective scales & applies optical DoF by depth', () {
      const screenH = 800.0;
      final farBg = PetDepthPerspective.fromScreenY(
        y: PetDepthPerspective.minYForScreen(screenH),
        screenHeight: screenH,
      );
      final midGround = PetDepthPerspective.fromScreenY(
        y: 380.0,
        screenHeight: screenH,
      );
      final nearFg = PetDepthPerspective.fromScreenY(
        y: PetDepthPerspective.maxYForScreen(screenH),
        screenHeight: screenH,
      );
      final closeUpBoop = PetDepthPerspective.fromScreenY(
        y: PetDepthPerspective.maxYForScreen(screenH),
        screenHeight: screenH,
        closeUpFactor: 1.0,
      );

      // Scale grows progressively from far background -> midground -> foreground -> close-up boop
      expect(farBg.scale, closeTo(0.50, 0.02));
      expect(midGround.scale, greaterThan(farBg.scale));
      expect(nearFg.scale, closeTo(1.48, 0.02));
      expect(closeUpBoop.scale, closeTo(2.25, 0.02));

      // Far background has optical DoF blur & atmospheric fade; foreground & boop are razor sharp
      expect(farBg.blurSigma, greaterThan(1.2));
      expect(farBg.opacity, lessThan(0.90));
      expect(midGround.blurSigma, equals(0.0));
      expect(nearFg.blurSigma, equals(0.0));
      expect(closeUpBoop.blurSigma, equals(0.0));

      // Camera rack-focus during close-up deepens background bokeh on distant items
      final rackedBg = PetDepthPerspective.fromScreenY(
        y: 220.0,
        screenHeight: screenH,
        cameraCloseUpFactor: 1.0,
      );
      final normalBg = PetDepthPerspective.fromScreenY(
        y: 220.0,
        screenHeight: screenH,
        cameraCloseUpFactor: 0.0,
      );
      expect(rackedBg.blurSigma, greaterThan(normalBg.blurSigma));
    });
  });

  testWidgets('PetTabsWidget displays Collars tab and handles equip/buy', (
    tester,
  ) async {
    String? equippedId;
    bool? equippedFlag;
    String? boughtId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetTabsWidget(
            data: const PetTabsData(
              stage: 'puppy',
              isDark: true,
              ownedAccessories: ['collar_red'],
              equippedAccessories: ['collar_red'],
              ownedTricks: [],
              ownedConsumables: {},
              ownedBalls: ['white'],
              equippedBall: 'white',
            ),
            callbacks: PetTabsCallbacks(
              onEquipAccessory: (id, equip) {
                equippedId = id;
                equippedFlag = equip;
              },
              onBuyAccessory: (id, price) {
                boughtId = id;
              },
              onUseConsumable: (_) {},
              onBuyConsumable: (_, _) {},
              onEquipBall: (_) {},
              onBuyBall: (_, _) {},
              onPerformTrick: (_) {},
              onBuyTrick: (_, _) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Collars'), findsOneWidget);
    await tester.tap(find.text('Collars'));
    await tester.pumpAndSettle();

    expect(find.text('Ruby Red Collar'), findsOneWidget);
    expect(find.text('Unequip'), findsOneWidget);

    await tester.tap(find.text('Unequip'));
    expect(equippedId, 'collar_red');
    expect(equippedFlag, isFalse);

    expect(find.text('Sunset Orange Collar'), findsOneWidget);
    await tester.tap(find.text('Buy').first);
    expect(boughtId, 'collar_orange');
  });
}
