import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../src/theme_provider.dart';
import 'pet_depth_perspective.dart';

/// A data class representing a single poo on the screen.
class PooData {
  final String id;
  final double x;
  final double y;

  PooData({required this.id, required this.x, required this.y});
}

/// Renders all poos on screen with 2.5D perspective scaling, background DoF,
/// and high-visibility Dark Theme sticker rim + stink waves so poos pop clearly
/// against both dark and light backgrounds.
class PooLayerWidget extends StatelessWidget {
  final List<PooData> poos;
  final void Function(String id) onClean;
  final double cameraCloseUpFactor;

  const PooLayerWidget({
    super.key,
    required this.poos,
    required this.onClean,
    this.cameraCloseUpFactor = 0.0,
  });

  Widget _buildPooSprite(bool isDark) {
    final baseImage = Image.asset(
      'assets/shiba_poo.png',
      width: 44,
      height: 44,
      filterQuality: FilterQuality.none,
    );

    return SizedBox(
      width: 54,
      height: 58,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Ground spot / warm contrast pad (brighter in dark mode so dark brown never blends into #212121/#2A2A2A)
          Positioned(
            bottom: 1,
            child: Container(
              width: 44,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          Colors.amber.shade200.withValues(alpha: 0.42),
                          Colors.amber.withValues(alpha: 0.16),
                          Colors.transparent,
                        ]
                      : [
                          Colors.brown.shade900.withValues(alpha: 0.24),
                          Colors.brown.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.28),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),

          // Stink wave lines above the poo
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(28, 12),
              painter: _PooStinkWavesPainter(isDark: isDark),
            ),
          ),

          // In Dark Theme, draw a crisp warm-cream sticker rim around the dark pixel border
          if (isDark) ...[
            for (final offset in const [
              Offset(-1.5, 0),
              Offset(1.5, 0),
              Offset(0, -1.5),
              Offset(0, 1.5),
              Offset(-1.2, -1.2),
              Offset(1.2, -1.2),
              Offset(-1.2, 1.2),
              Offset(1.2, 1.2),
            ])
              Positioned(
                bottom: 3,
                child: Transform.translate(
                  offset: offset,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFFFF3C4),
                      BlendMode.srcIn,
                    ),
                    child: baseImage,
                  ),
                ),
              ),
          ],

          // Main poo sprite
          Positioned(
            bottom: 3,
            child: baseImage,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sorted = List<PooData>.from(poos)
      ..sort((a, b) => a.y.compareTo(b.y));

    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: sorted.map((poo) {
            final perspective = PetDepthPerspective.fromScreenY(
              y: poo.y - 55.0,
              screenHeight: screenHeight,
              cameraCloseUpFactor: cameraCloseUpFactor,
            );
            final pooScale = perspective.scale.clamp(0.68, 1.38);

            // Keep full 1.0 opacity on poos so they never dim into dark theme backgrounds
            final sharpOrBlurredPoo = perspective.blurSigma > 0.08
                ? PetDepthPerspective(
                    depth: perspective.depth,
                    scale: perspective.scale,
                    blurSigma: perspective.blurSigma * 0.7,
                    opacity: 1.0,
                    shadowIntensity: perspective.shadowIntensity,
                  ).applyOpticalDoF(_buildPooSprite(isDark))
                : _buildPooSprite(isDark);

            return Positioned(
              left: poo.x,
              top: poo.y,
              child: PointerInterceptor(
                child: Transform.scale(
                  scale: pooScale,
                  alignment: Alignment.bottomCenter,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onClean(poo.id),
                      child: sharpOrBlurredPoo,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PooStinkWavesPainter extends CustomPainter {
  final bool isDark;

  const _PooStinkWavesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFFFFE082).withValues(alpha: 0.85)
          : const Color(0xFF6D4C41).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (final xBase in [size.width * 0.30, size.width * 0.70]) {
      final path = Path()
        ..moveTo(xBase, size.height)
        ..quadraticBezierTo(
          xBase - 3.0,
          size.height * 0.66,
          xBase,
          size.height * 0.36,
        )
        ..quadraticBezierTo(
          xBase + 3.0,
          size.height * 0.12,
          xBase - 1.0,
          0,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PooStinkWavesPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
