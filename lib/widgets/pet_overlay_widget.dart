import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart';
import '../src/firebase_service.dart';

class PooData {
  final String id;
  final double x;
  final double y;

  PooData({required this.id, required this.x, required this.y});
}

class PetOverlayWidget extends StatefulWidget {
  const PetOverlayWidget({super.key});

  @override
  State<PetOverlayWidget> createState() => _PetOverlayWidgetState();
}

class _PetOverlayWidgetState extends State<PetOverlayWidget> with SingleTickerProviderStateMixin {
  String _stage = 'egg';
  Timer? _statusTimer;
  Timer? _moveTimer;
  Timer? _pooTimer;

  // Position & Animation
  double _petX = 100;
  double _petY = 100;
  bool _facingRight = true;
  bool _isWandering = false;

  // Shake animation for egg
  late AnimationController _shakeController;

  // Poos
  final List<PooData> _poos = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _fetchPetStatus();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchPetStatus());
    
    // Start movement loop
    _moveTimer = Timer.periodic(const Duration(seconds: 8), (_) => _movePetRandomly());
    
    // Start poo loop
    _pooTimer = Timer.periodic(const Duration(minutes: 5), (_) => _trySpawnPoo());

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _moveTimer?.cancel();
    _pooTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _fetchPetStatus() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['pet'] != null && mounted) {
          setState(() {
            _stage = data['pet']['stage'];
            if (_stage != 'egg') {
              _isWandering = true;
            } else {
              _isWandering = false;
              // Occasionally shake the egg
              if (_random.nextDouble() > 0.5) {
                _shakeController.forward(from: 0.0);
              }
            }
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  void _movePetRandomly() {
    if (!_isWandering || !mounted) return;
    
    final size = MediaQuery.of(context).size;
    final targetX = 50 + _random.nextDouble() * (size.width - 150);
    // Keep Y in the upper half or random area, avoiding being completely hidden
    final targetY = 100 + _random.nextDouble() * (size.height - 300);

    setState(() {
      _facingRight = targetX > _petX;
      _petX = targetX;
      _petY = targetY;
    });
  }

  void _trySpawnPoo() {
    if (!_isWandering || !mounted || _poos.length > 3) return;
    
    // Spawn at current pet location
    setState(() {
      _poos.add(PooData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        x: _petX,
        y: _petY + 50, // Drop below the pet
      ));
    });
  }

  Future<void> _cleanPoo(String pooId) async {
    setState(() {
      _poos.removeWhere((p) => p.id == pooId);
    });

    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-clean-poo'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cleaned up! +${data['reward']} DOGE'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to clean'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      // ignore
    }
  }

  String _getImageAsset() {
    switch (_stage) {
      case 'egg': return 'assets/shiba_egg.png';
      case 'teen': return 'assets/shiba_teen.png';
      case 'adult': return 'assets/shiba_adult.png';
      case 'puppy':
      default: return 'assets/shiba_puppy.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Poos
        ..._poos.map((poo) => Positioned(
          left: poo.x,
          top: poo.y,
          child: GestureDetector(
            onTap: () => _cleanPoo(poo.id),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Image.asset('assets/shiba_poo.png'),
            ),
          ),
        )),

        // Pet
        AnimatedPositioned(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          left: _petX,
          top: _petY,
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              double offset = 0;
              if (_stage == 'egg') {
                offset = sin(_shakeController.value * pi * 4) * 10;
              }
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(_facingRight ? pi : 0), // Flip horizontal
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(_getImageAsset()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
