import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import '../widgets/widgets.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool _isLoading = true;
  List<dynamic> _leaderboard = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/leaderboard'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _leaderboard = data['leaderboard'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Failed to load leaderboard.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildPrizeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                SizedBox(width: 8),
                Text(
                  'Weekly Top 5 Prizes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Take the best care of your pet to win free DOGE every Sunday at midnight!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _prizeTier('1st', '3 DOGE', Colors.amber),
                _prizeTier('2nd', '0.25 DOGE', Colors.grey.shade400),
                _prizeTier('3rd', '1 DOGE', Colors.orange.shade300),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _prizeTier('4th', '0.5 DOGE', Colors.blueGrey),
                _prizeTier('5th', '0.25 DOGE', Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _prizeTier(String rank, String prize, Color color) {
    return Column(
      children: [
        Text(rank, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
        Text(prize, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Weekly Pet Leaderboard',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildPrizeCard(),
                const SizedBox(height: 24),
                const Center(child: Bitcotasks300x100AdWidget()),
                const SizedBox(height: 24),
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage.isNotEmpty)
                  Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                else if (_leaderboard.isEmpty)
                  const Center(child: Text('No scores yet! Feed your pet to get on the board.'))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _leaderboard.length,
                      itemBuilder: (context, index) {
                        final item = _leaderboard[index];
                        final rank = index + 1;
                        final username = item['username'] ?? 'Anonymous';
                        final score = (item['weekly_time_above_40'] as num?)?.toInt() ?? 0;
                        final petName = item['pet_name'] ?? 'Golden Paw Shiba';
                        final isAi = item['is_ai'] == true;

                        Color rankColor;
                        if (rank == 1) {
                          rankColor = Colors.amber;
                        } else if (rank == 2) {
                          rankColor = Colors.grey.shade400;
                        } else if (rank == 3) {
                          rankColor = Colors.orange.shade300;
                        } else {
                          rankColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: rankColor.withValues(alpha: 0.2),
                              child: Text(
                                '#$rank',
                                style: TextStyle(color: rankColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (isAi)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4.0),
                                        child: Icon(Icons.verified, size: 14, color: Colors.blue),
                                      ),
                                  ],
                                ),
                                Text(
                                  'Pet: $petName',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '$score Hours >40% Stats',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        );
                      },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

