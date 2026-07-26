import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../src/theme_provider.dart';
import '../../api_constants.dart';

class LeaderboardPreview extends StatefulWidget {
  const LeaderboardPreview({super.key});

  @override
  State<LeaderboardPreview> createState() => _LeaderboardPreviewState();
}

class _LeaderboardPreviewState extends State<LeaderboardPreview> {
  bool _isLoadingLeaderboard = true;
  List<dynamic> _leaderboard = [];
  String _leaderboardError = '';

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoadingLeaderboard = true;
      _leaderboardError = '';
    });
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/leaderboard'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _leaderboard = data['leaderboard'] ?? [];
              _isLoadingLeaderboard = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _leaderboardError = data['error'] ?? 'Failed to load leaderboard.';
              _isLoadingLeaderboard = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _leaderboardError = 'Server error: ${response.statusCode}';
            _isLoadingLeaderboard = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leaderboardError = 'Network error: $e';
          _isLoadingLeaderboard = false;
        });
      }
    }
  }

  Widget _buildPrizeTier(String rank, String prize, Color color) {
    return Column(
      children: [
        Text(rank, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(prize, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: isDark ? themeProvider.darkGreyBoxColor : Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
            border: isDark
                ? Border.all(color: themeProvider.darkGreyBorder, width: 1)
                : null,
          ),
          child: ExpansionTile(
            title: const Text(
              '🏆 Weekly Pet Leaderboard (Top 10)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            subtitle: const Text(
              'Take the best care of your pet to win free DOGE every Sunday at midnight!',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: isDark ? Colors.grey.shade800 : Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            const Text(
                              'Top 5 Prizes',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildPrizeTier('1st', '3 DOGE', Colors.amber),
                                _buildPrizeTier('2nd', '2 DOGE', Colors.grey.shade400),
                                _buildPrizeTier('3rd', '1 DOGE', Colors.orange.shade300),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildPrizeTier('4th', '0.5 DOGE', Colors.blueGrey),
                                _buildPrizeTier('5th', '0.25 DOGE', Colors.blueGrey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isLoadingLeaderboard)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (_leaderboardError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(_leaderboardError, style: const TextStyle(color: Colors.red)),
                      )
                    else if (_leaderboard.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No scores yet! Feed your pet to get on the board.'),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 350),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _leaderboard.length > 10 ? 10 : _leaderboard.length,
                          itemBuilder: (context, index) {
                            final item = _leaderboard[index];
                            final rank = index + 1;
                            final username = item['username'] ?? 'Anonymous';
                            final score = item['weekly_time_above_40'] ?? 0;
                            final petName = item['pet_name'] ?? 'Golden Paw Shiba';
                            final isAi = item['is_ai'] == true;

                            Color rankColor;
                            if (rank == 1) { rankColor = Colors.amber; }
                            else if (rank == 2) { rankColor = Colors.grey.shade400; }
                            else if (rank == 3) { rankColor = Colors.orange.shade300; }
                            else { rankColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black; }

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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
