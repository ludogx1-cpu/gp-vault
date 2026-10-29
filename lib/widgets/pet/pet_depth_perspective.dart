import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Unified 2.5D camera perspective & optical Depth-of-Field (DoF) model
/// for the wandering Shiba, fetch ball, poos, and speech bubbles.
class PetDepthPerspective {
  /// Normalized depth `0.0` (far horizon / background) -> `1.0` (close foreground).
  final double depth;

  /// Perspective size multiplier (`0.50x` far background -> `1.48x` foreground,
  /// smoothly expanding up to `2.25x` during a close-up camera Boop).
  final double scale;

  /// Optical Depth-of-Field Gaussian blur sigma (`0.0` in sharp focus,
  /// ramping smoothly up to `1.65`–`2.25` in the far background).
  final double blurSigma;

  /// Subtle atmospheric distance opacity (`0.82` at far horizon -> `1.0` in focus).
  final double opacity;

  /// Ground contact shadow intensity multiplier (`0.58` far -> `1.20` close).
  final double shadowIntensity;

  const PetDepthPerspective({
    required this.depth,
    required this.scale,
    required this.blurSigma,
    required this.opacity,
    required this.shadowIntensity,
  });

  static const PetDepthPerspective neutral = PetDepthPerspective(
    depth: 0.55,
    scale: 1.0,
    blurSigma: 0.0,
    opacity: 1.0,
    shadowIntensity: 1.0,
  );

  static double minYForScreen(double screenHeight) => 55.0;

  static double maxYForScreen(double screenHeight) {
    final safeHeight = max(360.0, screenHeight);
    return max(minYForScreen(safeHeight) + 140.0, safeHeight - 150.0);
  }

  /// Computes 2.5D perspective scale and optical DoF blur from a screen Y coordinate.
  factory PetDepthPerspective.fromScreenY({
    required double y,
    required double screenHeight,
    double closeUpFactor = 0.0,
    double cameraCloseUpFactor = 0.0,
  }) {
    final minY = minYForScreen(screenHeight);
    final maxY = maxYForScreen(screenHeight);
    final z = ((y - minY) / (maxY - minY)).clamp(0.0, 1.0);
    final clampedCloseUp = closeUpFactor.clamp(0.0, 1.0);
    final clampedCamRack = cameraCloseUpFactor.clamp(0.0, 1.0);

    // Non-linear perspective curve:
    // z = 0.0 (far background)  -> 0.50x
    // z = 0.5 (midground)       -> 0.94x
    // z = 1.0 (close foreground)-> 1.48x
    final basePerspectiveScale = 0.50 + 0.98 * pow(z, 1.15).toDouble();
    final effectiveScale =
        lerpDouble(basePerspectiveScale, 2.25, clampedCloseUp) ??
        basePerspectiveScale;

    // Optical Depth-of-Field (DoF):
    // Foreground & midground (z >= 0.44) stay razor-sharp (0.0 blur).
    // Wandering deeper into the background (z < 0.44) smoothly defocuses up to 1.65px.
    // When the camera racks focus onto a close-up Boop, background objects defocus
    // across a wider plane (z < 0.76, up to 2.25px) like a shallow-aperture lens.
    final focusPlane = lerpDouble(0.44, 0.76, clampedCamRack) ?? 0.44;
    final maxBlur = lerpDouble(1.65, 2.25, clampedCamRack) ?? 1.65;

    double sigma = 0.0;
    if (z < focusPlane) {
      final t = ((focusPlane - z) / focusPlane).clamp(0.0, 1.0);
      sigma = maxBlur * (t * t * 0.65 + t * 0.35);
    }
    // Subject leaning into the lens pulls cleanly into sharp focus
    sigma *= (1.0 - clampedCloseUp);

    double alpha = 1.0;
    if (z < 0.48) {
      final t = ((0.48 - z) / 0.48).clamp(0.0, 1.0);
      alpha = (1.0 - t * 0.18 * (1.0 - clampedCloseUp)).clamp(0.82, 1.0);
    }

    final baseShadow = 0.58 + 0.55 * z;
    final shadow =
        lerpDouble(baseShadow, 1.22, clampedCloseUp) ?? baseShadow;

    return PetDepthPerspective(
      depth: lerpDouble(z, 1.0, clampedCloseUp) ?? z,
      scale: effectiveScale,
      blurSigma: sigma,
      opacity: alpha,
      shadowIntensity: shadow,
    );
  }

  /// Wraps [child] with universal GPU-compatible optical DoF blur and atmospheric
  /// distance opacity. Skips offscreen layers completely when in sharp focus.
  Widget applyOpticalDoF(Widget child) {
    Widget current = child;
    if (blurSigma > 0.08) {
      current = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: current,
      );
    }
    if (opacity < 0.995) {
      current = Opacity(opacity: opacity, child: current);
    }
    return current;
  }
}
