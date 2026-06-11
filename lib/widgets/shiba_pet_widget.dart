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
  String _stage = 'puppy';
  double _totalDistance = 0;
  double _ageMultiplier = 1.0;

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
            _stage = data['pet']['stage'];
            _ageMultiplier = (data['pet']['age_multiplier'] as num?)?.toDouble() ?? 1.0;
            _totalDistance = (data['pet']['total_distance'] as num).toDouble();
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
        }
        // Force refresh user provider to update doge balance if fed
        // The user provider automatically listens to Firestore, so it will update itself!
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

  String _getImageAsset() {
    switch (_stage) {
      case 'egg': return 'assets/shiba_egg.png';
      case 'teen': return 'assets/shiba_teen.png';
      case 'adult': return 'assets/shiba_adult.png';
      case 'puppy':
      default: return 'assets/shiba_puppy.png';
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
              // Left side: Shiba Image
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text("Your Shiba ${_stage.toUpperCase()}", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.amber : Colors.brown)),
                    const SizedBox(height: 10),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(_getImageAsset(), fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 8),
                    Text("Age Multiplier: ${_ageMultiplier.toStringAsFixed(2)}x", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text("Walked: ${_totalDistance.toStringAsFixed(0)}m", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Right side: Stats
              Expanded(
                flex: 3,
                child: Column(
                  children: [
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
                          label: const Text("Feed (0.05 DOGE)", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _performAction('play'),
                          icon: const Icon(Icons.sports_baseball, size: 16),
                          label: const Text("Play", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _performAction('sleep'),
                          icon: const Icon(Icons.bedtime, size: 16),
                          label: const Text("Sleep", style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                        ),
                      ],
                    )
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
              onPressed: () => context.go('/walk-pet'),
              icon: const Icon(Icons.directions_walk),
              label: const Text("Take for a Walk (Earn DOGE!)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
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
