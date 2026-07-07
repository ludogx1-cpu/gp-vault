import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart';
import '../src/firebase_service.dart';
import '../utils/pet_events.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PooData {
  final String id;
  final double x;
  final double y;

  PooData({required this.id, required this.x, required this.y});
}

double globalMouseX = 0;
double globalMouseY = 0;

class PetOverlayWidget extends StatefulWidget {
  const PetOverlayWidget({super.key});

  @override
  State<PetOverlayWidget> createState() => _PetOverlayWidgetState();
}

class _PetOverlayWidgetState extends State<PetOverlayWidget>
    with TickerProviderStateMixin {
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
  List<String> _equippedAccessories = [];

  // Position & Animation
  double _petX = 100;
  double _petY = 100;
  bool _facingRight = true;
  bool _isWandering = false;
  bool _isCloseUp = false;
  bool _isChasing = false;
  bool _isSleepingOverlay = false;
  bool _userWantsSleep = false;

  // Animations
  late AnimationController _shakeController;
  late AnimationController _walkController;
  late AnimationController _boopController;
  late AnimationController _trickController;

  String _currentTrick = '';
  StreamSubscription? _trickSubscription;
  StreamSubscription? _sleepSubscription;
  StreamSubscription? _ballSubscription;

  // Fetch Mechanics
  String _equippedBall = 'white';
  bool _isFetching = false;
  bool _isReturning = false;
  double _ballX = 400;
  double _ballY = 400;
  bool _ballInitialized = false;

  // Poos
  final List<PooData> _poos = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _boopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _trickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _listenForEvents();

    _fetchPetStatus();
    _statusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchPetStatus(),
    );

    // Start movement loop
    _moveTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _movePetRandomly(),
    );

    // Load saved sleep state
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _userWantsSleep = prefs.getBool('pet_sleeping') ?? false;
        _isSleepingOverlay = _userWantsSleep;
      });
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _moveTimer?.cancel();
    _chaseTimer?.cancel();
    _trickSubscription?.cancel();
    _sleepSubscription?.cancel();
    _ballSubscription?.cancel();
    _shakeController.dispose();
    _walkController.dispose();
    _boopController.dispose();
    _trickController.dispose();
    super.dispose();
  }

  void _listenForEvents() {
    _trickSubscription = PetEvents.trickStream.listen((trickName) {
      _playTrickAnimation(trickName);
    });

    _sleepSubscription = PetEvents.sleepStream.listen((sleep) {
      if (mounted) {
        setState(() {
          _userWantsSleep = sleep;

          bool boopReady = (DateTime.now().millisecondsSinceEpoch - _lastBoopTime) >= 1800000;
          if (_poos.isNotEmpty || boopReady) {
            _isSleepingOverlay = false;
          } else {
            _isSleepingOverlay = sleep;
          }
        });
      }
    });

    _ballSubscription = PetEvents.equipBallStream.listen((color) {
      if (mounted) setState(() => _equippedBall = color);
    });
  }

  void _playTrickAnimation(String trickName) {
    if (!mounted) return;
    setState(() => _currentTrick = trickName);
    _trickController.forward(from: 0).then((_) {
      if (mounted) setState(() => _currentTrick = '');
    });
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
            _equippedBall = data['pet']['equipped_ball'] ?? 'white';
            _equippedAccessories = List<String>.from(
              data['pet']['equipped_accessories'] ?? [],
            );

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

            final now = DateTime.now().millisecondsSinceEpoch;
            bool boopReady = (now - _lastBoopTime) >= 1800000;

            SharedPreferences.getInstance().then((prefs) {
              bool userWantsSleep = prefs.getBool('pet_sleeping') ?? false;
              if (mounted) {
                setState(() {
                  _userWantsSleep = userWantsSleep;
                  if (pendingPoos > 0 || boopReady) {
                    _isSleepingOverlay = false;
                  } else {
                    _isSleepingOverlay = userWantsSleep;
                  }
                });
              }
            });

            // Add missing poos randomly across the screen
            if (pendingPoos > _poos.length) {
              final size = MediaQuery.of(context).size;
              int toAdd = pendingPoos - _poos.length;
              for (int i = 0; i < toAdd; i++) {
                double px =
                    50 +
                    _random.nextDouble() *
                        (size.width > 100 ? size.width - 100 : 100);
                double py =
                    100 +
                    _random.nextDouble() *
                        (size.height > 200 ? size.height - 200 : 200);
                _poos.add(
                  PooData(
                    id:
                        DateTime.now().millisecondsSinceEpoch.toString() +
                        i.toString(),
                    x: px,
                    y: py,
                  ),
                );
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
    if (_isSleepingOverlay && _stage != 'egg') return;

    // 15% chance to start chasing the mouse if not already close up or chasing
    if (!_isCloseUp &&
        !_isChasing &&
        _stage != 'egg' &&
        _random.nextDouble() < 0.15) {
      _startChasingMouse();
      return;
    }

    final size = MediaQuery.of(context).size;
    final now = DateTime.now().millisecondsSinceEpoch;
    bool boopReady = (now - _lastBoopTime) >= 1800000;

    // Check if 30 mins passed since last boop
    if (boopReady) {
      _isCloseUp = true;
      final targetX = (size.width / 2) - 50; // Center horizontal
      final targetY = size.height - 250; // Bottom center

      setState(() {
        _facingRight = targetX > _petX;
        _petX = targetX;
        _petY = targetY;
      });
      // Do not walk away if waiting for a boop
      return;
    } else {
      _isCloseUp = false;
      final targetX =
          50 +
          _random.nextDouble() * (size.width > 150 ? size.width - 150 : 100);
      final targetY =
          100 +
          _random.nextDouble() * (size.height > 300 ? size.height - 300 : 200);

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
        _facingRight = globalMouseX > _petX;
        _petX = globalMouseX - 50; // Center on mouse
        _petY = globalMouseY - 50;
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
      _moveTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) => _movePetRandomly(),
      );
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
            SnackBar(
              content: Text('Cleaned up! +${data['reward']} DOGE', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to clean'),
              backgroundColor: Colors.red,
            ),
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
    if (now - _lastBoopTime < 30 * 60 * 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet is not ready for another boop yet!')),
      );
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
            SnackBar(
              content: Text('Boop! +${data['reward']} DOGE ❤️', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Boop failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // ignore
    }
  }

  String _getImageAsset() {
    switch (_stage) {
      case 'egg':
        return 'assets/shiba_egg.png';
      case 'baby':
        return 'assets/shiba_baby.png';
      case 'toddler':
        return 'assets/shiba_baby.png'; // Uses baby image but scaled larger
      case 'puppy':
        return 'assets/shiba_teen.png'; // Swapped with teen
      case 'child':
        return 'assets/shiba_child.png';
      case 'teen':
        return 'assets/shiba_puppy.png'; // Swapped with puppy
      case 'young_adult':
        return 'assets/shiba_young_adult.png';
      case 'adult':
        return 'assets/shiba_adult.png';
      default:
        return 'assets/shiba_toddler.png';
    }
  }

  double _getScaleForStage() {
    switch (_stage) {
      case 'egg':
        return 0.65; // Increased from 0.4
      case 'baby':
        return 0.75; // Increased from 0.5
      case 'toddler':
        return 0.85; // Increased from 0.6
      case 'puppy':
        return 0.95; // Increased from 0.7
      case 'child':
        return 1.0; // Increased from 0.8
      case 'teen':
        return 1.1; // Increased from 0.9
      case 'young_adult':
        return 1.2; // Increased from 1.0
      case 'adult':
        return 1.4; // Increased from 1.2
      default:
        return 0.7;
    }
  }

  void _onBallPanUpdate(DragUpdateDetails details) {
    if (_isFetching || _stage == 'egg') return;
    setState(() {
      _ballX += details.delta.dx;
      _ballY += details.delta.dy;
    });
  }

  void _onBallPanEnd(DragEndDetails details) {
    if (_isFetching || _stage == 'egg') return;
    
    if (details.velocity.pixelsPerSecond.distance > 500) {
      _startFetchSequence(details.velocity.pixelsPerSecond);
    } else {
      setState(() {
        _ballX = MediaQuery.of(context).size.width / 2;
        _ballY = MediaQuery.of(context).size.height / 2;
      });
    }
  }

  Future<void> _startFetchSequence(Offset velocity) async {
    if (!mounted) return;
    setState(() => _isFetching = true);

    final size = MediaQuery.of(context).size;
    final distance = velocity.distance;
    
    setState(() {
      if (distance > 0) {
        final dirX = velocity.dx / distance;
        final dirY = velocity.dy / distance;
        // Throw far off screen in the direction of the swipe
        _ballX += dirX * 1500;
        _ballY += dirY * 1500;
      }
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    // Pet chases the ball
    setState(() {
      _petX = _ballX;
      _petY = _ballY;
      _isChasing = true;
    });

    // Pet is away for 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // Return to screen (pet brings ball back)
    setState(() {
      _isChasing = false; // Pet will take 4 seconds to return
      _isReturning = true; // Ball will take 4 seconds to return
      
      // Place ball near pet, but not directly behind it
      _ballX = size.width / 2 + 60;
      _ballY = size.height / 2 + 80;
      _petX = size.width / 2 - 50;
      _petY = size.height / 2 + 30;
    });

    // Wait for the return journey to finish
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    setState(() {
      _isFetching = false;
      _isReturning = false;
      _isWandering = true; // Resume wandering
    });

    _recordFetchResult();
  }

  Future<void> _recordFetchResult() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-fetch'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        int clicks = data['clicks'] ?? 0;
        if (clicks % 5 == 0) {
          _launchSmartlink();
        }
        _fetchPetStatus(); 
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _launchSmartlink() async {
    final url = Uri.parse('https://landslidegraphsystems.com/yb0uurni?key=a7a2f7a7dae98e1083902b1e7285bdad');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (!_ballInitialized && size.width > 0) {
      _ballX = size.width / 2 + 60;
      _ballY = size.height / 2 + 80;
      _ballInitialized = true;
    } else if (_ballInitialized) {
      // Clamp to screen bounds to ensure it never gets lost
      if (_ballX < 0) _ballX = 20;
      if (_ballX > size.width - 30) _ballX = size.width - 30;
      if (_ballY < 0) _ballY = 20;
      if (_ballY > size.height - 30) _ballY = size.height - 30;

      // Prevent ball from getting stuck under the Adsterra ads on wide screens
      if (size.width >= 1000) {
        double leftAdEnd = ((size.width - 600) / 2 - 160) / 2 + 160;
        double rightAdStart = size.width - (((size.width - 600) / 2 - 160) / 2) - 160;
        
        if (_ballX < leftAdEnd + 10) _ballX = leftAdEnd + 10;
        if (_ballX > rightAdStart - 40) _ballX = rightAdStart - 40;
      }
    }

    String emotion = '';
    if (!_walkController.isAnimating &&
        !_isCloseUp &&
        !_isChasing &&
        _stage != 'egg') {
      if (_energy < 30) {
        emotion = '💤';
      } else if (_hunger < 30) {
        emotion = '🍖';
      } else if (_happiness > 80) {
        emotion = '❤️';
      }
    }

    if (_isSleepingOverlay && _stage != 'egg') {
      return Stack(
        children: [
          ..._poos.map(
            (poo) => Positioned(
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
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        // Poos
        ..._poos.map(
          (poo) => Positioned(
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
          ),
        ),

        // Pet
        if (_isSleepingOverlay && _stage != 'egg')
          const SizedBox.shrink()
        else
          AnimatedPositioned(
            duration: Duration(seconds: _isChasing ? 1 : 4),
            curve: Curves.easeInOut,
            left: _petX,
            top: _petY,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _shakeController,
                _walkController,
                _boopController,
              ]),
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
                double baseScale = _getScaleForStage();
                double boopScale =
                    baseScale - (_boopController.value * 0.15 * baseScale);

                return Transform.translate(
                  offset: Offset(eggOffset, walkOffset),
                  child: AnimatedScale(
                    scale: _isCloseUp
                        ? 2.5
                        : 1.0, // Scale up if walking to camera
                    duration: const Duration(seconds: 4),
                    curve: Curves.easeInOut,
                    child: Transform.scale(
                      scale: boopScale,
                      child: AnimatedBuilder(
                        animation: _trickController,
                        builder: (context, child) {
                          double trickRotation = 0;
                          double trickScale = 1.0;
                          double trickYOffset = 0;

                          if (_currentTrick == 'Spin') {
                            trickRotation = _trickController.value * pi * 2;
                          } else if (_currentTrick == 'Jump') {
                            trickYOffset =
                                sin(_trickController.value * pi) * -50;
                          } else if (_currentTrick == 'Roll Over') {
                            trickRotation = _trickController.value * pi * 2;
                            trickYOffset =
                                sin(_trickController.value * pi) *
                                20; // dip down
                          } else if (_currentTrick == 'Backflip') {
                            trickRotation =
                                _trickController.value *
                                pi *
                                2 *
                                -1; // rotate backwards
                            trickYOffset =
                                sin(_trickController.value * pi) *
                                -80; // jump higher
                          }

                          double trickXOffset = 0;
                          if (_currentTrick == 'Moonwalk') {
                            double direction = _facingRight ? -1.0 : 1.0;
                            double slideDist =
                                sin(_trickController.value * pi) * 60;
                            trickXOffset = slideDist * direction;
                          }

                          return Transform(
                            alignment: Alignment.center,
                            transform:
                                Matrix4.translationValues(
                                  trickXOffset,
                                  trickYOffset,
                                  0.0,
                                ) *
                                Matrix4.rotationZ(trickRotation) *
                                Matrix4.diagonal3Values(
                                  trickScale,
                                  trickScale,
                                  1.0,
                                ),
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          onTapDown: (_) {
                            if (_stage != 'egg') _boopController.forward();
                          },
                          onTapUp: (_) {
                            if (_stage != 'egg') _boopController.reverse();
                            if (_isCloseUp) {
                              _boopPet();
                            } else if (_stage != 'egg') {
                              _startChasingMouse();
                            }
                          },
                          onTapCancel: () {
                            if (_stage != 'egg') _boopController.reverse();
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(
                                  _facingRight ? pi : 0,
                                ), // Flip horizontal
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Image.asset(_getImageAsset()),
                                    ),
                                    // Render equipped accessories
                                    if (_equippedAccessories.contains(
                                      'top_hat',
                                    ))
                                      Positioned(
                                        top: -15,
                                        left: 30,
                                        child: Image.asset(
                                          'assets/shiba_top_hat.png',
                                          width: 40,
                                        ),
                                      ),
                                    if (_equippedAccessories.contains('crown'))
                                      Positioned(
                                        top: -10,
                                        left: 25,
                                        child: Image.asset(
                                          'assets/shiba_crown.png',
                                          width: 50,
                                        ),
                                      ),
                                    if (_equippedAccessories.contains(
                                      'sunglasses',
                                    ))
                                      Positioned(
                                        top: 25,
                                        left: 20,
                                        child: Image.asset(
                                          'assets/shiba_sunglasses.png',
                                          width: 45,
                                        ),
                                      ),
                                    if (_equippedAccessories.contains(
                                      'gold_chain',
                                    ))
                                      Positioned(
                                        top: 55,
                                        left: 25,
                                        child: Image.asset(
                                          'assets/shiba_gold_chain.png',
                                          width: 50,
                                        ),
                                      ),
                                    if (_equippedAccessories.contains(
                                      'coat_basic',
                                    ))
                                      Positioned(
                                        top: 20,
                                        left: 10,
                                        child: Image.asset(
                                          'assets/shiba_coat_basic.png',
                                          width: 80,
                                        ),
                                      ),
                                    if (_equippedAccessories.contains(
                                      'coat_rain',
                                    ))
                                      Positioned(
                                        top: 20,
                                        left: 10,
                                        child: Image.asset(
                                          'assets/shiba_coat_rain.png',
                                          width: 80,
                                        ),
                                      ),
                                    if (_equippedAccessories.contains(
                                      'coat_winter',
                                    ))
                                      Positioned(
                                        top: 20,
                                        left: 10,
                                        child: Image.asset(
                                          'assets/shiba_coat_winter.png',
                                          width: 80,
                                        ),
                                      ),
                                    if (_equippedAccessories.contains(
                                      'coat_luxury',
                                    ))
                                      Positioned(
                                        top: 20,
                                        left: 10,
                                        child: Image.asset(
                                          'assets/shiba_coat_luxury.png',
                                          width: 80,
                                        ),
                                      ),
                                    if (_equippedAccessories.contains(
                                      'diamond_watch',
                                    ))
                                      Positioned(
                                        top: 55,
                                        left: 25,
                                        child: Image.asset(
                                          'assets/shiba_diamond_watch.png',
                                          width: 50,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Emotion bubble
                              if (emotion.isNotEmpty || _stage != 'egg')
                                Positioned(
                                  top: -45,
                                  child: Column(
                                    children: [
                                      if (_stage != 'egg')
                                        Column(
                                          children: [
                                            Text(
                                              _petName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black,
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _stage
                                                  .replaceAll('_', ' ')
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 1.0,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black,
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (emotion.isNotEmpty)
                                        AnimatedOpacity(
                                          opacity: emotion.isNotEmpty
                                              ? 1.0
                                              : 0.0,
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          child: Text(
                                            emotion,
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              // Boop Hint
                              if (_isCloseUp &&
                                  !_walkController.isAnimating &&
                                  !_isChasing)
                                const Positioned(
                                  top: -25,
                                  child: Text(
                                    "Boop!",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.pinkAccent,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ), // closes AnimatedBuilder (trickController)
                    ), // closes Transform.scale (boopScale)
                  ), // closes AnimatedScale
                ); // closes Transform.translate
              },
            ), // closes AnimatedBuilder (shake/walk)
          ), // closes AnimatedPositioned
          
        // Fetch Ball
        if (_stage != 'egg')
          AnimatedPositioned(
            duration: _isReturning ? const Duration(seconds: 4) : (_isFetching ? const Duration(milliseconds: 300) : const Duration(milliseconds: 1)),
            curve: _isReturning ? Curves.easeInOut : Curves.easeOut,
            left: _ballX,
            top: _ballY,
            child: GestureDetector(
              onPanUpdate: _onBallPanUpdate,
              onPanEnd: _onBallPanEnd,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _getBallColor(_equippedBall),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
        // Debug Text
      ],
    );
  }

  Color _getBallColor(String colorString) {
    switch(colorString) {
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.yellow;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'indigo': return Colors.indigo;
      case 'violet': return Colors.purple;
      default: return Colors.white;
    }
  }
}
