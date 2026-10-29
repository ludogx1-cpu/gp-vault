import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart';
import '../src/firebase_service.dart';
import '../utils/pet_events.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pet/pet_sprite_widget.dart';
import 'pet/pet_collar_painter.dart';
import 'pet/pet_depth_perspective.dart';
import 'pet/speech_bubble_widget.dart';
import 'pet/poo_layer_widget.dart';
import 'pet/fetch_ball_widget.dart';

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

  // 2.5D Continuous Position & Camera Depth Interpolation
  double _startX = 120;
  double _startY = 220;
  double _petX = 120;
  double _petY = 220;
  double _startCloseUpFactor = 0.0;
  double _targetCloseUpFactor = 0.0;
  Curve _moveCurve = Curves.easeInOut;
  bool _positionInitialized = false;

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
  late AnimationController _moveController;
  late AnimationController _ballFlightController;
  late AnimationController _shakeController;
  late AnimationController _walkController;
  late AnimationController _boopController;
  late AnimationController _trickController;
  late AnimationController _idleController;
  late AnimationController _reactionController;

  String _currentTrick = '';
  String _reactionEmoji = '';
  StreamSubscription? _trickSubscription;
  StreamSubscription? _sleepSubscription;
  StreamSubscription? _ballSubscription;
  StreamSubscription? _collarSubscription;
  StreamSubscription? _refreshSubscription;
  StreamSubscription? _reactionSubscription;
  StreamSubscription<User?>? _authSubscription;

  // Fetch Mechanics (with 2.5D flight & perspective)
  String _equippedBall = 'white';
  bool _isFetching = false;
  bool _isReturning = false;
  bool _isBallDragging = false;
  double _ballStartX = 400;
  double _ballStartY = 400;
  double _ballX = 400;
  double _ballY = 400;
  double _panStartBallX = 400;
  double _panStartBallY = 400;
  double _flightArcHeight = 85.0;
  bool _ballInitialized = false;
  final List<(Offset, int)> _recentDragSamples = [];

  // Speech Bubble
  String _currentSpeech = '';
  Timer? _speechTimer;

  // Poos
  final List<PooData> _poos = [];
  final Random _random = Random();

  double get _moveProgress =>
      _moveController.isAnimating
          ? _moveCurve.transform(_moveController.value)
          : (_moveController.status == AnimationStatus.completed ? 1.0 : 0.0);

  double get _currentPetX =>
      lerpDouble(_startX, _petX, _moveProgress) ?? _petX;

  double get _currentPetY =>
      lerpDouble(_startY, _petY, _moveProgress) ?? _petY;

  double get _currentCloseUpFactor =>
      lerpDouble(_startCloseUpFactor, _targetCloseUpFactor, _moveProgress) ??
      _targetCloseUpFactor;

  double get _ballFlightProgress =>
      _ballFlightController.isAnimating
          ? Curves.easeOutCubic.transform(_ballFlightController.value)
          : (_ballFlightController.status == AnimationStatus.completed
                ? 1.0
                : 0.0);

  double get _currentBallX =>
      lerpDouble(_ballStartX, _ballX, _ballFlightProgress) ?? _ballX;

  double get _currentBallY =>
      lerpDouble(_ballStartY, _ballY, _ballFlightProgress) ?? _ballY;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
      value: 1.0,
    );
    _ballFlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1.0,
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _boopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _trickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _listenForEvents();

    _fetchPetStatus();
    _statusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchPetStatus(),
    );

    // Start 2.5D wandering loop
    _moveTimer = Timer.periodic(
      const Duration(seconds: 7),
      (_) => _movePetRandomly(),
    );

    // Start speech loop
    _speechTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _updateSpeech(),
    );

    // Load saved sleep state
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
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
    _collarSubscription?.cancel();
    _refreshSubscription?.cancel();
    _reactionSubscription?.cancel();
    _authSubscription?.cancel();
    _moveController.dispose();
    _ballFlightController.dispose();
    _shakeController.dispose();
    _walkController.dispose();
    _boopController.dispose();
    _trickController.dispose();
    _idleController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  /// Smoothly walks the Shiba from its exact current 2.5D coordinates & depth
  /// to `(targetX, targetY)`, syncing step bounces, facing direction, and DoF focus.
  void _animatePetTo(
    double targetX,
    double targetY, {
    required Duration duration,
    bool closeUp = false,
    Curve curve = Curves.easeInOut,
  }) {
    if (!mounted) return;
    final curX = _currentPetX;
    final curY = _currentPetY;
    final curCloseUp = _currentCloseUpFactor;

    setState(() {
      if ((targetX - curX).abs() > 4.0) {
        _facingRight = targetX >= curX;
      }
      _startX = curX;
      _startY = curY;
      _petX = targetX;
      _petY = targetY;
      _isCloseUp = closeUp;
      _startCloseUpFactor = curCloseUp;
      _targetCloseUpFactor = closeUp ? 1.0 : 0.0;
      _moveCurve = curve;
    });

    _moveController.duration = duration;
    if (!_walkController.isAnimating) {
      _walkController.repeat(reverse: true);
    }

    _moveController.forward(from: 0.0).then((_) {
      if (mounted &&
          !_moveController.isAnimating &&
          !_isChasing &&
          !_isFetching &&
          !_isReturning) {
        _walkController.stop();
        setState(() {});
      }
    });
  }

  (double, double) _horizontalBounds(Size size) {
    final double minX = 24.0;
    final double maxX = max(minX + 40.0, size.width - 124.0);
    return (minX, maxX);
  }

  /// Computes a poo position in the open left/right floor margins outside the
  /// center web page column and HTML iframes so poos are never hidden underneath
  /// page cards or platform-view iframes.
  Offset _spawnPooPosition(Size size, int index) {
    final minY = PetDepthPerspective.minYForScreen(size.height) + 45.0;
    final maxY = PetDepthPerspective.maxYForScreen(size.height);
    final py = minY + _random.nextDouble() * max(60.0, maxY - minY);

    if (size.width >= 900) {
      final centerHalfWidth = min(410.0, size.width * 0.34);
      final centerX = size.width / 2.0;
      final leftMin = 24.0;
      final leftMax = max(leftMin + 24.0, centerX - centerHalfWidth - 62.0);
      final rightMin = min(
        size.width - 96.0,
        centerX + centerHalfWidth + 14.0,
      );
      final rightMax = max(rightMin + 24.0, size.width - 68.0);

      final useLeftLane = (index % 2 == 0)
          ? (_random.nextDouble() < 0.7)
          : (_random.nextDouble() < 0.3);
      final px = useLeftLane
          ? (leftMin + _random.nextDouble() * max(16.0, leftMax - leftMin))
          : (rightMin + _random.nextDouble() * max(16.0, rightMax - rightMin));
      return Offset(px, py);
    }

    // On narrower screens, prefer the outer left/right edges away from centered iframes
    final placeLeft = (index % 2 == 0);
    final maxSafeX = max(64.0, size.width - 68.0);
    final px = placeLeft
        ? (16.0 + _random.nextDouble() * min(56.0, maxSafeX * 0.22))
        : max(16.0, maxSafeX - _random.nextDouble() * min(56.0, maxSafeX * 0.22));
    return Offset(px, py);
  }

  void _triggerReaction(String emoji) {
    if (!mounted) return;
    setState(() => _reactionEmoji = emoji);
    _reactionController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _reactionEmoji = '');
    });
  }

  void _listenForEvents() {
    _trickSubscription = PetEvents.trickStream.listen((trickName) {
      _playTrickAnimation(trickName);
      _triggerReaction('✨');
    });

    _sleepSubscription = PetEvents.sleepStream.listen((sleep) {
      if (mounted) {
        setState(() {
          _userWantsSleep = sleep;

          bool boopReady =
              (DateTime.now().millisecondsSinceEpoch - _lastBoopTime) >=
              1800000;

          if (_poos.isNotEmpty || boopReady || _isSick) {
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

    _collarSubscription = PetEvents.equipCollarStream.listen((collars) {
      if (mounted) {
        setState(() => _equippedAccessories = List<String>.from(collars));
      }
    });

    _refreshSubscription = PetEvents.refreshStream.listen((_) {
      if (mounted) _fetchPetStatus();
    });

    _reactionSubscription = PetEvents.reactionStream.listen((emoji) {
      if (mounted) {
        _triggerReaction(emoji);
        _shakeController.forward(from: 0.0);
      }
    });

    if (Firebase.apps.isNotEmpty) {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) {
        if (user != null && mounted) {
          _fetchPetStatus();
        }
      });
    }
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
          final wasEgg = _stage == 'egg';
          setState(() {
            _stage = data['pet']['stage'];
            _hunger = (data['pet']['hunger'] as num).toDouble();
            _happiness = (data['pet']['happiness'] as num).toDouble();
            _energy = (data['pet']['energy'] as num).toDouble();
            _lastBoopTime = data['pet']['last_boop_time'] ?? 0;
            _petName = data['pet']['name'] ?? 'Golden Paw Shiba';
            _equippedBall = data['pet']['equipped_ball'] ?? 'white';
            _equippedAccessories = PetCollars.normalizeList(
              List<String>.from(data['pet']['equipped_accessories'] ?? []),
            );

            if (_stage != 'egg') {
              _isWandering = true;
            } else {
              _isWandering = false;
              if (_random.nextDouble() > 0.5) {
                _shakeController.forward(from: 0.0);
              }
            }

            _isSick = data['pet']['sick'] ?? false;
            _sleepingUntil = data['pet']['sleeping_until'] ?? 0;

            int pendingPoos = data['pet']['pending_poos'] ?? 0;

            final now = DateTime.now().millisecondsSinceEpoch;
            bool boopReady = (now - _lastBoopTime) >= 1800000;

            SharedPreferences.getInstance().then((prefs) {
              bool userWantsSleep = prefs.getBool('pet_sleeping') ?? false;
              if (mounted) {
                setState(() {
                  _userWantsSleep = userWantsSleep;
                  if (pendingPoos > 0 || boopReady || _isSick) {
                    _isSleepingOverlay = false;
                  } else {
                    _isSleepingOverlay = userWantsSleep;
                  }
                });
              }
            });

            // Spawn poos in open floor lanes outside the center web page / iframes
            if (pendingPoos > _poos.length) {
              final size = MediaQuery.of(context).size;
              int toAdd = pendingPoos - _poos.length;
              for (int i = 0; i < toAdd; i++) {
                final pos = _spawnPooPosition(size, _poos.length + i);
                _poos.add(
                  PooData(
                    id:
                        DateTime.now().millisecondsSinceEpoch.toString() +
                        i.toString(),
                    x: pos.dx,
                    y: pos.dy,
                  ),
                );
              }
            } else if (pendingPoos < _poos.length) {
              _poos.removeRange(0, _poos.length - pendingPoos);
            }
          });

          if (wasEgg && _stage != 'egg' && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _movePetRandomly();
            });
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  void _updateSpeech() {
    if (!mounted || _isSleepingOverlay || _stage == 'egg') return;

    if (_random.nextDouble() > 0.5) {
      setState(() => _currentSpeech = '');
      return;
    }

    String text = '';
    double avgStats = (_hunger + _happiness + _energy) / 3;

    if (_isSick || avgStats < 30) {
      const needy = [
        "I'm hungry! Please feed me.",
        "I need a nap... zZz",
        "Can we play fetch?",
        "I'm feeling a bit neglected...",
      ];
      text = needy[_random.nextInt(needy.length)];
    } else if (avgStats >= 30 && avgStats < 75) {
      const gpInfo = [
        "Did you know? You get 20% of your friends' claims for life!",
        "Boop my nose every 30 mins for free DOGE!",
        "Check the Updates Board to stay informed.",
        "You can stake DOGE in The Vault for 33% APY!",
        "Don't forget to walk me every 3 hours.",
      ];
      text = gpInfo[_random.nextInt(gpInfo.length)];
    } else {
      const cryptoInfo = [
        "Crypto Tip: Diversify your portfolio!",
        "Remember to do your own research (DYOR) before investing.",
        "Dogecoin was created in 2013 as a joke!",
        "Never invest more than you can afford to lose.",
        "Golden Paw is the best place to earn crypto in 2026!",
        "Keep holding! Diamond hands 💎🐾",
        "Market moving? Stay calm and earn passive income.",
      ];
      text = cryptoInfo[_random.nextInt(cryptoInfo.length)];
    }

    setState(() => _currentSpeech = text);

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _currentSpeech == text) {
        setState(() => _currentSpeech = '');
      }
    });
  }

  void _movePetRandomly() {
    if (!_isWandering || !mounted) return;
    if (_isSleepingOverlay && _stage != 'egg') return;
    if (_sleepingUntil > DateTime.now().millisecondsSinceEpoch) return;
    if (_isFetching || _isReturning) return;

    if (!_isCloseUp &&
        !_isChasing &&
        _stage != 'egg' &&
        (globalMouseX > 0 || globalMouseY > 0) &&
        _random.nextDouble() < 0.15) {
      _startChasingMouse();
      return;
    }

    final size = MediaQuery.of(context).size;
    final minY = PetDepthPerspective.minYForScreen(size.height);
    final maxY = PetDepthPerspective.maxYForScreen(size.height);
    final (minX, maxX) = _horizontalBounds(size);

    final now = DateTime.now().millisecondsSinceEpoch;
    bool boopReady = !_isSick && (now - _lastBoopTime) >= 1800000;

    if (boopReady) {
      // Walk right up to the front-center camera lens for a close-up Boop!
      final targetX = ((size.width / 2) - 50).clamp(minX, maxX);
      final targetY = maxY;
      if (_isCloseUp &&
          !_moveController.isAnimating &&
          (_petX - targetX).abs() < 8 &&
          (_petY - targetY).abs() < 8) {
        // Already arrived at the camera lens waiting for a boop
        return;
      }
      final dist = Offset(
        targetX - _currentPetX,
        targetY - _currentPetY,
      ).distance;
      final ms = (dist * 8.5).round().clamp(1800, 4200);
      _animatePetTo(
        targetX,
        targetY,
        duration: Duration(milliseconds: ms),
        closeUp: true,
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    // Varied 2.5D depth waypoints:
    // ~34% far background (small + soft DoF blur),
    // ~34% close foreground (large + crisp focus),
    // ~32% midground roam.
    final spanY = max(80.0, maxY - minY);
    final zoneRoll = _random.nextDouble();
    double targetY;
    if (zoneRoll < 0.34) {
      targetY = minY + _random.nextDouble() * (spanY * 0.30);
    } else if (zoneRoll < 0.68) {
      targetY = minY + (spanY * 0.70) + _random.nextDouble() * (spanY * 0.30);
    } else {
      targetY = minY + (spanY * 0.28) + _random.nextDouble() * (spanY * 0.44);
    }

    final targetX = minX + _random.nextDouble() * max(20.0, maxX - minX);
    final dist = Offset(
      targetX - _currentPetX,
      targetY - _currentPetY,
    ).distance;
    final ms = (dist * 9.0).round().clamp(2200, 4800);

    _animatePetTo(
      targetX,
      targetY,
      duration: Duration(milliseconds: ms),
      closeUp: false,
      curve: Curves.easeInOut,
    );
  }

  void _startChasingMouse() {
    _isChasing = true;
    _moveTimer?.cancel();

    _chaseTimer = Timer.periodic(const Duration(milliseconds: 950), (timer) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final minY = PetDepthPerspective.minYForScreen(size.height);
      final maxY = PetDepthPerspective.maxYForScreen(size.height);
      final targetX = (globalMouseX - 50.0)
          .clamp(15.0, max(20.0, size.width - 115.0))
          .toDouble();
      final targetY = (globalMouseY - 50.0).clamp(minY, maxY).toDouble();

      _animatePetTo(
        targetX,
        targetY,
        duration: const Duration(milliseconds: 900),
        closeUp: false,
        curve: Curves.easeOutCubic,
      );

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
        const Duration(seconds: 7),
        (_) => _movePetRandomly(),
      );
    }
  }

  Future<void> _cleanPoo(String pooId) async {
    setState(() {
      _poos.removeWhere((p) => p.id == pooId);
    });
    _triggerReaction('✨');

    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-clean-poo'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        PetEvents.notifyStatusChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cleaned up! +${data['reward']} DOGE',
                style: const TextStyle(color: Colors.white),
              ),
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
    _triggerReaction('💖');

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastBoopTime < 30 * 60 * 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet is not ready for another boop yet!')),
      );
      return;
    }

    setState(() {
      _lastBoopTime = now;
      _isCloseUp = false;
    });

    // Trot happily off into the room after being booped!
    _movePetRandomly();

    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-boop'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        PetEvents.notifyStatusChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Boop! +${data['reward']} DOGE ❤️',
                style: const TextStyle(color: Colors.white),
              ),
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

  void _onBallPanStart(DragStartDetails details) {
    if (_isFetching || _isReturning || _stage == 'egg') return;
    _ballFlightController.stop();
    setState(() {
      _isBallDragging = true;
      _panStartBallX = _currentBallX;
      _panStartBallY = _currentBallY;
      _recentDragSamples.clear();
      _recentDragSamples.add((Offset.zero, DateTime.now().millisecondsSinceEpoch));
    });
  }

  void _onBallPanUpdate(DragUpdateDetails details) {
    if (_isFetching || _isReturning || _stage == 'egg') return;
    _ballFlightController.stop();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _recentDragSamples.add((details.delta, nowMs));
    if (_recentDragSamples.length > 8) {
      _recentDragSamples.removeAt(0);
    }
    setState(() {
      _isBallDragging = true;
      _ballX += details.delta.dx;
      _ballY += details.delta.dy;
      _ballStartX = _ballX;
      _ballStartY = _ballY;
    });
  }

  void _onBallTap() {
    if (_isFetching || _isReturning || _stage == 'egg' || !mounted) return;
    final size = MediaQuery.of(context).size;
    final throwRight = _facingRight || _currentBallX < (size.width / 2);
    final tossDir = Offset(throwRight ? 0.85 : -0.85, -0.55);
    _launchBallWithVector(velocity: tossDir * 320.0, displacement: tossDir * 80.0);
  }

  void _onBallPanEnd(DragEndDetails details) {
    if (_isFetching || _isReturning || _stage == 'egg') return;
    setState(() => _isBallDragging = false);

    // 1. Gesture velocity
    final gestureVel = details.velocity.pixelsPerSecond;

    // 2. Velocity from recent drag history (essential on Web/touch when mouse slows right before release)
    Offset historyVel = Offset.zero;
    if (_recentDragSamples.length >= 2) {
      final dt = (_recentDragSamples.last.$2 - _recentDragSamples.first.$2) / 1000.0;
      if (dt > 0.015 && dt < 0.35) {
        Offset totalDelta = Offset.zero;
        for (final s in _recentDragSamples) {
          totalDelta += s.$1;
        }
        historyVel = totalDelta / dt;
      }
    }

    final effectiveVel = gestureVel.distance >= historyVel.distance ? gestureVel : historyVel;
    final totalDisp = Offset(_ballX - _panStartBallX, _ballY - _panStartBallY);

    _launchBallWithVector(velocity: effectiveVel, displacement: totalDisp);
  }

  void _launchBallWithVector({required Offset velocity, required Offset displacement}) {
    if (_isFetching || _isReturning || _stage == 'egg' || !mounted) return;

    final size = MediaQuery.of(context).size;
    final minY = PetDepthPerspective.minYForScreen(size.height) + 20.0;
    final maxY = PetDepthPerspective.maxYForScreen(size.height) + 35.0;
    final (minX, maxX) = _horizontalBounds(size);

    final curBX = _currentBallX;
    final curBY = _currentBallY;

    Offset throwDir;
    double throwDist;

    if (velocity.distance >= 100.0) {
      // High-momentum flick or throw
      throwDir = velocity / velocity.distance;
      throwDist = (velocity.distance * 1.55).clamp(380.0, 950.0);
    } else if (displacement.distance >= 18.0) {
      // Drag & release toss
      throwDir = displacement / displacement.distance;
      throwDist = (displacement.distance * 4.2).clamp(360.0, 900.0);
    } else {
      // Tap or gentle nudge: toss forward into the open room
      final throwRight = _facingRight || curBX < (size.width / 2);
      throwDir = Offset(throwRight ? 0.85 : -0.85, -0.55);
      throwDir = throwDir / throwDir.distance;
      throwDist = 440.0;
    }

    // Projected landing coordinates
    double targetX = curBX + (throwDir.dx * throwDist);
    double targetY = curBY + (throwDir.dy * throwDist);

    // Wall bounce: if thrown off-screen, bounce dynamically back into the yard
    if (targetX < minX) {
      final overflow = minX - targetX;
      targetX = (minX + overflow * 0.45).clamp(minX, maxX);
    } else if (targetX > maxX + 40.0) {
      final overflow = targetX - (maxX + 40.0);
      targetX = ((maxX + 40.0) - overflow * 0.45).clamp(minX, maxX);
    }

    // Depth bounds: if thrown too far backward or forward, bounce gently back
    if (targetY < minY) {
      final overflow = minY - targetY;
      targetY = (minY + overflow * 0.35).clamp(minY, maxY);
    } else if (targetY > maxY) {
      final overflow = targetY - maxY;
      targetY = (maxY - overflow * 0.35).clamp(minY, maxY);
    }

    // Guarantee that every throw travels at least 280px across the yard!
    final actualDist = Offset(targetX - curBX, targetY - curBY).distance;
    if (actualDist < 260.0) {
      final fallbackDir = Offset(
        curBX < (size.width / 2) ? 1.0 : -1.0,
        curBY > (minY + (maxY - minY) * 0.5) ? -0.7 : 0.7,
      );
      final normFallback = fallbackDir / fallbackDir.distance;
      targetX = (curBX + normFallback.dx * 380.0).clamp(minX, maxX);
      targetY = (curBY + normFallback.dy * 380.0).clamp(minY, maxY);
    }

    _startFetchFlight(targetX, targetY);
  }

  Future<void> _startFetchFlight(double targetX, double targetY) async {
    if (!mounted) return;

    final curBX = _currentBallX;
    final curBY = _currentBallY;
    final flightDist = Offset(targetX - curBX, targetY - curBY).distance;

    // High lofty parabolic flight arc scaled by distance
    final arcHeight = (flightDist * 0.28).clamp(65.0, 145.0);
    final flightDurationMs = (flightDist * 1.15).round().clamp(650, 980);

    setState(() {
      _isFetching = true;
      _ballStartX = curBX;
      _ballStartY = curBY;
      _ballX = targetX;
      _ballY = targetY;
      _flightArcHeight = arcHeight;
    });

    _ballFlightController.duration = Duration(milliseconds: flightDurationMs);
    _ballFlightController.forward(from: 0.0);

    await Future.delayed(Duration(milliseconds: flightDurationMs));
    if (!mounted) return;

    // Shiba spots the landed ball, barks happily and sprints over!
    final size = MediaQuery.of(context).size;
    final (minX, maxX) = _horizontalBounds(size);
    final targetPetX = (targetX - (_facingRight ? 45.0 : 25.0)).clamp(minX, maxX);
    final targetPetY = (targetY - 58.0).clamp(
      PetDepthPerspective.minYForScreen(size.height),
      PetDepthPerspective.maxYForScreen(size.height),
    );

    _isChasing = true;
    final chaseDist = Offset(targetPetX - _currentPetX, targetPetY - _currentPetY).distance;
    final chaseDurationMs = (chaseDist * 4.8).round().clamp(750, 1500);

    _animatePetTo(
      targetPetX,
      targetPetY,
      duration: Duration(milliseconds: chaseDurationMs),
      closeUp: false,
      curve: Curves.easeOutCubic,
    );

    await Future.delayed(Duration(milliseconds: chaseDurationMs + 50));
    if (!mounted) return;

    // Shiba scoops up the ball!
    _triggerReaction('🎾');
    await Future.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;

    // Shiba trots back towards midground/user carrying the ball!
    final returnX = ((size.width / 2) + (_random.nextDouble() * 120.0 - 60.0)).clamp(minX, maxX);
    final returnY = (PetDepthPerspective.minYForScreen(size.height) +
        (PetDepthPerspective.maxYForScreen(size.height) - PetDepthPerspective.minYForScreen(size.height)) * 0.62);

    setState(() {
      _isChasing = false;
      _isReturning = true;
    });

    final returnDist = Offset(returnX - _currentPetX, returnY - _currentPetY).distance;
    final returnDurationMs = (returnDist * 6.2).round().clamp(1200, 2400);

    _animatePetTo(
      returnX,
      returnY,
      duration: Duration(milliseconds: returnDurationMs),
      closeUp: false,
      curve: Curves.easeInOut,
    );

    await Future.delayed(Duration(milliseconds: returnDurationMs + 50));
    if (!mounted) return;

    _walkController.stop();
    setState(() {
      _ballX = _currentPetX + (_facingRight ? 58.0 : 16.0);
      _ballY = _currentPetY + 65.0;
      _ballStartX = _ballX;
      _ballStartY = _ballY;
      _isFetching = false;
      _isReturning = false;
      _isWandering = true;
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
        PetEvents.notifyStatusChanged();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _launchSmartlink() async {
    final url = Uri.parse(
      'https://landslidegraphsystems.com/yb0uurni?key=a7a2f7a7dae98e1083902b1e7285bdad',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _strokePet() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastStrokeTime < 2000) return;
    if (_isSleepingOverlay || _isSick) return;

    _lastStrokeTime = now;
    _shakeController.forward(from: 0.0);
    _triggerReaction('❤️');

    try {
      final headers = await getAuthHeaders();
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-stroke'),
        headers: headers,
      );
      _fetchPetStatus();
      PetEvents.notifyStatusChanged();
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minY = PetDepthPerspective.minYForScreen(size.height);
    final maxY = PetDepthPerspective.maxYForScreen(size.height);
    final (minX, maxX) = _horizontalBounds(size);

    if (!_positionInitialized && size.width > 0 && size.height > 0) {
      _petX = ((size.width / 2) - 50).clamp(minX, maxX);
      _petY = minY + (maxY - minY) * 0.54;
      _startX = _petX;
      _startY = _petY;
      _positionInitialized = true;
    }

    if (!_ballInitialized && size.width > 0 && size.height > 0) {
      _ballX = (size.width / 2 + 65).clamp(minX, maxX + 50);
      _ballY = (minY + (maxY - minY) * 0.62 + 55).clamp(minY, maxY + 45);
      _ballStartX = _ballX;
      _ballStartY = _ballY;
      _ballInitialized = true;
    } else if (_ballInitialized && !_isFetching && !_isReturning) {
      _ballX = _ballX.clamp(minX, maxX + 60);
      _ballY = _ballY.clamp(minY + 10, maxY + 50);
      _ballStartX = _ballX;
      _ballStartY = _ballY;
    }

    final isNapping = _sleepingUntil > DateTime.now().millisecondsSinceEpoch;
    String emotion = '';
    if (isNapping && _stage != 'egg') {
      emotion = '💤';
    } else if (!_walkController.isAnimating &&
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

    return AnimatedBuilder(
      animation: Listenable.merge([_moveController, _ballFlightController]),
      builder: (context, _) {
        final curPetX = _currentPetX;
        final curPetY = _currentPetY;
        final curCloseUp = _currentCloseUpFactor;

        final petPerspective = PetDepthPerspective.fromScreenY(
          y: curPetY,
          screenHeight: size.height,
          closeUpFactor: curCloseUp,
        );

        // Parabolic throw arc when ball is flying, or carried by Shiba when returning!
        final throwArc =
            (_ballFlightController.isAnimating && !_isReturning)
                ? -sin(_ballFlightController.value * pi) * _flightArcHeight
                : 0.0;
        final stageScale = PetSpriteWidget.stageScaleFor(_stage);
        final combinedPetScale = stageScale * petPerspective.scale;

        final liveBallX = _isReturning
            ? (curPetX + (_facingRight ? 58.0 : 12.0))
            : _currentBallX;
        final liveBallY = _isReturning
            ? (curPetY + 62.0)
            : (_currentBallY + throwArc);

        final ballPerspective = PetDepthPerspective.fromScreenY(
          y: liveBallY - 58.0,
          screenHeight: size.height,
          cameraCloseUpFactor: curCloseUp,
        );

        final petWidget =
            (_isSleepingOverlay && _stage != 'egg')
                ? const SizedBox.shrink()
                : Positioned(
                    left: curPetX,
                    top: curPetY,
                    child: PointerInterceptor(
                      child: PetSpriteWidget(
                        stage: _stage,
                        petName: _petName,
                        isSick: _isSick,
                        isSleeping:
                            _sleepingUntil >
                            DateTime.now().millisecondsSinceEpoch,
                        facingRight: _facingRight,
                        equippedAccessories: _equippedAccessories,
                        emotion: emotion,
                        reactionEmoji: _reactionEmoji,
                        isCloseUp: _isCloseUp,
                        isWalkAnimating: _walkController.isAnimating,
                        isChasing: _isChasing,
                        perspective: petPerspective,
                        shakeController: _shakeController,
                        walkController: _walkController,
                        boopController: _boopController,
                        trickController: _trickController,
                        idleController: _idleController,
                        reactionController: _reactionController,
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
                            _strokePet();
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
                      ),
                    ),
                  );

        final ballWidget = (_stage != 'egg')
            ? FetchBallWidget(
                ballX: liveBallX,
                ballY: liveBallY,
                equippedBall: _equippedBall,
                perspective: ballPerspective,
                onPanStart: _onBallPanStart,
                onPanUpdate: _onBallPanUpdate,
                onPanEnd: _onBallPanEnd,
                onTap: _onBallTap,
                isDragging: _isBallDragging,
              )
            : null;

        // 2.5D Painter's Algorithm Z-ordering: object closer to bottom renders in front!
        final petGroundY = curPetY + 95.0;
        final ballGroundY = _currentBallY + 34.0;
        final ballInFrontOfPet =
            _isReturning || (ballGroundY >= petGroundY && !_isCloseUp);

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Ground layer Poos (with 2.5D perspective & background DoF)
            PooLayerWidget(
              poos: _poos,
              onClean: _cleanPoo,
              cameraCloseUpFactor: curCloseUp,
            ),

            if (ballWidget != null && !ballInFrontOfPet) ballWidget,
            petWidget,
            if (ballWidget != null && ballInFrontOfPet) ballWidget,

            // Speech Bubble anchored cleanly above the scaled Shiba's head
            if (_currentSpeech.isNotEmpty &&
                !_isSleepingOverlay &&
                _stage != 'egg')
              SpeechBubbleWidget(
                text: _currentSpeech,
                x: curPetX,
                y: curPetY,
                combinedPetScale: combinedPetScale,
                perspective: petPerspective,
              ),
          ],
        );
      },
    );
  }
}
