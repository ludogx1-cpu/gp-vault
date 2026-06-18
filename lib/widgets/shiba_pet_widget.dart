import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../api_constants.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'walk_treadmill_dialog.dart';
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
  double _totalDistance = 0.0;
  double _ageMultiplier = 1.0;
  double _lockedReturns = 0.0;
  String _petName = 'Golden Paw Shiba';
  
  int _lastFeedTime = 0;
  int _lastPlayTime = 0;
  int _lastSleepTime = 0;
  List<String> _ownedAccessories = [];
  List<String> _equippedAccessories = [];
  List<String> _ownedTricks = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchPetStatus();
    // Refresh stats every minute to show decay/growth
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchPetStatus());
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
            _ageMultiplier = (data['pet']['age_multiplier'] as num?)?.toDouble() ?? 1.0;
            _totalDistance = (data['pet']['total_distance'] as num).toDouble();
            _lockedReturns = (data['pet']['locked_returns'] as num?)?.toDouble() ?? 0.0;
            _petName = data['pet']['name'] ?? 'Golden Paw Shiba';
            _lastFeedTime = (data['pet']['last_feed_time'] as num?)?.toInt() ?? 0;
            _lastPlayTime = (data['pet']['last_play_time'] as num?)?.toInt() ?? 0;
            _lastSleepTime = (data['pet']['last_sleep_time'] as num?)?.toInt() ?? 0;
            _ownedAccessories = List<String>.from(data['pet']['owned_accessories'] ?? []);
            _equippedAccessories = List<String>.from(data['pet']['equipped_accessories'] ?? []);
            _ownedTricks = List<String>.from(data['pet']['owned_tricks'] ?? []);
            
            final matured = (data['pet']['matured_returns'] as num?)?.toDouble() ?? 0.0;
            if (matured > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('+${matured.toStringAsFixed(4)} DOGE Investment Matured!'), backgroundColor: Colors.green),
              );
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
            _energy = (data['stats']['energy'] as num).toDouble();
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
    final bool canFeed = now - _lastFeedTime >= 3 * 60 * 60 * 1000;
    final bool canPlay = now - _lastPlayTime >= 3 * 60 * 60 * 1000;
    final bool canSleep = now - _lastSleepTime >= 3 * 60 * 60 * 1000;

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
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatBar("Hunger", _hunger, Colors.orange, Icons.restaurant),
                    _buildStatBar("Happiness", _happiness, Colors.pink, Icons.favorite),
                    _buildStatBar("Energy", _energy, Colors.blue, Icons.bolt),
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
                          label: const Text("Feed (0.0001)", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: canFeed ? Colors.orange : Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                        ElevatedButton.icon(
                          onPressed: (_isLoading || !canPlay) ? null : () => _performAction('play'),
                          icon: const Icon(Icons.sports_baseball, size: 16),
                          label: const Text("Play (0.0001)", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: canPlay ? Colors.pink : Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                        ElevatedButton.icon(
                          onPressed: (_isLoading || !canSleep) ? null : () => _performAction('sleep'),
                          icon: const Icon(Icons.bedtime, size: 16),
                          label: const Text("Sleep (0.0001)", style: TextStyle(fontSize: 11)),
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
                      length: 3,
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
                              tabs: const [
                                Tab(icon: Icon(Icons.info, size: 20), text: "Info"),
                                Tab(icon: Icon(Icons.shopping_cart, size: 20), text: "Shop"),
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
                                        "• Your pet wanders around the screen!\n"
                                        "• Every 15 mins, it walks to the camera. Boop its nose for 0.002 DOGE!\n"
                                        "• Watch thought bubbles (💤, 🍖, ❤️).\n"
                                        "• Buy items and perform tricks!",
                                        style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                  // Shop Tab
                                  ListView(
                                    padding: const EdgeInsets.all(8),
                                    children: [
                                      _buildShopItem('top_hat', 'Fancy Top Hat', 1.0, '+10% Faucet Bonus'),
                                      _buildShopItem('sunglasses', 'Cool Shades', 2.0, '+20% Faucet Bonus'),
                                      _buildShopItem('gold_chain', 'Gold Chain', 3.0, '+30% Faucet Bonus'),
                                      _buildShopItem('diamond_watch', 'Diamond Watch', 5.0, '+50% Faucet Bonus'),
                                      _buildShopItem('crown', 'Royal Crown', 10.0, '+100% Faucet Bonus'),
                                      _buildShopItem('coat_basic', 'Basic Coat', 1.5, '+15% Faucet Bonus'),
                                      _buildShopItem('coat_rain', 'Rain Coat', 2.5, '+25% Faucet Bonus'),
                                      _buildShopItem('coat_winter', 'Winter Coat', 4.0, '+40% Faucet Bonus'),
                                      _buildShopItem('coat_luxury', 'Luxury Coat', 7.5, '+75% Faucet Bonus'),
                                    ],
                                  ),
                                  // Tricks Tab
                                  Center(
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          _buildTrickButton('Spin', Icons.rotate_right, 1.0, '+10% Bonus'),
                                          _buildTrickButton('Jump', Icons.arrow_upward, 2.0, '+20% Bonus'),
                                          _buildTrickButton('Roll Over', Icons.replay, 3.0, '+30% Bonus'),
                                          _buildTrickButton('Backflip', Icons.loop, 5.0, '+50% Bonus'),
                                          _buildTrickButton('Moonwalk', Icons.directions_walk, 10.0, '+100% Bonus'),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _showWalkDialog(),
              icon: const Icon(Icons.directions_walk),
              label: const Text("Take for a Walk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )
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
              onPressed: () => _buyAccessory(id),
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
      message: isOwned ? 'Perform $name' : 'Buy $name for \$$price USDT ($bonus)',
      child: ElevatedButton.icon(
        onPressed: () => isOwned ? _performTrick(name) : _buyTrick(name),
        icon: Icon(isOwned ? icon : Icons.lock, size: 16),
        label: Text(isOwned ? name : '\$$price'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOwned ? Colors.purple.shade400 : Colors.grey.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _buyTrick(String name) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-buy-trick'),
        headers: headers,
        body: jsonEncode({'trickName': name}),
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

  Future<void> _buyAccessory(String id) async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-buy-accessory'),
        headers: headers,
        body: jsonEncode({'accessoryId': id}),
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
