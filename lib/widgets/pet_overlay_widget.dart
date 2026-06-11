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

class _PetOverlayWidgetState extends State<PetOverlayWidget> with TickerProviderStateMixin {
  String _stage = 'egg';
  Timer? _statusTimer;
  Timer? _moveTimer;
  Timer? _chaseTimer;

  // Stats
  double _hunger = 50;
  double _happiness = 50;
  double _energy = 100;
  int _lastBoopTime = 0;
  String _petName = 'Golden Paw Shiba';

  // Position & Animation
  double _petX = 100;
  double _petY = 100;
  bool _facingRight = true;
  bool _isWandering = false;
  bool _isCloseUp = false;
  bool _isChasing = false;
  double _mouseX = 0;
  double _mouseY = 0;

  // Animations
  late AnimationController _shakeController;
  late AnimationController _walkController;
  late AnimationController _boopController;

  // Poos
  final List<PooData> _poos = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _walkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _boopController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    _fetchPetStatus();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchPetStatus());
    
    // Start movement loop
    _moveTimer = Timer.periodic(const Duration(seconds: 8), (_) => _movePetRandomly());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _moveTimer?.cancel();
    _chaseTimer?.cancel();
    _shakeController.dispose();
    _walkController.dispose();
    _boopController.dispose();
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
            _hunger = (data['pet']['hunger'] as num).toDouble();
            _happiness = (data['pet']['happiness'] as num).toDouble();
            _energy = (data['pet']['energy'] as num).toDouble();
            _lastBoopTime = data['pet']['last_boop_time'] ?? 0;
            _petName = data['pet']['name'] ?? 'Golden Paw Shiba';

            if (_stage != 'egg') {
              _isWandering = true;
            } else {
              _isWandering = false;
              // Occasionally shake the egg
              if (_random.nextDouble() > 0.5) {
                _shakeController.forward(from: 0.0);
              }
            }

            int pendingPoos = data['pet']['pending_poos'] ?? 0;
            // Add missing poos randomly across the screen
            if (pendingPoos > _poos.length) {
              final size = MediaQuery.of(context).size;
              int toAdd = pendingPoos - _poos.length;
              for (int i = 0; i < toAdd; i++) {
                double px = 50 + _random.nextDouble() * (size.width > 100 ? size.width - 100 : 100);
                double py = 100 + _random.nextDouble() * (size.height > 200 ? size.height - 200 : 200);
                _poos.add(PooData(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
                  x: px,
                  y: py,
                ));
              }
            } else if (pendingPoos < _poos.length) {
              _poos.removeRange(0, _poos.length - pendingPoos);
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
    
    // 15% chance to start chasing the mouse if not already close up or chasing
    if (!_isCloseUp && !_isChasing && _stage != 'egg' && _random.nextDouble() < 0.15) {
      _startChasingMouse();
      return;
    }

    final size = MediaQuery.of(context).size;
    final now = DateTime.now().millisecondsSinceEpoch;
    final msSinceBoop = now - _lastBoopTime;

    // Check if 15 mins passed since last boop
    if (msSinceBoop >= 15 * 60 * 1000 && !_isCloseUp) {
      _isCloseUp = true;
      final targetX = (size.width / 2) - 50; // Center horizontal
      final targetY = size.height - 250; // Bottom center
      
      setState(() {
        _facingRight = targetX > _petX;
        _petX = targetX;
        _petY = targetY;
      });
    } else {
      _isCloseUp = false;
      final targetX = 50 + _random.nextDouble() * (size.width > 150 ? size.width - 150 : 100);
      final targetY = 100 + _random.nextDouble() * (size.height > 300 ? size.height - 300 : 200);

      setState(() {
        _facingRight = targetX > _petX;
        _petX = targetX;
        _petY = targetY;
      });
    }

    // Start waddle animation while moving
    _walkController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isChasing) _walkController.stop();
      if (mounted) setState(() {}); // Refresh to show emotion if stopped
    });
  }

  void _startChasingMouse() {
    _isChasing = true;
    _moveTimer?.cancel();
    _walkController.repeat(reverse: true); // Constantly walk while chasing

    _chaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _facingRight = _mouseX > _petX;
        _petX = _mouseX - 50; // Center on mouse
        _petY = _mouseY - 50;
      });
      // Stop chasing after 10 seconds
      if (timer.tick >= 10) {
        _stopChasingMouse();
      }
    });
  }

  void _stopChasingMouse() {
    _isChasing = false;
    _chaseTimer?.cancel();
    if (mounted) {
      _walkController.stop();
      _moveTimer = Timer.periodic(const Duration(seconds: 8), (_) => _movePetRandomly());
    }
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

  Future<void> _boopPet() async {
    if (!_isCloseUp) return;

    _boopController.forward().then((_) => _boopController.reverse());

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastBoopTime < 15 * 60 * 1000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet is not ready for another boop yet!')));
      return;
    }

    // Optimistic UI update
    setState(() {
      _lastBoopTime = now;
      _isCloseUp = false;
    });

    // Walk away happily
    _movePetRandomly();

    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-boop'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Boop! +${data['reward']} DOGE ❤️'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Boop failed'), backgroundColor: Colors.red),
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
      case 'baby': return 'assets/shiba_baby.png';
      case 'toddler': return 'assets/shiba_toddler.png';
      case 'puppy': return 'assets/shiba_puppy.png';
      case 'child': return 'assets/shiba_child.png';
      case 'teen': return 'assets/shiba_teen.png';
      case 'young_adult': return 'assets/shiba_young_adult.png';
      case 'adult': return 'assets/shiba_adult.png';
      default: return 'assets/shiba_puppy.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    String emotion = '';
    if (!_walkController.isAnimating && !_isCloseUp && !_isChasing && _stage != 'egg') {
      if (_energy < 30) emotion = '💤';
      else if (_hunger < 30) emotion = '🍖';
      else if (_happiness > 80) emotion = '❤️';
    }

    return MouseRegion(
      onHover: (event) {
        _mouseX = event.position.dx;
        _mouseY = event.position.dy;
      },
      child: Stack(
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
          duration: Duration(seconds: _isChasing ? 1 : 4),
          curve: Curves.easeInOut,
          left: _petX,
          top: _petY,
          child: AnimatedBuilder(
            animation: Listenable.merge([_shakeController, _walkController, _boopController]),
            builder: (context, child) {
              double eggOffset = 0;
              double walkOffset = 0;
              
              if (_stage == 'egg') {
                eggOffset = sin(_shakeController.value * pi * 4) * 10;
              } else if (_walkController.isAnimating) {
                // Bob up and down while walking
                walkOffset = sin(_walkController.value * pi) * -10;
              }

              // Squish effect for boop
              double boopScale = 1.0 - (_boopController.value * 0.15);

              return Transform.translate(
                offset: Offset(eggOffset, walkOffset),
                child: AnimatedScale(
                  scale: _isCloseUp ? 2.5 : 1.0, // Scale up if walking to camera
                  duration: const Duration(seconds: 4),
                  curve: Curves.easeInOut,
                  child: Transform.scale(
                    scale: boopScale,
                    child: child,
                  ),
                ),
              );
            },
            child: GestureDetector(
              onTap: _isCloseUp ? _boopPet : null,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(_facingRight ? pi : 0), // Flip horizontal
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset(_getImageAsset()),
                    ),
                  ),
                  // Emotion bubble
                  if (emotion.isNotEmpty || _stage != 'egg')
                    Positioned(
                      top: -30,
                      child: Column(
                        children: [
                          if (_stage != 'egg')
                            Text(
                              _petName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                              ),
                            ),
                          if (emotion.isNotEmpty)
                            AnimatedOpacity(
                              opacity: emotion.isNotEmpty ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                emotion,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                        ],
                      ),
                    ),
                  // Boop Hint
                  if (_isCloseUp && !_walkController.isAnimating && !_isChasing)
                    const Positioned(
                      top: -25,
                      child: Text(
                        "Boop!",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                          shadows: [Shadow(color: Colors.white, blurRadius: 4)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}
