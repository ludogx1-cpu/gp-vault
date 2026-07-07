import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../api_constants.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'walk_treadmill_dialog.dart';
import '../src/notification_service.dart';
import '../utils/pet_events.dart';

class ShibaPetWidget extends StatefulWidget {
  const ShibaPetWidget({super.key});

  @override
  State<ShibaPetWidget> createState() => _ShibaPetWidgetState();
}

class _ShibaPetWidgetState extends State<ShibaPetWidget> {
  bool _isLoading = true;
  
  double _hunger = 50;
  double _happiness = 50;
  double _energy = 100;
  double _attention = 50;
  double _totalDistance = 0.0;
  double _ageMultiplier = 1.0;
  double _lockedReturns = 0.0;
  String _petName = 'Golden Paw Shiba';
  String _stage = 'egg'; // Track stage to lock features
  int _xp = 0;
  int _nextStageXp = 100;
  
  int _lastFeedTime = 0;
  int _lastPlayTime = 0;
  int _lastSleepTime = 0;
  int _lastWalkTime = 0;
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

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchPetStatus();
    _loadSleepState();
    // Refresh stats every minute to show decay/growth
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchPetStatus());
  }

  Future<void> _loadSleepState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userWantsSleep = prefs.getBool('pet_sleeping') ?? false;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
            _ageMultiplier = (data['pet']['age_multiplier'] as num?)?.toDouble() ?? 1.0;
            _totalDistance = (data['pet']['total_distance'] as num).toDouble();
            _lockedReturns = (data['pet']['locked_returns'] as num?)?.toDouble() ?? 0.0;
            _petName = data['pet']['name'] ?? 'Golden Paw Shiba';
            _stage = data['pet']['stage'] ?? 'egg'; // Get stage from backend
            _xp = (data['pet']['xp'] as num?)?.toInt() ?? 0;
            _nextStageXp = (data['pet']['next_stage_xp'] as num?)?.toInt() ?? 100;
            _lastFeedTime = (data['pet']['last_feed_time'] as num?)?.toInt() ?? 0;
            _lastPlayTime = (data['pet']['last_play_time'] as num?)?.toInt() ?? 0;
            _lastSleepTime = (data['pet']['last_sleep_time'] as num?)?.toInt() ?? 0;
            _lastWalkTime = (data['pet']['last_walk_time'] as num?)?.toInt() ?? 0;
            _sleepingUntil = (data['pet']['sleeping_until'] as num?)?.toInt() ?? 0;
            _ownedAccessories = List<String>.from(data['pet']['owned_accessories'] ?? []);
            _equippedAccessories = List<String>.from(data['pet']['equipped_accessories'] ?? []);
            _ownedTricks = List<String>.from(data['pet']['owned_tricks'] ?? []);
            _ownedConsumables = Map<String, int>.from(data['pet']['owned_consumables'] ?? {});
            _ownedBalls = List<String>.from(data['pet']['owned_balls'] ?? ['white']);
            _equippedBall = data['pet']['equipped_ball'] ?? 'white';
            _isSick = data['pet']['sick'] ?? false;
            _xpBoostActive = data['pet']['xp_boost_active'] ?? false;
            
            final matured = (data['pet']['matured_returns'] as num?)?.toDouble() ?? 0.0;
            if (matured > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('+${matured.toStringAsFixed(4)} DOGE Investment Matured!'), backgroundColor: Colors.green),
              );
            }

            // Schedule Hunger Notification 1 hour from last feed time
            if (_lastFeedTime > 0) {
              final expectedHungryTime = DateTime.fromMillisecondsSinceEpoch(_lastFeedTime).add(const Duration(hours: 1));
              NotificationService().scheduleHungerNotification(expectedHungryTime);
            }

            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
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
          setState(() {
            _hunger = (data['stats']['hunger'] as num).toDouble();
            _happiness = (data['stats']['happiness'] as num).toDouble();
            _attention = (data['stats']['attention'] as num?)?.toDouble() ?? 50.0;
            _energy = (data['stats']['energy'] as num).toDouble();
            if (data['stats']['xp'] != null) {
              _xp = (data['stats']['xp'] as num).toInt();
            }
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Action successful!'), backgroundColor: Colors.green),
          );
          _fetchPetStatus(); // refresh the locked returns UI immediately
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Action failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Try again later.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatBar(String label, double value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${value.toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildXPBar() {
    double progress = _nextStageXp > 0 ? (_xp / _nextStageXp) * 100 : 100;
    if (progress > 100) progress = 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, size: 14, color: Colors.purple),
            const SizedBox(width: 4),
            const Text("XP (Next Stage)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('$_xp / $_nextStageXp', style: const TextStyle(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.purple.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
      ],
    );
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aged by $days days!'), backgroundColor: Colors.green));
          _fetchPetStatus(); // Refresh UI
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error'), backgroundColor: Colors.red));
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
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'pet_owned_accessories': [
            'top_hat', 'sunglasses', 'gold_chain', 'diamond_watch', 'crown',
            'coat_basic', 'coat_rain', 'coat_winter', 'coat_luxury'
          ],
          'active_trick_buffs': ['Spin', 'Jump', 'Roll Over', 'Backflip', 'Moonwalk'],
          'pet_owned_tricks': ['Spin', 'Jump', 'Roll Over', 'Backflip', 'Moonwalk'],
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin Unlock Successful! Refreshing...'), backgroundColor: Colors.green));
          _fetchPetStatus(); // Refresh UI
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unlock Error: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _renamePet() async {
    final TextEditingController nameController = TextEditingController(text: _petName);
    
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, nameController.text.trim()),
              child: const Text("Save"),
            ),
          ],
        );
      }
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet renamed successfully!'), backgroundColor: Colors.green));
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to rename'), backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;

    final now = DateTime.now().millisecondsSinceEpoch;
    final bool isSleeping = _sleepingUntil > DateTime.now().millisecondsSinceEpoch;
    final bool canFeed = !_isSick && !isSleeping && _hunger < 100 && (DateTime.now().millisecondsSinceEpoch - _lastFeedTime) >= (1 * 60 * 60 * 1000);
    final bool canSleep = !_isSick && !isSleeping && _energy < 100;

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
        border: Border.all(color: isDark ? theme.darkGreyBorder : Colors.amber.shade200, width: 2),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Removed static image since pet now wanders the screen
              const SizedBox(width: 20),
              // Right side: Stats
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_petName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                          onPressed: _renamePet,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 12,
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: _userWantsSleep ? 'Turn Dogeogotcha On' : 'Turn Dogeogotcha Off (Sleep Mode)',
                          child: InkWell(
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();
                              bool newValue = !_userWantsSleep;
                              await prefs.setBool('pet_sleeping', newValue);
                              setState(() {
                                _userWantsSleep = newValue;
                              });
                              PetEvents.toggleSleep(newValue);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(newValue ? 'Dogeogotcha turned off! It will automatically wake up when it needs you.' : 'Dogeogotcha turned on!')),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.white54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.power_settings_new, color: _userWantsSleep ? Colors.blue : Colors.green, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                    _buildStatBar("Attention", _attention, Colors.green, Icons.waving_hand),
                    _buildStatBar("Hunger", _hunger, Colors.orange, Icons.restaurant),
                    _buildStatBar("Happiness", _happiness, Colors.pink, Icons.favorite),
                    _buildStatBar("Energy", _energy, Colors.blue, Icons.bolt),
                    _buildXPBar(),
                    if (_isSick)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text("SICK! Interactions disabled. Buy Medicine from Consumables.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    if (isSleeping)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text("SLEEPING Zzz... Wakes up in ${((_sleepingUntil - DateTime.now().millisecondsSinceEpoch) / 60000).ceil()} mins", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    if (_xpBoostActive)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text("XP BOOST ACTIVE (1.5x)", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    const SizedBox(height: 10),
                    // Action Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: (_isLoading || !canFeed) ? null : () => _performAction('feed'),
                          icon: const Icon(Icons.restaurant, size: 16),
                          label: const Text("Feed", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: canFeed ? Colors.orange : Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),

                        ElevatedButton.icon(
                          onPressed: (_isLoading || !canSleep) ? null : () => _performAction('sleep'),
                          icon: const Icon(Icons.bedtime, size: 16),
                          label: const Text("Sleep", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: canSleep ? Colors.blue : Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                        if (FirebaseAuth.instance.currentUser?.email == 'ludogx1@gmail.com') ...[
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _forceAgeAdmin(-5),
                            icon: const Icon(Icons.fast_rewind, size: 16),
                            label: const Text("-5 Days", style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _forceAgeAdmin(5),
                            icon: const Icon(Icons.fast_forward, size: 16),
                            label: const Text("+5 Days", style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _unlockAllAdmin(),
                            icon: const Icon(Icons.admin_panel_settings, size: 16),
                            label: const Text("Unlock All", style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Age Multiplier: ${_ageMultiplier.toStringAsFixed(2)}x | Walked: ${_totalDistance.toStringAsFixed(0)}m", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    if (_lockedReturns > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text("Locked Returns: ${_lockedReturns.toStringAsFixed(4)} DOGE (Matures in 24h)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                      ),
                    
                    // Tabbed Area (Info, Shop, Tricks)
                    DefaultTabController(
                      length: 5,
                      child: Container(
                        height: 180,
                        margin: const EdgeInsets.only(top: 15),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blueGrey.withValues(alpha: 0.2) : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: isDark ? Colors.amber : Colors.blue.shade800,
                              unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                              indicatorColor: Colors.amber,
                              isScrollable: true,
                              tabs: const [
                                Tab(icon: Icon(Icons.info, size: 20), text: "Info"),
                                Tab(icon: Icon(Icons.shopping_cart, size: 20), text: "Shop"),
                                Tab(icon: Icon(Icons.fastfood, size: 20), text: "Items"),
                                Tab(icon: Icon(Icons.sports_baseball, size: 20), text: "Balls"),
                                Tab(icon: Icon(Icons.star, size: 20), text: "Tricks"),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Info Tab
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        "• Stroke: Stroke your pet to raise Attention & get 5 XP!\n"
                                        "• Fetch: Swipe the ball! Costs Energy & Hunger but boosts Happiness.\n"
                                        "• Boop: Every 30 mins, it walks to the camera. Boop its nose for 0.002 DOGE!\n"
                                        "• Walk: Walk your pet every 3 hours for up to 0.005 DOGE.\n"
                                        "• Sickness: Keep stats above 0! Sick pets can't walk and lose faucet bonuses.\n"
                                        "• Items: Buy Medicine to cure sickness for FREE.",
                                        style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                  // Shop Tab
                                  _stage == 'egg' 
                                  ? const Center(child: Text("Shop unlocks at Baby stage!\n(Wait 2 days or use Admin controls)", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))
                                  : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: [
                                        _buildShopItem('top_hat', 'Fancy Top Hat', 1.0, '+10% PTC Bonus'),
                                        _buildShopItem('sunglasses', 'Cool Shades', 2.0, '+20% PTC Bonus'),
                                        _buildShopItem('gold_chain', 'Gold Chain', 3.0, '+30% PTC Bonus'),
                                        _buildShopItem('diamond_watch', 'Diamond Watch', 5.0, '+50% PTC Bonus'),
                                        _buildShopItem('crown', 'Royal Crown', 10.0, '+100% PTC Bonus'),
                                        _buildShopItem('coat_basic', 'Basic Coat', 1.5, '+15% PTC Bonus'),
                                        _buildShopItem('coat_rain', 'Rain Coat', 2.5, '+25% PTC Bonus'),
                                        _buildShopItem('coat_winter', 'Winter Coat', 4.0, '+40% PTC Bonus'),
                                        _buildShopItem('coat_luxury', 'Luxury Coat', 7.5, '+75% PTC Bonus'),
                                      ],
                                    ),
                                  // Consumables Tab
                                  _stage == 'egg' 
                                  ? const Center(child: Text("Items unlock at Baby stage!\n(Wait 2 days or use Admin controls)", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))
                                  : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: [
                                        _buildConsumableItem('medicine', 'Medicine', 0.0, 'Cures Sickness (FREE)', Icons.local_hospital),
                                      ],
                                    ),
                                  // Balls Tab
                                  _stage == 'egg' 
                                  ? const Center(child: Text("Balls unlock at Baby stage!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))
                                  : ListView(
                                      padding: const EdgeInsets.all(8),
                                      children: [
                                        _buildBallItem('white', 'Classic White', 0.0, '0.0 DOGE | 1 XP'),
                                        _buildBallItem('red', 'Red Ball', 0.25, '0.0001 DOGE | 1 XP'),
                                        _buildBallItem('orange', 'Orange Ball', 0.75, '0.0002 DOGE | 2 XP'),
                                        _buildBallItem('yellow', 'Yellow Ball', 1.25, '0.0003 DOGE | 3 XP'),
                                        _buildBallItem('green', 'Green Ball', 1.75, '0.0004 DOGE | 4 XP'),
                                        _buildBallItem('blue', 'Blue Ball', 2.25, '0.0005 DOGE | 5 XP'),
                                        _buildBallItem('indigo', 'Indigo Ball', 2.75, '0.0006 DOGE | 6 XP'),
                                        _buildBallItem('violet', 'Violet Ball', 3.25, '0.0007 DOGE | 7 XP'),
                                      ],
                                    ),
                                  // Tricks Tab
                                  _stage == 'egg'
                                  ? const Center(child: Text("Tricks unlock at Baby stage!\n(Wait 2 days or use Admin controls)", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))
                                  : Center(
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            _buildTrickButton('Spin', Icons.rotate_right, 1.0, '+10% Sponsor Bonus'),
                                            _buildTrickButton('Jump', Icons.arrow_upward, 2.0, '+20% Sponsor Bonus'),
                                            _buildTrickButton('Roll Over', Icons.replay, 3.0, '+30% Sponsor Bonus'),
                                            _buildTrickButton('Backflip', Icons.loop, 5.0, '+50% Sponsor Bonus'),
                                            _buildTrickButton('Moonwalk', Icons.directions_walk, 10.0, '+100% Sponsor Bonus'),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
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
                final minutes = (remainingWalkMs % (60 * 60 * 1000)) ~/ (60 * 1000);
                walkText = "Walk Cooldown: ${hours}h ${minutes}m";
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || !canWalk) ? null : () => _showWalkDialog(),
                  icon: const Icon(Icons.directions_walk),
                  label: Text(walkText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canWalk ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              );
            }
          )
        ],
      ),
    );
  }

  void _showPurchaseDialog(String title, double usdtPrice, Function(String) onConfirm) {
    final dogePrice = usdtPrice * 8.0; // Static rate matching backend
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Buy $title", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text("Choose your payment method:"),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              Navigator.pop(context);
              onConfirm('usdt');
            },
            child: Text("\$${usdtPrice.toStringAsFixed(2)} USDT", style: const TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              onConfirm('doge');
            },
            child: Text("${dogePrice.toStringAsFixed(2)} DOGE", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem(String id, String name, double price, String bonus) {
    final isOwned = _ownedAccessories.contains(id);
    final isEquipped = _equippedAccessories.contains(id);
    
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Image.asset('assets/shiba_$id.png', width: 30, height: 30, errorBuilder: (c,e,s) => const Icon(Icons.checkroom)),
      title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: isOwned ? Text(bonus, style: const TextStyle(fontSize: 10, color: Colors.green)) : Text('\$$price USDT (Ad Credit)\n$bonus', style: const TextStyle(fontSize: 10, color: Colors.amber)),
      trailing: isOwned
          ? ElevatedButton(
              onPressed: () => _equipAccessory(id, !isEquipped),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEquipped ? Colors.grey : Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(60, 30),
              ),
              child: Text(isEquipped ? "Unequip" : "Equip", style: const TextStyle(fontSize: 10, color: Colors.white)),
            )
          : ElevatedButton(
              onPressed: () {
                _showPurchaseDialog(name, price, (currency) => _buyAccessory(id, currency));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(60, 30),
              ),
              child: const Text("Buy", style: TextStyle(fontSize: 10, color: Colors.black)),
            ),
    );
  }

  Widget _buildConsumableItem(String id, String name, double price, String desc, IconData icon) {
    final count = _ownedConsumables[id] ?? 0;
    
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 30, color: Colors.amber),
      title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: Text('Owned: $count\n$desc', style: const TextStyle(fontSize: 10, color: Colors.grey)),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (count > 0)
            ElevatedButton(
              onPressed: () => _useConsumable(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 30),
              ),
              child: const Text("Use", style: TextStyle(fontSize: 10, color: Colors.white)),
            ),
          ElevatedButton(
            onPressed: () {
              if (price == 0.0) {
                _buyConsumable(id, 'doge');
              } else {
                _showPurchaseDialog(name, price, (currency) => _buyConsumable(id, currency));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(50, 30),
            ),
            child: Text(price == 0.0 ? "FREE" : "\$$price", style: const TextStyle(fontSize: 10, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildBallItem(String color, String name, double price, String bonus) {
    final isOwned = _ownedBalls.contains(color);
    final isEquipped = _equippedBall == color;
    
    Color ballColor = Colors.white;
    switch(color) {
      case 'red': ballColor = Colors.red; break;
      case 'orange': ballColor = Colors.orange; break;
      case 'yellow': ballColor = Colors.yellow; break;
      case 'green': ballColor = Colors.green; break;
      case 'blue': ballColor = Colors.blue; break;
      case 'indigo': ballColor = Colors.indigo; break;
      case 'violet': ballColor = Colors.purple; break;
    }

    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Container(width: 20, height: 20, decoration: BoxDecoration(color: ballColor, shape: BoxShape.circle, border: Border.all(color: Colors.black))),
      title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: isOwned ? Text(bonus, style: const TextStyle(fontSize: 10, color: Colors.green)) : Text('\$$price USDT (Ad Credit)\n$bonus', style: const TextStyle(fontSize: 10, color: Colors.amber)),
      trailing: isOwned
          ? ElevatedButton(
              onPressed: isEquipped ? null : () => _equipBall(color),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEquipped ? Colors.grey : Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(60, 30),
              ),
              child: Text(isEquipped ? "Equipped" : "Equip", style: const TextStyle(fontSize: 10, color: Colors.white)),
            )
          : ElevatedButton(
              onPressed: () {
                _showPurchaseDialog(name, price, (currency) => _buyBall(color, currency));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(60, 30),
              ),
              child: const Text("Buy", style: TextStyle(fontSize: 10, color: Colors.black)),
            ),
    );
  }

  Widget _buildTrickButton(String name, IconData icon, double price, String bonus) {
    final isOwned = _ownedTricks.contains(name);
    return Tooltip(
      message: isOwned ? 'Perform $name' : 'Buy $name for \$$price USDT / ${price * 8.0} DOGE ($bonus)',
      child: ElevatedButton.icon(
        onPressed: () {
          if (isOwned) {
            _performTrick(name);
          } else {
            _showPurchaseDialog(name, price, (currency) => _buyTrick(name, currency));
          }
        },
        icon: Icon(isOwned ? icon : Icons.lock, size: 16),
        label: Text(isOwned ? name : 'Buy'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOwned ? Colors.purple.shade400 : Colors.grey.shade700,
          foregroundColor: Colors.white,
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ball purchased!'), backgroundColor: Colors.green));
        _fetchPetStatus();
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error'), backgroundColor: Colors.red));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ball equipped!'), backgroundColor: Colors.green));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Trick learned!'), backgroundColor: Colors.green));
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to buy'), backgroundColor: Colors.red));
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
          _ownedAccessories.add(id);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Purchased!'), backgroundColor: Colors.green));
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to buy'), backgroundColor: Colors.red));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Purchased!'), backgroundColor: Colors.green));
        _fetchPetStatus();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to buy'), backgroundColor: Colors.red));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Item used!'), backgroundColor: Colors.green));
        _fetchPetStatus();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to use'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _equipAccessory(String id, bool equip) async {
    if (equip && _equippedAccessories.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 3 items equipped! Unequip something first.'), backgroundColor: Colors.orange));
      return;
    }

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
          if (equip) {
            _equippedAccessories.add(id);
          } else {
            _equippedAccessories.remove(id);
          }
          _isLoading = false;
        });
        // We broadcast an event so the pet overlay can update immediately
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
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
        // Notify overlay to perform animation
        PetEvents.performTrick(trickName);
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Too tired!'), backgroundColor: Colors.red));
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
      builder: (context) => const WalkTreadmillDialog(),
    ).then((_) => _fetchPetStatus()); // Refresh stats after walk
  }

}
