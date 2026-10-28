import 'dart:math';
import 'package:flutter/material.dart';

class CollarStyle {
  final String id;
  final String name;
  final double usdtPrice;
  final int bonusPercent;
  final Color primaryColor;
  final Color highlightColor;
  final Color studColor;
  final bool hasStuds;
  final bool hasSparkles;
  final bool isDiamond;

  const CollarStyle({
    required this.id,
    required this.name,
    required this.usdtPrice,
    required this.bonusPercent,
    required this.primaryColor,
    required this.highlightColor,
    this.studColor = const Color(0xFFFFD54F),
    this.hasStuds = false,
    this.hasSparkles = false,
    this.isDiamond = false,
  });

  String get bonusLabel => '+$bonusPercent% PTC Bonus';
}

class PetCollars {
  static const Map<String, String> legacyToCollarMap = {
    'top_hat': 'collar_red',
    'coat_basic': 'collar_orange',
    'sunglasses': 'collar_yellow',
    'coat_rain': 'collar_green',
    'gold_chain': 'collar_blue',
    'coat_winter': 'collar_indigo',
    'diamond_watch': 'collar_violet',
    'coat_luxury': 'collar_gold',
    'crown': 'collar_diamond',
  };

  static const List<CollarStyle> all = [
    CollarStyle(
      id: 'collar_red',
      name: 'Ruby Red Collar',
      usdtPrice: 1.0,
      bonusPercent: 10,
      primaryColor: Color(0xFFE53935),
      highlightColor: Color(0xFFFF8A80),
    ),
    CollarStyle(
      id: 'collar_orange',
      name: 'Sunset Orange Collar',
      usdtPrice: 1.5,
      bonusPercent: 15,
      primaryColor: Color(0xFFFB8C00),
      highlightColor: Color(0xFFFFD180),
    ),
    CollarStyle(
      id: 'collar_yellow',
      name: 'Sunburst Yellow Collar',
      usdtPrice: 2.0,
      bonusPercent: 20,
      primaryColor: Color(0xFFFDD835),
      highlightColor: Color(0xFFFFFF8D),
    ),
    CollarStyle(
      id: 'collar_green',
      name: 'Emerald Green Collar',
      usdtPrice: 2.5,
      bonusPercent: 25,
      primaryColor: Color(0xFF43A047),
      highlightColor: Color(0xFFB9F6CA),
    ),
    CollarStyle(
      id: 'collar_blue',
      name: 'Sapphire Blue Collar',
      usdtPrice: 3.0,
      bonusPercent: 30,
      primaryColor: Color(0xFF1E88E5),
      highlightColor: Color(0xFF82B1FF),
    ),
    CollarStyle(
      id: 'collar_indigo',
      name: 'Royal Indigo Collar',
      usdtPrice: 4.0,
      bonusPercent: 40,
      primaryColor: Color(0xFF3949AB),
      highlightColor: Color(0xFF9FA8DA),
      studColor: Color(0xFFE0E0E0),
      hasStuds: true,
    ),
    CollarStyle(
      id: 'collar_violet',
      name: 'Amethyst Violet Collar',
      usdtPrice: 5.0,
      bonusPercent: 50,
      primaryColor: Color(0xFF8E24AA),
      highlightColor: Color(0xFFEA80FC),
      studColor: Color(0xFFFFD54F),
      hasStuds: true,
    ),
    CollarStyle(
      id: 'collar_gold',
      name: '24K Golden Paw Collar',
      usdtPrice: 7.5,
      bonusPercent: 75,
      primaryColor: Color(0xFFFFB300),
      highlightColor: Color(0xFFFFF59D),
      studColor: Color(0xFFFF5252),
      hasStuds: true,
      hasSparkles: true,
    ),
    CollarStyle(
      id: 'collar_diamond',
      name: 'Diamond Prismatic Collar',
      usdtPrice: 10.0,
      bonusPercent: 100,
      primaryColor: Color(0xFF26C6DA),
      highlightColor: Color(0xFFE0F7FA),
      studColor: Color(0xFFFFFFFF),
      hasStuds: true,
      hasSparkles: true,
      isDiamond: true,
    ),
  ];

  static String normalizeId(String id) => legacyToCollarMap[id] ?? id;

  static List<String> normalizeList(Iterable<String> ids) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in ids) {
      final mapped = normalizeId(raw);
      if (seen.add(mapped)) {
        out.add(mapped);
      }
    }
    return out;
  }

  static CollarStyle? resolveActiveCollar(Iterable<String> equippedIds) {
    CollarStyle? best;
    for (final raw in equippedIds) {
      final norm = normalizeId(raw);
      for (final c in all) {
        if (c.id == norm) {
          if (best == null || c.bonusPercent >= best.bonusPercent) {
            best = c;
          }
        }
      }
    }
    return best;
  }

  static CollarStyle byId(String id) {
    final norm = normalizeId(id);
    for (final c in all) {
      if (c.id == norm) return c;
    }
    return all.first;
  }
}

/// Exact normalized (0.0..1.0) anatomical rig for each 1024x1024 Shiba sprite.
class PetStageRig {
  final Offset collarStart;
  final Offset collarControl;
  final Offset collarEnd;
  final double collarThickness;
  final Offset tagAnchor;

  final Offset leftEye;
  final Offset rightEye;
  final double eyeRadius;
  final Color eyelidFurColor;
  final Offset leftCheek;
  final Offset rightCheek;
  final Offset tailAnchor;

  const PetStageRig({
    required this.collarStart,
    required this.collarControl,
    required this.collarEnd,
    required this.collarThickness,
    required this.tagAnchor,
    required this.leftEye,
    required this.rightEye,
    required this.eyeRadius,
    required this.eyelidFurColor,
    required this.leftCheek,
    required this.rightCheek,
    required this.tailAnchor,
  });

  static const Map<String, PetStageRig> _byAsset = {
    'assets/shiba_baby.png': PetStageRig(
      collarStart: Offset(0.508, 0.452),
      collarControl: Offset(0.648, 0.556),
      collarEnd: Offset(0.772, 0.510),
      collarThickness: 0.043,
      tagAnchor: Offset(0.692, 0.526),
      leftEye: Offset(0.648, 0.365),
      rightEye: Offset(0.796, 0.365),
      eyeRadius: 0.030,
      eyelidFurColor: Color(0xFFEDA65C),
      leftCheek: Offset(0.595, 0.408),
      rightCheek: Offset(0.822, 0.408),
      tailAnchor: Offset(0.26, 0.28),
    ),
    'assets/shiba_teen.png': PetStageRig(
      collarStart: Offset(0.388, 0.512),
      collarControl: Offset(0.495, 0.562),
      collarEnd: Offset(0.602, 0.512),
      collarThickness: 0.040,
      tagAnchor: Offset(0.495, 0.545),
      leftEye: Offset(0.422, 0.375),
      rightEye: Offset(0.568, 0.375),
      eyeRadius: 0.028,
      eyelidFurColor: Color(0xFFF0AD5E),
      leftCheek: Offset(0.365, 0.412),
      rightCheek: Offset(0.625, 0.412),
      tailAnchor: Offset(0.71, 0.45),
    ),
    'assets/shiba_puppy.png': PetStageRig(
      collarStart: Offset(0.360, 0.470),
      collarControl: Offset(0.480, 0.548),
      collarEnd: Offset(0.600, 0.470),
      collarThickness: 0.043,
      tagAnchor: Offset(0.480, 0.518),
      leftEye: Offset(0.408, 0.318),
      rightEye: Offset(0.550, 0.318),
      eyeRadius: 0.030,
      eyelidFurColor: Color(0xFFE59B52),
      leftCheek: Offset(0.355, 0.365),
      rightCheek: Offset(0.602, 0.365),
      tailAnchor: Offset(0.82, 0.62),
    ),
    'assets/shiba_child.png': PetStageRig(
      collarStart: Offset(0.495, 0.485),
      collarControl: Offset(0.635, 0.585),
      collarEnd: Offset(0.764, 0.534),
      collarThickness: 0.044,
      tagAnchor: Offset(0.678, 0.555),
      leftEye: Offset(0.628, 0.368),
      rightEye: Offset(0.768, 0.360),
      eyeRadius: 0.030,
      eyelidFurColor: Color(0xFFF68B33),
      leftCheek: Offset(0.580, 0.414),
      rightCheek: Offset(0.805, 0.404),
      tailAnchor: Offset(0.25, 0.29),
    ),
    'assets/shiba_young_adult.png': PetStageRig(
      collarStart: Offset(0.515, 0.442),
      collarControl: Offset(0.645, 0.545),
      collarEnd: Offset(0.758, 0.494),
      collarThickness: 0.043,
      tagAnchor: Offset(0.675, 0.515),
      leftEye: Offset(0.618, 0.315),
      rightEye: Offset(0.730, 0.315),
      eyeRadius: 0.026,
      eyelidFurColor: Color(0xFFEC7D2A),
      leftCheek: Offset(0.575, 0.360),
      rightCheek: Offset(0.775, 0.360),
      tailAnchor: Offset(0.25, 0.27),
    ),
    'assets/shiba_adult.png': PetStageRig(
      collarStart: Offset(0.558, 0.390),
      collarControl: Offset(0.680, 0.488),
      collarEnd: Offset(0.782, 0.440),
      collarThickness: 0.042,
      tagAnchor: Offset(0.708, 0.460),
      leftEye: Offset(0.658, 0.278),
      rightEye: Offset(0.750, 0.278),
      eyeRadius: 0.022,
      eyelidFurColor: Color(0xFFE08C42),
      leftCheek: Offset(0.618, 0.316),
      rightCheek: Offset(0.790, 0.316),
      tailAnchor: Offset(0.29, 0.24),
    ),
    'assets/old_dog.png': PetStageRig(
      collarStart: Offset(0.542, 0.392),
      collarControl: Offset(0.662, 0.495),
      collarEnd: Offset(0.765, 0.454),
      collarThickness: 0.042,
      tagAnchor: Offset(0.692, 0.468),
      leftEye: Offset(0.686, 0.285),
      rightEye: Offset(0.776, 0.285),
      eyeRadius: 0.021,
      eyelidFurColor: Color(0xFFD6823E),
      leftCheek: Offset(0.648, 0.325),
      rightCheek: Offset(0.805, 0.325),
      tailAnchor: Offset(0.24, 0.23),
    ),
  };

  static PetStageRig? forAsset(String assetPath) => _byAsset[assetPath];
}

/// CustomPainter that draws the equipped collar, studs, swinging paw/diamond charm,
/// and sparkles locked cleanly to the exact neck contour of the current Shiba stage.
class PetCollarPainter extends CustomPainter {
  final PetStageRig rig;
  final CollarStyle collar;
  final double swingAngle;
  final double shimmerPhase;

  static const Color _outlineDark = Color(0xFF1F120C);

  const PetCollarPainter({
    required this.rig,
    required this.collar,
    this.swingAngle = 0.0,
    this.shimmerPhase = 0.0,
  });

  Offset _quadPoint(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1.0 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p0 = Offset(rig.collarStart.dx * w, rig.collarStart.dy * h);
    final p1 = Offset(rig.collarControl.dx * w, rig.collarControl.dy * h);
    final p2 = Offset(rig.collarEnd.dx * w, rig.collarEnd.dy * h);
    final bandWidth = (rig.collarThickness * w).clamp(2.5, 40.0);
    final outlinePad = (w * 0.015).clamp(1.2, 6.0);

    final collarPath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);

    // 1. Pixel-art dark brown/black outer stroke
    final outlinePaint = Paint()
      ..color = _outlineDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = bandWidth + outlinePad * 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(collarPath, outlinePaint);

    // 2. Main collar strap
    final mainPaint = Paint()
      ..color = collar.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = bandWidth
      ..strokeCap = StrokeCap.round;
    if (collar.id == 'collar_gold' || collar.isDiamond) {
      mainPaint.shader = LinearGradient(
        colors: collar.isDiamond
            ? const [
                Color(0xFF00ACC1),
                Color(0xFFE0F7FA),
                Color(0xFF4DD0E1),
                Color(0xFFFFFFFF),
              ]
            : const [
                Color(0xFFFF8F00),
                Color(0xFFFFE57F),
                Color(0xFFFFB300),
                Color(0xFFFFF8E1),
              ],
      ).createShader(Rect.fromPoints(p0, p2));
    }
    canvas.drawPath(collarPath, mainPaint);

    // 3. Upper specular highlight ribbon along the collar
    final hiOffset = -bandWidth * 0.22;
    final hiPath = Path()
      ..moveTo(p0.dx, p0.dy + hiOffset)
      ..quadraticBezierTo(p1.dx, p1.dy + hiOffset, p2.dx, p2.dy + hiOffset);
    final hiPaint = Paint()
      ..color = collar.highlightColor.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bandWidth * 0.28).clamp(0.8, 10.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hiPath, hiPaint);

    // 4. Optional decorative studs along the strap for royal/luxury tiers
    if (collar.hasStuds) {
      final studRadius = (bandWidth * 0.20).clamp(0.8, 5.0);
      final studFill = Paint()..color = collar.studColor;
      final studRim = Paint()
        ..color = _outlineDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.006).clamp(0.5, 2.0);
      for (final t in const [0.18, 0.36, 0.84]) {
        final pt = _quadPoint(p0, p1, p2, t);
        canvas.drawCircle(pt, studRadius, studFill);
        canvas.drawCircle(pt, studRadius, studRim);
      }
    }

    // 5. Swinging D-ring & Golden Paw / Diamond Charm
    final anchor = Offset(rig.tagAnchor.dx * w, rig.tagAnchor.dy * h);
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(swingAngle);

    // Small metallic D-ring at top
    final ringRadius = (w * 0.016).clamp(1.2, 6.0);
    final ringPaint = Paint()
      ..color = collar.isDiamond
          ? const Color(0xFFE0F7FA)
          : const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.011).clamp(0.9, 3.5);
    canvas.drawCircle(Offset(0, ringRadius * 0.6), ringRadius, ringPaint);

    final tagCenter = Offset(0, ringRadius * 1.6 + (w * 0.028));
    final tagRadius = (w * (collar.hasSparkles ? 0.036 : 0.031)).clamp(
      2.4,
      14.0,
    );

    if (collar.isDiamond) {
      // Faceted glowing Diamond Gem pendant
      final gemPath = Path()
        ..moveTo(tagCenter.dx, tagCenter.dy - tagRadius * 1.15)
        ..lineTo(tagCenter.dx + tagRadius * 0.95, tagCenter.dy - tagRadius * 0.15)
        ..lineTo(tagCenter.dx, tagCenter.dy + tagRadius * 1.25)
        ..lineTo(tagCenter.dx - tagRadius * 0.95, tagCenter.dy - tagRadius * 0.15)
        ..close();
      canvas.drawPath(
        gemPath,
        Paint()
          ..color = const Color(0xFF80DEEA).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(gemPath, Paint()..color = const Color(0xFF4DD0E1));
      // Inner bright facet
      final innerFacet = Path()
        ..moveTo(tagCenter.dx, tagCenter.dy - tagRadius * 0.85)
        ..lineTo(tagCenter.dx + tagRadius * 0.55, tagCenter.dy - tagRadius * 0.15)
        ..lineTo(tagCenter.dx, tagCenter.dy + tagRadius * 0.75)
        ..lineTo(tagCenter.dx - tagRadius * 0.55, tagCenter.dy - tagRadius * 0.15)
        ..close();
      canvas.drawPath(innerFacet, Paint()..color = const Color(0xFFE0F7FA));
      canvas.drawPath(
        gemPath,
        Paint()
          ..color = _outlineDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = (w * 0.012).clamp(1.0, 4.0)
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      // Golden Paw Medallion
      canvas.drawCircle(
        tagCenter,
        tagRadius + outlinePad * 0.75,
        Paint()..color = _outlineDark,
      );
      canvas.drawCircle(
        tagCenter,
        tagRadius,
        Paint()..color = const Color(0xFFFFC107),
      );
      // Specular crescent on gold tag
      canvas.drawCircle(
        Offset(
          tagCenter.dx - tagRadius * 0.25,
          tagCenter.dy - tagRadius * 0.25,
        ),
        tagRadius * 0.35,
        Paint()..color = const Color(0xFFFFF59D),
      );
      // Tiny embossed brown paw pad inside medallion
      final pawPaint = Paint()..color = const Color(0xFF8D4E00);
      canvas.drawCircle(
        Offset(tagCenter.dx, tagCenter.dy + tagRadius * 0.18),
        tagRadius * 0.28,
        pawPaint,
      );
      for (final dx in const [-0.34, 0.0, 0.34]) {
        canvas.drawCircle(
          Offset(
            tagCenter.dx + dx * tagRadius,
            tagCenter.dy - (dx == 0.0 ? 0.32 : 0.20) * tagRadius,
          ),
          tagRadius * 0.15,
          pawPaint,
        );
      }
    }
    canvas.restore();

    // 6. Animated twinkling star sparkles for 24K Gold & Diamond collars
    if (collar.hasSparkles) {
      final pulse1 = (sin(shimmerPhase * pi * 2) * 0.5 + 0.5);
      final pulse2 = (sin((shimmerPhase + 0.45) * pi * 2) * 0.5 + 0.5);
      final s1 = _quadPoint(p0, p1, p2, 0.24);
      final s2 = Offset(
        anchor.dx + w * 0.055,
        anchor.dy + w * 0.045,
      );
      _drawSparkle(
        canvas,
        Offset(s1.dx, s1.dy - bandWidth * 0.45),
        (w * 0.032) * (0.55 + pulse1 * 0.6),
        collar.isDiamond ? Colors.white : const Color(0xFFFFF59D),
        pulse1,
      );
      _drawSparkle(
        canvas,
        s2,
        (w * 0.036) * (0.55 + pulse2 * 0.6),
        collar.isDiamond ? const Color(0xFFE0F7FA) : Colors.white,
        pulse2,
      );
    }
  }

  void _drawSparkle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    if (radius <= 0.5) return;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: (0.35 + alpha * 0.65).clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(covariant PetCollarPainter oldDelegate) {
    return oldDelegate.collar.id != collar.id ||
        oldDelegate.rig != rig ||
        (oldDelegate.swingAngle - swingAngle).abs() > 0.002 ||
        (oldDelegate.shimmerPhase - shimmerPhase).abs() > 0.01;
  }
}

/// CustomPainter for organic eye blinking, happy ^ ^ eyes + rosy cheeks,
/// sleeping closed eyes, tail-wagging motion arcs, and paw-step dust puffs!
class PetFaceAndFxPainter extends CustomPainter {
  final PetStageRig rig;
  final double blinkAmount; // 0.0 = open, 1.0 = closed
  final bool isHappy;
  final bool isSleeping;
  final bool isWagging;
  final bool isWalking;
  final double motionPhase; // 0.0..1.0

  static const Color _outlineDark = Color(0xFF23140D);

  const PetFaceAndFxPainter({
    required this.rig,
    this.blinkAmount = 0.0,
    this.isHappy = false,
    this.isSleeping = false,
    this.isWagging = false,
    this.isWalking = false,
    this.motionPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Facial Expressions (Happy ^ ^ + blush, Sleeping ︶ ︶, or Natural Blink)
    final eyeR = (rig.eyeRadius * w).clamp(1.5, 18.0);
    final leftCenter = Offset(rig.leftEye.dx * w, rig.leftEye.dy * h);
    final rightCenter = Offset(rig.rightEye.dx * w, rig.rightEye.dy * h);
    final lidPaint = Paint()..color = rig.eyelidFurColor;
    final lashPaint = Paint()
      ..color = _outlineDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = (eyeR * 0.58).clamp(1.1, 5.5)
      ..strokeCap = StrokeCap.round;

    if (isSleeping) {
      for (final eye in [leftCenter, rightCenter]) {
        canvas.drawCircle(eye, eyeR * 1.25, lidPaint);
        final rect = Rect.fromCenter(
          center: Offset(eye.dx, eye.dy - eyeR * 0.25),
          width: eyeR * 2.1,
          height: eyeR * 1.4,
        );
        canvas.drawArc(rect, 0.15 * pi, 0.70 * pi, false, lashPaint);
      }
    } else if (isHappy) {
      // Happy ^ ^ smiling crescent eyes + rosy cheek blush
      for (final eye in [leftCenter, rightCenter]) {
        canvas.drawCircle(eye, eyeR * 1.25, lidPaint);
        final rect = Rect.fromCenter(
          center: Offset(eye.dx, eye.dy + eyeR * 0.35),
          width: eyeR * 2.1,
          height: eyeR * 1.6,
        );
        canvas.drawArc(rect, 1.15 * pi, 0.70 * pi, false, lashPaint);
      }
      final blushPaint = Paint()
        ..color = const Color(0xFFFF6E8E).withValues(alpha: 0.42);
      for (final cheek in [rig.leftCheek, rig.rightCheek]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cheek.dx * w, cheek.dy * h),
            width: eyeR * 2.2,
            height: eyeR * 1.25,
          ),
          blushPaint,
        );
      }
    } else if (blinkAmount > 0.05) {
      // Smooth natural blink closing from top down
      final clamped = blinkAmount.clamp(0.0, 1.0);
      for (final eye in [leftCenter, rightCenter]) {
        final top = eye.dy - eyeR * 1.25;
        final coverHeight = (eyeR * 2.5) * clamped;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              eye.dx - eyeR * 1.25,
              top,
              eyeR * 2.5,
              coverHeight,
            ),
            Radius.circular(eyeR * 0.6),
          ),
          lidPaint,
        );
        if (clamped > 0.65) {
          final lashY = top + coverHeight - eyeR * 0.2;
          canvas.drawLine(
            Offset(eye.dx - eyeR * 0.95, lashY),
            Offset(eye.dx + eyeR * 0.95, lashY),
            lashPaint,
          );
        }
      }
    }

    // 2. Excited Tail-Wagging Cartoon Motion Arcs
    if (isWagging && !isSleeping) {
      final wagToggle = sin(motionPhase * pi * 6);
      final tx = rig.tailAnchor.dx * w;
      final ty = rig.tailAnchor.dy * h;
      final isTailOnLeft = rig.tailAnchor.dx < 0.5;
      final dir = isTailOnLeft ? -1.0 : 1.0;

      final wagPaint = Paint()
        ..color = Colors.amber.shade600.withValues(
          alpha: (0.55 + wagToggle.abs() * 0.4).clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.018).clamp(1.2, 3.5)
        ..strokeCap = StrokeCap.round;

      final shift = wagToggle * (w * 0.022);
      for (int i = 0; i < 2; i++) {
        final dist = (w * (0.055 + i * 0.042)) * dir;
        final arcRect = Rect.fromCenter(
          center: Offset(tx + dist, ty + shift),
          width: w * (0.07 + i * 0.03),
          height: h * (0.11 + i * 0.04),
        );
        final startAngle = isTailOnLeft ? (0.78 * pi) : (-0.22 * pi);
        canvas.drawArc(arcRect, startAngle, 0.44 * pi, false, wagPaint);
      }
    }

    // 3. Paw-Step Dust Puffs when Walking / Running / Chasing
    if (isWalking && !isSleeping) {
      final p = motionPhase.clamp(0.0, 1.0);
      final puffAlpha = (1.0 - p) * 0.55;
      if (puffAlpha > 0.05) {
        final puffPaint = Paint()
          ..color = const Color(0xFFEFEBE9).withValues(alpha: puffAlpha);
        final baseX = w * 0.22 - (p * w * 0.10);
        final baseY = h * 0.90 - (p * h * 0.04);
        canvas.drawCircle(
          Offset(baseX, baseY),
          (w * 0.035) * (0.6 + p * 0.7),
          puffPaint,
        );
        canvas.drawCircle(
          Offset(baseX - w * 0.045, baseY - h * 0.025),
          (w * 0.024) * (0.5 + p * 0.8),
          puffPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PetFaceAndFxPainter oldDelegate) {
    return (oldDelegate.blinkAmount - blinkAmount).abs() > 0.02 ||
        oldDelegate.isHappy != isHappy ||
        oldDelegate.isSleeping != isSleeping ||
        oldDelegate.isWagging != isWagging ||
        oldDelegate.isWalking != isWalking ||
        (oldDelegate.motionPhase - motionPhase).abs() > 0.02;
  }
}

/// Crisp illustrated Collar + Swinging Paw/Diamond Tag icon for the Collars Shop tab!
class CollarPreviewIcon extends StatelessWidget {
  final String collarId;
  final double size;

  const CollarPreviewIcon({
    super.key,
    required this.collarId,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    final style = PetCollars.byId(collarId);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CollarIconPainter(style),
      ),
    );
  }
}

class _CollarIconPainter extends CustomPainter {
  final CollarStyle collar;

  const _CollarIconPainter(this.collar);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const outline = Color(0xFF1F120C);

    // Draw curved 3D collar ring
    final collarRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.38),
      width: w * 0.76,
      height: h * 0.38,
    );

    canvas.drawOval(
      collarRect,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.19,
    );

    final bandPaint = Paint()
      ..color = collar.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12;
    if (collar.id == 'collar_gold' || collar.isDiamond) {
      bandPaint.shader = LinearGradient(
        colors: collar.isDiamond
            ? const [Color(0xFF00ACC1), Color(0xFFE0F7FA), Color(0xFF26C6DA)]
            : const [Color(0xFFFF8F00), Color(0xFFFFE57F), Color(0xFFFFB300)],
      ).createShader(collarRect);
    }
    canvas.drawOval(collarRect, bandPaint);

    // Highlight arc along front
    canvas.drawArc(
      collarRect,
      0.15 * pi,
      0.70 * pi,
      false,
      Paint()
        ..color = collar.highlightColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Dangling charm at bottom center
    final cx = w * 0.5;
    final cy = h * 0.74;
    final r = w * 0.16;
    if (collar.isDiamond) {
      final gem = Path()
        ..moveTo(cx, cy - r * 1.15)
        ..lineTo(cx + r * 0.95, cy)
        ..lineTo(cx, cy + r * 1.2)
        ..lineTo(cx - r * 0.95, cy)
        ..close();
      canvas.drawPath(gem, Paint()..color = const Color(0xFF4DD0E1));
      canvas.drawPath(
        gem,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.045,
      );
    } else {
      canvas.drawCircle(Offset(cx, cy), r + w * 0.04, Paint()..color = outline);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = const Color(0xFFFFC107),
      );
      canvas.drawCircle(
        Offset(cx - r * 0.25, cy - r * 0.25),
        r * 0.32,
        Paint()..color = const Color(0xFFFFF59D),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CollarIconPainter oldDelegate) =>
      oldDelegate.collar.id != collar.id;
}
