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
import 'pet/pet_sprite_widget.dart';
import 'pet/speech_bubble_widget.dart';
import 'pet/poo_layer_widget.dart';

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
  bool _isSick = false;
  int _sleepingUntil = 0;
  bool _userWantsSleep = false;
  int _lastStrokeTime = 0;

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

  // Speech Bubble
  String _currentSpeech = '';
  Timer? _speechTimer;

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

    // Start speech loop
    _speechTimer = Timer.periodic(
      const Duration(seconds: 25), 
      (_) => _updateSpeech(),
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
    _speechTimer?.cancel();
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
          bool isNapping = _sleepingUntil > DateTime.now().millisecondsSinceEpoch;

          if (_poos.isNotEmpty || boopReady || _isSick) {
            _isSleepingOverlay = false;
          } else if (isNapping) {
            _isSleepingOverlay = true;
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

            _isSick = data['pet']['sick'] ?? false;
            _sleepingUntil = data['pet']['sleeping_until'] ?? 0;

            int pendingPoos = data['pet']['pending_poos'] ?? 0;

            final now = DateTime.now().millisecondsSinceEpoch;
            bool boopReady = (now - _lastBoopTime) >= 1800000;
            bool isSleeping = _sleepingUntil > now;

            SharedPreferences.getInstance().then((prefs) {
              bool userWantsSleep = prefs.getBool('pet_sleeping') ?? false;
              if (mounted) {
                setState(() {
                  _userWantsSleep = userWantsSleep;
                  if (pendingPoos > 0 || boopReady || _isSick) {
                    _isSleepingOverlay = false;
                  } else if (isSleeping) {
                    _isSleepingOverlay = true;
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

  void _updateSpeech() {
    if (!mounted || _isSleepingOverlay || _stage == 'egg') return;
    
    // 50% chance to say nothing this cycle to prevent it from being too spammy
    if (_random.nextDouble() > 0.5) {
      setState(() => _currentSpeech = '');
      return;
    }

    String text = '';
    // Determine tier based on stats
    double avgStats = (_hunger + _happiness + _energy) / 3;
    
    if (_isSick || avgStats < 30) {
      // Tier 1: Needy
      const needy = [
        "I'm hungry! Please feed me.",
        "I need a nap... zZz",
        "Can we play fetch?",
        "I'm feeling a bit neglected..."
      ];
      text = needy[_random.nextInt(needy.length)];
    } else if (avgStats >= 30 && avgStats < 75) {
      // Tier 2: Golden Paw info
      const gpInfo = [
        "Did you know? You get 20% of your friends' claims for life!",
        "Boop my nose every 30 mins for free DOGE!",
        "Check the Updates Board to stay informed.",
        "You can stake DOGE in The Vault for 8.5% APY!",
        "Don't forget to walk me every 3 hours."
      ];
      text = gpInfo[_random.nextInt(gpInfo.length)];
    } else {
      // Tier 3: Financial/Crypto advice
      const cryptoInfo = [
        "Crypto Tip: Diversify your portfolio!",
        "Remember to do your own research (DYOR) before investing.",
        "Dogecoin was created in 2013 as a joke!",
        "Never invest more than you can afford to lose.",
        "Golden Paw is the best place to earn crypto in 2026!",
        "Keep holding! Diamond hands 💎🐾",
        "Market moving? Stay calm and earn passive income."
      ];
      text = cryptoInfo[_random.nextInt(cryptoInfo.length)];
    }
    
    setState(() => _currentSpeech = text);
    
    // Clear after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _currentSpeech == text) {
        setState(() => _currentSpeech = '');
      }
    });
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

// the methods _getImageAsset and _getScaleForStage were moved to pet_sprite_widget.dart

  void _onBallPanUpdate(DragUpdateDetails details) {
    if (_isFetching || _stage == 'baby') return;
    setState(() {
      _ballX += details.delta.dx;
      _ballY += details.delta.dy;
    });
  }

  void _onBallPanEnd(DragEndDetails details) {
    if (_isFetching || _stage == 'baby') return;
    
    if (details.velocity.pixelsPerSecond.distance > 500) {
      _startFetchSequence(details.velocity.pixelsPerSecond);
    }
  }

  Future<void> _startFetchSequence(Offset velocity) async {
    if (!mounted) return;
    setState(() => _isFetching = true);

    final size = MediaQuery.of(context).size;
    
    setState(() {
      double projectedX = _ballX + (velocity.dx * 1.5);
      double projectedY = _ballY + (velocity.dy * 1.5);

      _ballX = projectedX;
      _ballY = projectedY;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    // Pet chases the ball
    setState(() {
      _facingRight = _ballX > _petX;
      _petX = _ballX;
      _petY = _ballY;
      _isChasing = true;
    });

    // Pet is away for 1 second
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Pause to pick up
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Return to screen center (pet brings ball back)
    setState(() {
      _isChasing = false;
      _isReturning = true;
      _facingRight = (size.width / 2) > _petX;
      _petX = size.width / 2;
      _petY = size.height / 2;
      _ballX = _petX;
      _ballY = _petY;
    });

    // Wait for the return journey to finish
    await Future.delayed(const Duration(seconds: 2));
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

  Future<void> _strokePet() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastStrokeTime < 2000) return; // throttle locally 
    if (_isSleepingOverlay || _isSick) return;
    
    _lastStrokeTime = now;
    // Play animation
    _shakeController.forward(from: 0.0);

    try {
      final headers = await getAuthHeaders();
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-stroke'),
        headers: headers,
      );
      _fetchPetStatus(); // get new attention
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (!_ballInitialized && size.width > 0) {
      _ballX = size.width / 2 + 60;
      _ballY = size.height / 2 + 80;
      _ballInitialized = true;
    } else if (_ballInitialized && !_isFetching && !_isReturning) {
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
      return PooLayerWidget(poos: _poos, onClean: _cleanPoo);
    }

    return Stack(
      children: [
        // Poos
        PooLayerWidget(poos: _poos, onClean: _cleanPoo),

        // Speech Bubble
        if (_currentSpeech.isNotEmpty && !_isSleepingOverlay && _stage != 'egg')
          SpeechBubbleWidget(
            text: _currentSpeech,
            x: _petX,
            y: _petY,
            isChasing: _isChasing,
            isReturning: _isReturning,
          ),

        // Pet
        if (_isSleepingOverlay && _stage != 'egg')
          const SizedBox.shrink()
        else
          AnimatedPositioned(
            duration: Duration(seconds: _isChasing ? 1 : (_isReturning ? 2 : 4)),
            curve: Curves.easeInOut,
            left: _petX,
            top: _petY,
            child: PetSpriteWidget(
              stage: _stage,
              petName: _petName,
              isSick: _isSick,
              facingRight: _facingRight,
              equippedAccessories: _equippedAccessories,
              emotion: emotion,
              isCloseUp: _isCloseUp,
              isWalkAnimating: _walkController.isAnimating,
              isChasing: _isChasing,
              shakeController: _shakeController,
              walkController: _walkController,
              boopController: _boopController,
              trickController: _trickController,
              currentTrick: _currentTrick,
              onBoopDown: () {
                if (_isSleepingOverlay || _isSick) return;
                if (_stage != 'egg') _boopController.forward();
              },
              onBoopUp: () {
                if (_isSleepingOverlay || _isSick) return;
                if (_stage != 'egg') _boopController.reverse();
                if (_isCloseUp) {
                  _boopPet();
                } else if (_stage != 'egg') {
                  _startChasingMouse();
                }
              },
              onBoopCancel: () {
                if (_isSleepingOverlay || _isSick) return;
                if (_stage != 'egg') _boopController.reverse();
              },
              onStroke: () {
                if (_isSleepingOverlay || _isSick) return;
                if (_stage != 'egg') {
                  _strokePet();
                }
              },
            ), // PetSpriteWidget
          ), // closes AnimatedPositioned
          
        // Fetch Ball
        if (_stage != 'egg')
          AnimatedPositioned(
            duration: _isReturning ? const Duration(seconds: 2) : (_isFetching ? const Duration(milliseconds: 500) : Duration.zero),
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
                      color: Colors.white.withValues(alpha: 0.1),
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
