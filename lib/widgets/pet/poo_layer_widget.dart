import 'package:flutter/material.dart';
import 'pet_depth_perspective.dart';

/// A data class representing a single poo on the screen.
class PooData {
  final String id;
  final double x;
  final double y;

  PooData({required this.id, required this.x, required this.y});
}

/// Renders all poos on screen with 2.5D perspective scaling & background DoF.
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

  @override
  Widget build(BuildContext context) {
    if (poos.isEmpty) return const SizedBox.shrink();
    final screenHeight = MediaQuery.of(context).size.height;
    final sorted = List<PooData>.from(poos)
      ..sort((a, b) => a.y.compareTo(b.y));

    return Stack(
      children: sorted.map((poo) {
        final perspective = PetDepthPerspective.fromScreenY(
          y: poo.y - 55.0,
          screenHeight: screenHeight,
          cameraCloseUpFactor: cameraCloseUpFactor,
        );
        final pooScale = perspective.scale.clamp(0.55, 1.38);

        return Positioned(
          left: poo.x,
          top: poo.y,
          child: Transform.scale(
            scale: pooScale,
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () => onClean(poo.id),
              child: perspective.applyOpticalDoF(
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset('assets/shiba_poo.png'),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
