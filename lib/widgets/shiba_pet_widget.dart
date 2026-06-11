import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../src/user_provider.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../api_constants.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class ShibaPetWidget extends StatefulWidget {
  const ShibaPetWidget({super.key});

  @override
  State<ShibaPetWidget> createState() => _ShibaPetWidgetState();
}

class _ShibaPetWidgetState extends State<ShibaPetWidget> {
  bool _isLoading = true;
  String _error = "";
  
  double _hunger = 50;
  double _happiness = 50;
  double _energy = 100;
  double _totalDistance = 0.0;
  double _ageMultiplier = 1.0;
  double _lockedReturns = 0.0;
  String _petName = 'Golden Paw Shiba';

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

  Future<void> _forceAgeUpAdmin() async {
    setState(() => _isLoading = true);
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-admin-age-up'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aged up 30 days!'), backgroundColor: Colors.green));
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
                          onPressed: _isLoading ? null : () => _performAction('feed'),
                          icon: const Icon(Icons.restaurant, size: 16),
                          label: const Text("Feed (0.0001)", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _performAction('play'),
                          icon: const Icon(Icons.sports_baseball, size: 16),
                          label: const Text("Play (0.0001)", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _performAction('sleep'),
                          icon: const Icon(Icons.bedtime, size: 16),
                          label: const Text("Sleep (0.0001)", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                        if (FirebaseAuth.instance.currentUser?.email == 'ludogx1@gmail.com')
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _forceAgeUpAdmin,
                            icon: const Icon(Icons.fast_forward, size: 16),
                            label: const Text("Admin: +30 Days", style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Age Multiplier: ${_ageMultiplier.toStringAsFixed(2)}x | Walked: ${_totalDistance.toStringAsFixed(0)}m", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    if (_lockedReturns > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text("Locked Returns: ${_lockedReturns.toStringAsFixed(4)} DOGE (Matures in 24h)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                      ),
                    
                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 15),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blueGrey.withOpacity(0.2) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pets, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text("Dogeogotcha", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "• Your pet now waddles around the screen!\n"
                            "• Every 15 mins, it may walk up to the camera. Tap its nose to 'Boop' it for a 0.002 DOGE reward!\n"
                            "• Watch its thought bubbles (💤, 🍖, ❤️) to see how it's feeling.\n"
                            "• More features coming soon!",
                            style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ],
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
              onPressed: null, // Disabled for now
              icon: const Icon(Icons.directions_walk),
              label: const Text("Take for a Walk (Feature coming soon)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // Grey out
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
}
