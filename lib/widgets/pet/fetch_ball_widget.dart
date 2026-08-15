import 'package:flutter/material.dart';

class FetchBallWidget extends StatelessWidget {
  final double ballX;
  final double ballY;
  final bool isFetching;
  final bool isReturning;
  final String equippedBall;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const FetchBallWidget({
    super.key,
    required this.ballX,
    required this.ballY,
    required this.isFetching,
    required this.isReturning,
    required this.equippedBall,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  Color _getBallColor(String colorString) {
    switch (colorString) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'indigo':
        return Colors.indigo;
      case 'violet':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: isReturning
          ? const Duration(seconds: 2)
          : (isFetching ? const Duration(milliseconds: 500) : Duration.zero),
      curve: isReturning ? Curves.easeInOut : Curves.easeOut,
      left: ballX,
      top: ballY,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _getBallColor(equippedBall),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
