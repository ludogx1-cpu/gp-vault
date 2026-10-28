import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../api_constants.dart';
import '../src/firebase_service.dart';
import 'pet/pet_sprite_widget.dart';

class WalkTreadmillDialog extends StatefulWidget {
  final String stage;
  final List<String> equippedAccessories;

  const WalkTreadmillDialog({
    super.key,
    this.stage = 'adult',
    this.equippedAccessories = const [],
  });

  @override
  State<WalkTreadmillDialog> createState() => _WalkTreadmillDialogState();
}

class _WalkTreadmillDialogState extends State<WalkTreadmillDialog>
    with TickerProviderStateMixin {
  int _distanceMeters = 0;
  bool _isSaving = false;
  double _dogeEarned = 0;

  late AnimationController _stepController;
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _stepController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  void _tapToWalk() {
    if (_isSaving) return;

    setState(() {
      _distanceMeters += 5;
    });

    _stepController.forward(from: 0);
  }

  Future<void> _endWalk() async {
    if (_distanceMeters == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-walk-sync'),
        headers: headers,
        body: jsonEncode({'distance_meters': _distanceMeters}),
      );

      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        setState(() {
          _dogeEarned = (data['reward'] as num).toDouble();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Walk complete! Earned ${_dogeEarned.toStringAsFixed(4)} DOGE 🐾',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to sync walk'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Walk Your Shiba! 🐾"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Tap 'STEP!' to walk your Shiba (+5m per step). Earn DOGE and XP!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Mini Treadmill view
          Container(
            height: 138,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.lightBlue.shade100, Colors.green.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: AnimatedBuilder(
              animation: Listenable.merge([_stepController, _idleController]),
              builder: (context, child) {
                final stepping = _stepController.isAnimating;
                final t = _stepController.value;
                final idleWave = sin(_idleController.value * pi * 2);
                final hopY = stepping
                    ? (-sin(t * pi) * 18.0)
                    : (-idleWave.abs() * 2.5);
                final waddle = stepping
                    ? (sin(t * pi * 2) * 0.10)
                    : (idleWave * 0.025);
                final scaleY = stepping
                    ? (1.0 + sin(t * pi) * 0.05)
                    : (1.0 + idleWave * 0.035);
                final scaleX = stepping
                    ? (1.0 - sin(t * pi) * 0.03)
                    : (1.0 - idleWave * 0.022);
                final collarSwing = stepping
                    ? (sin(t * pi * 2) * 0.28)
                    : (cos(_idleController.value * pi * 2) * 0.08);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Moving track stripes
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) {
                          return Transform.translate(
                            offset: Offset(stepping ? (-t * 24) : 0, 0),
                            child: Container(
                              width: 22,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.brown.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Dynamic shadow beneath paws
                    Positioned(
                      bottom: 18,
                      child: Container(
                        width: 56,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: stepping ? 0.14 : 0.20,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),

                    // Dressed Shiba hopping along with swinging collar, wagging tail & paw dust
                    Transform.translate(
                      offset: Offset(0, hopY),
                      child: Transform.rotate(
                        angle: waddle,
                        child: Transform.scale(
                          scaleX: scaleX,
                          scaleY: scaleY,
                          alignment: Alignment.bottomCenter,
                          child: PetSpriteWidget.buildDressedShiba(
                            stage:
                                widget.stage == 'egg' ? 'puppy' : widget.stage,
                            isSick: false,
                            equippedAccessories: widget.equippedAccessories,
                            size: 88,
                            isWalking: stepping,
                            isHappy: stepping,
                            isWagging: true,
                            collarSwingAngle: collarSwing,
                            motionPhase: t,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Text(
            "Distance: $_distanceMeters m",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _tapToWalk,
              icon: const Icon(Icons.pets, size: 24),
              label: const Text(
                "STEP! (+5m)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _endWalk,
          child: const Text(
            "Finish & Claim Walk",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
