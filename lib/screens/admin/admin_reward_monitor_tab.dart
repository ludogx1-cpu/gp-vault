import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../src/reward_report_export.dart';

class AdminRewardMonitorTab extends StatefulWidget {
  const AdminRewardMonitorTab({super.key});

  @override
  State<AdminRewardMonitorTab> createState() => _AdminRewardMonitorTabState();
}

class _AdminRewardMonitorTabState extends State<AdminRewardMonitorTab> {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _transactions = [];
  String _selectedType = 'all';

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedType == 'all') {
      return _transactions;
    }

    return _transactions
        .where((entry) => (entry['type'] as String? ?? 'unknown') == _selectedType)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();

      final transactions = snapshot.docs
          .map((doc) => doc.data())
          .whereType<Map<String, dynamic>>()
          .toList();

      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load reward data: $error';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _buildSummary() {
    final filtered = _filteredTransactions;
    double totalEarned = 0;
    double totalSpent = 0;
    double totalNet = 0;
    double largestSingleReward = 0;
    final List<double> positiveRewards = [];

    for (final entry in filtered) {
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      if (amount > 0) {
        totalEarned += amount;
        positiveRewards.add(amount);
        if (amount > largestSingleReward) {
          largestSingleReward = amount;
        }
      } else if (amount < 0) {
        totalSpent += amount.abs();
      }
      totalNet += amount;
    }

    final averageReward = positiveRewards.isEmpty
        ? 0.0
        : positiveRewards.reduce((a, b) => a + b) / positiveRewards.length;
    final suspicious = positiveRewards.isNotEmpty && largestSingleReward > averageReward * 3;
    final healthScore = filtered.isEmpty
        ? 100
        : (100 - ((largestSingleReward > 0 && averageReward > 0 ? (largestSingleReward / averageReward - 1) : 0) * 30).clamp(0, 100)).round();

    return {
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'totalNet': totalNet,
      'largestSingleReward': largestSingleReward,
      'averageReward': averageReward,
      'suspicious': suspicious,
      'count': filtered.length,
      'healthScore': healthScore,
    };
  }

  List<MapEntry<String, Map<String, num>>> _buildTypeBreakdown() {
    final grouped = <String, Map<String, num>>{};

    for (final entry in _filteredTransactions) {
      final type = (entry['type'] as String?) ?? 'unknown';
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final bucket = grouped.putIfAbsent(type, () => {'count': 0, 'net': 0, 'earned': 0, 'spent': 0});

      bucket['count'] = (bucket['count'] ?? 0) + 1;
      if (amount > 0) {
        bucket['earned'] = (bucket['earned'] ?? 0) + amount;
      } else if (amount < 0) {
        bucket['spent'] = (bucket['spent'] ?? 0) + amount.abs();
      }
      bucket['net'] = (bucket['net'] ?? 0) + amount;
    }

    final entries = grouped.entries.toList();
    entries.sort((a, b) => (b.value['net'] ?? 0).compareTo(a.value['net'] ?? 0));
    return entries;
  }

  List<Map<String, dynamic>> _buildTopUsers() {
    final grouped = <String, Map<String, dynamic>>{};

    for (final entry in _filteredTransactions) {
      final uid = (entry['uid'] as String?) ?? 'unknown';
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final bucket = grouped.putIfAbsent(uid, () => {'count': 0, 'net': 0.0});
      bucket['count'] = (bucket['count'] as int? ?? 0) + 1;
      bucket['net'] = (bucket['net'] as double? ?? 0.0) + amount;
    }

    final users = grouped.entries
        .map((entry) => {'uid': entry.key, 'count': entry.value['count'] as int, 'net': entry.value['net'] as double})
        .toList();
    users.sort((a, b) => (b['net'] as double).compareTo(a['net'] as double));
    return users.take(5).toList();
  }

  List<Map<String, dynamic>> _buildWeeklySummary() {
    final bucket = <String, double>{};

    for (final entry in _filteredTransactions) {
      final ts = entry['timestamp'];
      final date = ts is Timestamp ? ts.toDate() : DateTime.now();
      final key = DateTime(date.year, date.month, date.day).toIso8601String().substring(0, 10);
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      bucket[key] = (bucket[key] ?? 0.0) + amount;
    }

    final now = DateTime.now();
    final lastSevenDays = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final key = DateTime(day.year, day.month, day.day).toIso8601String().substring(0, 10);
      lastSevenDays.add({
        'date': key,
        'total': bucket[key] ?? 0.0,
      });
    }

    return lastSevenDays;
  }

  Future<void> _exportCsv() async {
    final csv = buildRewardReportCsv(_filteredTransactions, filterLabel: _selectedType);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reward report copied to clipboard as CSV.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final summary = _buildSummary();
    final suspicious = summary['suspicious'] as bool;
    final typeBreakdown = _buildTypeBreakdown();
    final topType = typeBreakdown.isNotEmpty ? typeBreakdown.first.key : 'n/a';
    final topUsers = _buildTopUsers();
    final weeklySummary = _buildWeeklySummary();
    final typeOptions = ['all', 'faucet_claim', 'stake_harvest', 'ptc_reward', 'withdrawal', 'offerwall_reward'];

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: suspicious ? Colors.red.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      suspicious ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: suspicious ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suspicious
                            ? 'Reward anomaly detected: a recent payout is significantly above the recent average.'
                            : 'Reward distribution looks healthy for the recent transaction window.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _statCard('Transactions', summary['count'].toString(), Colors.blue),
                _statCard('Health', '${summary['healthScore']}%', Colors.indigo),
                _statCard('Earned', '${summary['totalEarned'].toStringAsFixed(6)} DOGE', Colors.green),
                _statCard('Spent', '${summary['totalSpent'].toStringAsFixed(6)} DOGE', Colors.orange),
                _statCard('Net', '${summary['totalNet'].toStringAsFixed(6)} DOGE', Colors.purple),
                _statCard('Largest Reward', '${summary['largestSingleReward'].toStringAsFixed(6)} DOGE', Colors.red),
                _statCard('Avg Reward', '${summary['averageReward'].toStringAsFixed(6)} DOGE', Colors.teal),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Top reward stream: ${topType.replaceAll('_', ' ').toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter by Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: typeOptions.map((type) {
                final selected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type == 'all' ? 'All' : type.replaceAll('_', ' ').toUpperCase()),
                  selected: selected,
                  selectedColor: Colors.orange,
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Type Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (typeBreakdown.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No reward types recorded yet.'),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: typeBreakdown.map((entry) {
                  final type = entry.key;
                  final values = entry.value;
                  final net = (values['net'] ?? 0).toDouble();
                  final earned = (values['earned'] ?? 0).toDouble();
                  final spent = (values['spent'] ?? 0).toDouble();
                  return SizedBox(
                    width: 180,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Events: ${(values['count'] ?? 0)}'),
                            Text('Earned: ${earned.toStringAsFixed(6)} DOGE'),
                            Text('Spent: ${spent.toStringAsFixed(6)} DOGE'),
                            Text(
                              'Net: ${net.toStringAsFixed(6)} DOGE',
                              style: TextStyle(
                                color: net >= 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            const Text(
              'Top Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (topUsers.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No active users to summarize yet.'),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: topUsers.map((user) {
                      final uid = user['uid'] as String;
                      final net = (user['net'] as double).toStringAsFixed(6);
                      final count = user['count'] as int;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                uid.length > 12 ? '${uid.substring(0, 12)}...' : uid,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('$count events', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 10),
                            Text(
                              '$net DOGE',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              '7-Day Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: weeklySummary.map((entry) {
                    final date = entry['date'] as String;
                    final total = (entry['total'] as double).toStringAsFixed(6);
                    final isPositive = (entry['total'] as double) >= 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(date),
                          Text(
                            '$total DOGE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Reward Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_filteredTransactions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No matching transaction activity yet.'),
                ),
              )
            else
              ListView.builder(
                itemCount: _filteredTransactions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = _filteredTransactions[index];
                  final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                  final type = item['type']?.toString() ?? 'unknown';
                  final timestamp = item['timestamp'];
                  final when = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        amount >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                        color: amount >= 0 ? Colors.green : Colors.orange,
                      ),
                      title: Text(type.replaceAll('_', ' ').toUpperCase()),
                      subtitle: Text(when.toLocal().toString().substring(0, 16)),
                      trailing: Text(
                        '${amount >= 0 ? '+' : ''}${amount.toStringAsFixed(6)} DOGE',
                        style: TextStyle(
                          color: amount >= 0 ? Colors.green.shade700 : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
