import 'package:flutter/material.dart';

/// A data class representing a single poo on the screen.
class PooData {
  final String id;
  final double x;
  final double y;

  PooData({required this.id, required this.x, required this.y});
}

/// Renders all poo emojis on screen and handles tap-to-clean.
class PooLayerWidget extends StatelessWidget {
  final List<PooData> poos;
  final void Function(String id) onClean;

  const PooLayerWidget({
    super.key,
    required this.poos,
    required this.onClean,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: poos
          .map(
            (poo) => Positioned(
              left: poo.x,
              top: poo.y,
              child: GestureDetector(
                onTap: () => onClean(poo.id),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset('assets/shiba_poo.png'),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
