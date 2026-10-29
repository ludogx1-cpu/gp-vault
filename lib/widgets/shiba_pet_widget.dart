import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:provider/provider.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../api_constants.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'walk_treadmill_dialog.dart';
import '../src/notification_service.dart';
import '../utils/pet_events.dart';
import '../repositories/pet_repository.dart';
import 'pet/pet_tabs_widget.dart';
import 'pet/pet_stats_bar.dart';
import 'pet/pet_xp_bar.dart';
import 'pet/pet_sprite_widget.dart';
import 'pet/pet_collar_painter.dart';

class ShibaPetWidget extends StatefulWidget {
  const ShibaPetWidget({super.key});

  @override
  State<ShibaPetWidget> createState() => _ShibaPetWidgetState();
}

class _ShibaPetWidgetState extends State<ShibaPetWidget>
    with TickerProviderStateMixin {
  bool _isLoading = true;

  double _hunger = 50;
  double _happiness = 50;
  double _energy = 100;
  double _attention = 50;
  double _totalDistance = 0.0;
  double _ageMultiplier = 1.0;
  String _petName = 'Golden Paw Shiba';
  String _stage = 'egg';
  int _xp = 0;
  int _nextStageXp = 100;

  int _lastFeedTime = 0;
  int _lastPlayTime = 0;
  int _lastWalkTime = 0;
  int _lastBoopTime = 0;
  List<String> _ownedAccessories = [];
  List<String> _equippedAccessories = [];
  List<String> _ownedTricks = [];
  Map<String, int> _ownedConsumables = {};
  List<String> _ownedBalls = [];
  String _equippedBall = 'white';
  bool _isSick = false;
  int _sleepingUntil = 0;
  bool _xpBoostActive = false;
  bool _userWantsSleep = false;
  bool _canAffordAction = false;
  double _pendingReturnTotal = 0.0;

  Timer? _refreshTimer;
  StreamSubscription? _refreshSubscription;
  late AnimationController _cardIdleController;
  late AnimationController _cardReactionController;
  String _cardReactionEmoji = '';

  @override
  void initState() {
    super.initState();
    _cardIdleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _cardReactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fetchPetStatus();
    _loadSleepState();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchPetStatus(),
    );
    _refreshSubscription = PetEvents.refreshStream.listen((_) {
      if (mounted) _fetchPetStatus();
    });
  }

  void _showCardReaction(String emoji) {
    if (!mounted) return;
    setState(() => _cardReactionEmoji = emoji);
    _cardReactionController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _cardReactionEmoji = '');
    });
  }

  Future<void> _loadSleepState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userWantsSleep = prefs.getBool('pet_sleeping') ?? false;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshSubscription?.cancel();
    _cardIdleController.dispose();
    _cardReactionController.dispose();
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
            _hunger = (data['pet']['hunger'] as num).toDouble();
            _happiness = (data['pet']['happiness'] as num).toDouble();
            _energy = (data['pet']['energy'] as num).toDouble();
            _attention = (data['pet']['attention'] as num?)?.toDouble() ?? 50.0;
            _ageMultiplier =
                (data['pet']['age_multiplier'] as num?)?.toDouble() ?? 1.0;
            _totalDistance = (data['pet']['total_distance'] as num).toDouble();
            _petName = data['pet']['name'] ?? 'Golden Paw Shiba';
            _stage = data['pet']['stage'] ?? 'egg';
            _xp = (data['pet']['xp'] as num?)?.toInt() ?? 0;
            _nextStageXp =
                (data['pet']['next_stage_xp'] as num?)?.toInt() ?? 100;
            _lastFeedTime =
                (data['pet']['last_feed_time'] as num?)?.toInt() ?? 0;
            _lastPlayTime =
                (data['pet']['last_play_time'] as num?)?.toInt() ?? 0;
            _lastWalkTime =
                (data['pet']['last_walk_time'] as num?)?.toInt() ?? 0;
            _lastBoopTime =
                (data['pet']['last_boop_time'] as num?)?.toInt() ?? 0;
            _sleepingUntil =
                (data['pet']['sleeping_until'] as num?)?.toInt() ?? 0;
            _ownedAccessories = PetCollars.normalizeList(
              List<String>.from(data['pet']['owned_accessories'] ?? []),
            );
            _equippedAccessories = PetCollars.normalizeList(
              List<String>.from(data['pet']['equipped_accessories'] ?? []),
            );
            _ownedTricks = List<String>.from(data['pet']['owned_tricks'] ?? []);
            _ownedConsumables = Map<String, int>.from(
              data['pet']['owned_consumables'] ?? {},
            );
            _ownedBalls = List<String>.from(
              data['pet']['owned_balls'] ?? ['white'],
            );
            _equippedBall = data['pet']['equipped_ball'] ?? 'white';
            _isSick = data['pet']['sick'] ?? false;
            _xpBoostActive = data['pet']['xp_boost_active'] ?? false;
            _canAffordAction = data['pet']['can_afford_action'] ?? false;
            _pendingReturnTotal =
                (data['pet']['pending_return_total'] as num?)?.toDouble() ??
                0.0;

            if (_lastFeedTime > 0) {
              final expectedHungryTime = DateTime.fromMillisecondsSinceEpoch(
                _lastFeedTime,
              ).add(const Duration(hours: 1));
              NotificationService().scheduleHungerNotification(
                expectedHungryTime,
              );
            }

            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performAction(String action) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-$action'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          final emoji = action == 'feed'
              ? '🍖'
              : (action == 'play'
                    ? '🎾'
                    : (action == 'sleep' ? '💤' : '❤️'));
          _showCardReaction(emoji);
          PetEvents.notifyStatusChanged(reactionEmoji: emoji);

          setState(() {
            if (action == 'boop') {
              _lastBoopTime = DateTime.now().millisecondsSinceEpoch;
            }
            if (data['stats'] != null) {
              _hunger =
                  (data['stats']['hunger'] as num?)?.toDouble() ?? _hunger;
              _happiness =
                  (data['stats']['happiness'] as num?)?.toDouble() ??
                  _happiness;
              _attention =
                  (data['stats']['attention'] as num?)?.toDouble() ??
                  _attention;
              _energy =
                  (data['stats']['energy'] as num?)?.toDouble() ?? _energy;
              if (data['stats']['xp'] != null) {
                _xp = (data['stats']['xp'] as num).toInt();
              }
            }
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Action successful!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchPetStatus();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Action failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _forceAgeAdmin(int days) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-admin-age-up'),
        headers: headers,
        body: jsonEncode({'days': days}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aged by $days days!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchPetStatus();
          PetEvents.notifyStatusChanged(reactionEmoji: '✨');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Error'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlockAllAdmin() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await PetRepository.unlockAllAdmin(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin Unlock Successful! Refreshing...'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchPetStatus();
          PetEvents.notifyStatusChanged(reactionEmoji: '👑');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlock Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _renamePet() async {
    final TextEditingController nameController = TextEditingController(
      text: _petName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Name Your Shiba"),
          content: TextField(
            controller: nameController,
            maxLength: 20,
            decoration: const InputDecoration(
              hintText: "Enter a cool name...",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != _petName) {
      setState(() => _isLoading = true);
      try {
        final headers = await getAuthHeaders();
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/pet-rename'),
          headers: headers,
          body: jsonEncode({'newName': newName}),
        );
        final data = jsonDecode(response.body);
        if (data['success'] && mounted) {
          setState(() {
            _petName = newName;
            _isLoading = false;
          });
          PetEvents.notifyStatusChanged(reactionEmoji: '✨');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pet renamed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['error'] ?? 'Failed to rename'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLivePetAvatar(bool isDark, bool isSleeping, bool boopReady) {
    final activeCollar = PetCollars.resolveActiveCollar(_equippedAccessories);
    return GestureDetector(
      onTap: () {
        if (isSleeping || _isSick) return;
        if (boopReady) {
          _performAction('boop');
        } else {
          _performAction('stroke');
        }
      },
      child: Container(
        width: 118,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey.shade900, Colors.black45]
                : [Colors.amber.shade100, Colors.white],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: boopReady
                ? Colors.pinkAccent
                : (activeCollar?.primaryColor ?? Colors.amber).withValues(
                    alpha: 0.72,
                  ),
            width: boopReady ? 2.0 : 1.3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activeCollar != null && _stage != 'egg') ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: activeCollar.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black54, width: 0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      _stage.replaceAll('_', ' ').toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.amber : Colors.brown.shade800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 95,
              height: 95,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _cardIdleController,
                  _cardReactionController,
                ]),
                builder: (context, _) {
                  final nowMs = DateTime.now().millisecondsSinceEpoch;
                  final t = _cardIdleController.value;
                  final wave = sin(t * pi * 2);
                  final scaleY = isSleeping
                      ? 1.0 + (wave * 0.02)
                      : 1.0 + (wave * 0.042);
                  final scaleX = isSleeping
                      ? 1.0 - (wave * 0.015)
                      : 1.0 - (wave * 0.028);
                  final liftY = isSleeping ? 0.0 : -wave.abs() * 3.5;
                  final curiousTilt =
                      (isSleeping || _isSick || _stage == 'egg')
                      ? 0.0
                      : PetSpriteWidget.computeCuriousHeadTilt(nowMs);
                  final tilt = (isSleeping || _stage == 'egg')
                      ? 0.0
                      : (sin(t * pi * 2) * 0.030) + curiousTilt;
                  final reactionBurst = _cardReactionController.isAnimating
                      ? sin(_cardReactionController.value * pi * 4) * 0.26
                      : 0.0;
                  final collarSwing = (isSleeping || _stage == 'egg')
                      ? 0.0
                      : (cos(t * pi * 2) * 0.09) -
                            (curiousTilt * 1.4) +
                            reactionBurst;

                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Soft ground shadow
                      Positioned(
                        bottom: 2,
                        child: Container(
                          width: 58,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, liftY),
                        child: Transform.rotate(
                          angle: tilt,
                          child: Transform.scale(
                            scaleX: scaleX,
                            scaleY: scaleY,
                            alignment: Alignment.bottomCenter,
                            child: PetSpriteWidget.buildDressedShiba(
                              stage: _stage,
                              isSick: _isSick,
                              equippedAccessories: _equippedAccessories,
                              size: 88,
                              isSleeping: isSleeping,
                              isHappy: _cardReactionController.isAnimating,
                              collarSwingAngle: collarSwing,
                            ),
                          ),
                        ),
                      ),
                      if (isSleeping)
                        Positioned(
                          top: -4 + (wave * 3),
                          right: 0,
                          child: const Text(
                            "💤",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      if (_cardReactionEmoji.isNotEmpty &&
                          _cardReactionController.isAnimating)
                        Positioned(
                          top: -15 - (_cardReactionController.value * 25),
                          child: Opacity(
                            opacity: (1.0 - _cardReactionController.value)
                                .clamp(0.0, 1.0),
                            child: Text(
                              _cardReactionEmoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              boopReady
                  ? "🐾 Tap to Boop!"
                  : (isSleeping ? "Sleeping..." : "Tap to Pet ❤️"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: boopReady
                    ? Colors.pinkAccent
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;

    final now = DateTime.now().millisecondsSinceEpoch;
    final bool isSleeping = _sleepingUntil > now;
    final bool canFeed =
        !_isSick &&
        !isSleeping &&
        _hunger < 100 &&
        (now - _lastFeedTime) >= (1 * 60 * 60 * 1000);
    final bool canPlay =
        !_isSick &&
        !isSleeping &&
        _happiness < 100 &&
        (now - _lastPlayTime) >= (5 * 60 * 60 * 1000);
    final bool canSleep = !_isSick && !isSleeping && _energy < 100;
    final bool boopReady = !_isSick && !isSleeping && (now - _lastBoopTime) >= (29 * 60 * 1000);

    if (_isLoading && _hunger == 50 && _energy == 100) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.darkGreyBoxColor : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Interactive Live Shiba Stage inside the card!
              _buildLivePetAvatar(isDark, isSleeping, boopReady),
              const SizedBox(width: 14),
              // Right side: Stats
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _petName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed: _renamePet,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 12,
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: _userWantsSleep
                              ? 'Show Wandering Shiba on Screen'
                              : 'Hide Wandering Shiba (Sleep Mode)',
                          child: InkWell(
                            onTap: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              bool newValue = !_userWantsSleep;
                              await prefs.setBool('pet_sleeping', newValue);
                              setState(() {
                                _userWantsSleep = newValue;
                              });
                              PetEvents.toggleSleep(newValue);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      newValue
                                          ? 'Wandering Shiba hidden! You can still interact with your Shiba right here in the card.'
                                          : 'Wandering Shiba enabled!',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.white54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.power_settings_new,
                                color: _userWantsSleep
                                    ? Colors.blue
                                    : Colors.green,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    PetStatBar(
                      label: "Attention",
                      value: _attention,
                      color: Colors.green,
                      icon: Icons.waving_hand,
                    ),
                    PetStatBar(
                      label: "Hunger",
                      value: _hunger,
                      color: Colors.orange,
                      icon: Icons.restaurant,
                    ),
                    PetStatBar(
                      label: "Happiness",
                      value: _happiness,
                      color: Colors.pink,
                      icon: Icons.favorite,
                    ),
                    PetStatBar(
                      label: "Energy",
                      value: _energy,
                      color: Colors.blue,
                      icon: Icons.bolt,
                    ),
                    const SizedBox(height: 10),
                    PetXpBar(xp: _xp, nextStageXp: _nextStageXp),
                  ],
                ),
              ),
            ],
          ),
          if (_isSick)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "SICK! Interactions disabled. Buy Medicine from Items tab (FREE).",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          if (isSleeping)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "SLEEPING Zzz... Wakes up in ${((_sleepingUntil - now) / 60000).ceil()} mins",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          if (_xpBoostActive)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "XP BOOST ACTIVE (1.5x)",
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 10),
          // Action Buttons (Feed, Play, Sleep, Boop)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: (_isLoading || !canFeed)
                    ? null
                    : () => _performAction('feed'),
                icon: const Icon(Icons.restaurant, size: 16),
                label: Text(
                  _canAffordAction
                      ? "Feed (0.005 → 2x 24h)"
                      : "Feed (FREE → 1.5x 24h)",
                  style: const TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canFeed ? Colors.orange : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: (_isLoading || !canPlay)
                    ? null
                    : () => _performAction('play'),
                icon: const Icon(Icons.sports_tennis, size: 16),
                label: Text(
                  _canAffordAction
                      ? "Play (0.005 → 2x 24h)"
                      : "Play (FREE → 1.5x 24h)",
                  style: const TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canPlay ? Colors.pink : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: (_isLoading || !canSleep)
                    ? null
                    : () => _performAction('sleep'),
                icon: const Icon(Icons.bedtime, size: 16),
                label: const Text("Sleep", style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSleep ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                ),
              ),
              if (boopReady)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _performAction('boop'),
                  icon: const Icon(Icons.pets, size: 16),
                  label: const Text(
                    "Boop (+0.004)",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                  ),
                ),
              if (FirebaseAuth.instance.currentUser?.uid ==
                  ApiConstants.adminUid) ...[
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _forceAgeAdmin(-5),
                  icon: const Icon(Icons.fast_rewind, size: 16),
                  label: const Text("-5 Days", style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _forceAgeAdmin(5),
                  icon: const Icon(Icons.fast_forward, size: 16),
                  label: const Text("+5 Days", style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _unlockAllAdmin(),
                  icon: const Icon(Icons.admin_panel_settings, size: 16),
                  label: const Text(
                    "Unlock All",
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Age Multiplier: ${_ageMultiplier.toStringAsFixed(2)}x | Walked: ${_totalDistance.toStringAsFixed(0)}m",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          if (_pendingReturnTotal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "⏳ Pending 24h Care Returns: +${_pendingReturnTotal.toStringAsFixed(4)} DOGE",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),

          // Tabbed Area (Info, Shop, Items, Balls, Tricks)
          PetTabsWidget(
            data: PetTabsData(
              stage: _stage,
              isDark: isDark,
              ownedAccessories: _ownedAccessories,
              equippedAccessories: _equippedAccessories,
              ownedTricks: _ownedTricks,
              ownedConsumables: _ownedConsumables,
              ownedBalls: _ownedBalls,
              equippedBall: _equippedBall,
            ),
            callbacks: PetTabsCallbacks(
              onEquipAccessory: (id, equip) => _equipAccessory(id, equip),
              onBuyAccessory: (id, price) => _showPurchaseDialog(
                PetCollars.byId(id).name,
                price,
                (currency) => _buyAccessory(id, currency),
              ),
              onUseConsumable: (id) => _useConsumable(id),
              onBuyConsumable: (id, price) {
                if (price == 0.0) {
                  _buyConsumable(id, 'doge');
                } else {
                  _showPurchaseDialog(
                    id,
                    price,
                    (currency) => _buyConsumable(id, currency),
                  );
                }
              },
              onEquipBall: (color) => _equipBall(color),
              onBuyBall: (color, price) => _showPurchaseDialog(
                '${color[0].toUpperCase()}${color.substring(1)} Ball',
                price,
                (currency) => _buyBall(color, currency),
              ),
              onPerformTrick: (name) => _performTrick(name),
              onBuyTrick: (name, price) => _showPurchaseDialog(
                name,
                price,
                (currency) => _buyTrick(name, currency),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Divider(color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final walkCooldown = 3 * 60 * 60 * 1000;
              final timeSinceWalk = now - _lastWalkTime;
              final canWalk = timeSinceWalk >= walkCooldown;
              final remainingWalkMs = walkCooldown - timeSinceWalk;
              String walkText = "Take for a Walk";
              if (!canWalk) {
                final hours = remainingWalkMs ~/ (60 * 60 * 1000);
                final minutes =
                    (remainingWalkMs % (60 * 60 * 1000)) ~/ (60 * 1000);
                walkText = "Walk Cooldown: ${hours}h ${minutes}m";
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || !canWalk)
                      ? null
                      : () => _showWalkDialog(),
                  icon: const Icon(Icons.directions_walk),
                  label: Text(
                    walkText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canWalk ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(
    String title,
    double usdtPrice,
    Function(String) onConfirm,
  ) {
    final dogePrice = usdtPrice * 8.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Buy $title",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text("Choose your payment method:"),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              Navigator.pop(context);
              onConfirm('usdt');
            },
            child: Text(
              "\$${usdtPrice.toStringAsFixed(2)} USDT",
              style: const TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              onConfirm('doge');
            },
            child: Text(
              "${dogePrice.toStringAsFixed(2)} DOGE",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buyBall(String color, String currency) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-buy-ball'),
        headers: headers,
        body: jsonEncode({'color': color, 'currency': currency}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ball purchased!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPetStatus();
        PetEvents.notifyStatusChanged(reactionEmoji: '🎾');
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _equipBall(String color) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-equip-ball'),
        headers: headers,
        body: jsonEncode({'color': color}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ball equipped!'),
            backgroundColor: Colors.green,
          ),
        );
        PetEvents.equipBall(color);
        _fetchPetStatus();
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _buyTrick(String name, String currency) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-buy-trick'),
        headers: headers,
        body: jsonEncode({'trickName': name, 'currency': currency}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        setState(() {
          _ownedTricks.add(name);
          _isLoading = false;
        });
        PetEvents.notifyStatusChanged(reactionEmoji: '🌟');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Trick learned!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to buy'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _buyAccessory(String id, String currency) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-buy-accessory'),
        headers: headers,
        body: jsonEncode({'accessoryId': id, 'currency': currency}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        setState(() {
          if (!_ownedAccessories.contains(id)) {
            _ownedAccessories.add(id);
          }
          _equippedAccessories = [id];
          _isLoading = false;
        });
        _showCardReaction('✨');
        PetEvents.equipCollar(_equippedAccessories);
        PetEvents.notifyStatusChanged(reactionEmoji: '✨');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? '${PetCollars.byId(id).name} equipped!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to buy'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _buyConsumable(String id, String currency) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-buy-consumable'),
        headers: headers,
        body: jsonEncode({'itemId': id, 'currency': currency}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Purchased!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPetStatus();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to buy'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useConsumable(String id) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-use-consumable'),
        headers: headers,
        body: jsonEncode({'itemId': id}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        _showCardReaction('💊');
        PetEvents.notifyStatusChanged(reactionEmoji: '💊');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Item used!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPetStatus();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to use'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _equipAccessory(String id, bool equip) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-equip-accessory'),
        headers: headers,
        body: jsonEncode({'accessoryId': id, 'equip': equip}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        setState(() {
          _equippedAccessories = equip ? [id] : [];
          _isLoading = false;
        });
        _showCardReaction('✨');
        PetEvents.equipCollar(_equippedAccessories);
        PetEvents.notifyStatusChanged(reactionEmoji: '✨');
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to update collar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performTrick(String trickName) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-trick'),
        headers: headers,
        body: jsonEncode({'trickName': trickName}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        setState(() {
          _happiness = (data['stats']['happiness'] as num).toDouble();
          _energy = (data['stats']['energy'] as num).toDouble();
          _isLoading = false;
        });
        _showCardReaction('🌟');
        PetEvents.performTrick(trickName);
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Too tired!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showWalkDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WalkTreadmillDialog(
        stage: _stage,
        equippedAccessories: _equippedAccessories,
      ),
    ).then((_) {
      _fetchPetStatus();
      PetEvents.notifyStatusChanged(reactionEmoji: '🐾');
    });
  }
}
