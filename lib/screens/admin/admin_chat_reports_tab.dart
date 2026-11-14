import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_constants.dart';
import '../../src/firebase_service.dart';

/// Chat messages users have reported (Online Safety Act). Remove illegal or
/// rule-breaking messages, optionally ban the sender, or dismiss the report.
/// Every decision is saved on the report as a record of how it was handled.
class AdminChatReportsTab extends StatefulWidget {
  const AdminChatReportsTab({super.key});

  @override
  State<AdminChatReportsTab> createState() => _AdminChatReportsTabState();
}

class _AdminChatReportsTabState extends State<AdminChatReportsTab> {
  bool _showHandled = false;
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _reports = [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final status = _showHandled ? 'handled' : 'open';
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/reports?status=$status'),
        headers: await getAuthHeaders(),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(data['reports'] as List);
          _loading = false;
        });
      } else {
        setState(() {
          _error = (data['error'] ?? 'Could not load reports').toString();
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach the server. Try again in a moment.';
        _loading = false;
      });
    }
  }

  Future<bool> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$path'),
        headers: await getAuthHeaders(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) return true;
      final data = jsonDecode(response.body);
      _snack((data['error'] ?? 'Request failed').toString());
    } catch (_) {
      _snack('Could not reach the server.');
    }
    return false;
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _resolve(Map<String, dynamic> report, String action, {bool ban = false}) async {
    final id = report['id'] as String;
    setState(() => _busy.add(id));
    var ok = true;
    if (ban && (report['reported_uid'] as String).isNotEmpty) {
      ok = await _post('/chat/ban', {'target_uid': report['reported_uid'], 'reason': 'general'});
    }
    if (ok) ok = await _post('/chat/reports/$id/resolve', {'action': action});
    if (!mounted) return;
    setState(() => _busy.remove(id));
    if (ok) {
      _snack(action == 'removed'
          ? (ban ? 'Message removed and user banned.' : 'Message removed.')
          : 'Report dismissed.');
      setState(() => _reports.removeWhere((r) => r['id'] == id));
    }
  }

  String _when(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Open'), icon: Icon(Icons.flag)),
                  ButtonSegment(value: true, label: Text('Handled'), icon: Icon(Icons.history)),
                ],
                selected: {_showHandled},
                onSelectionChanged: (s) {
                  setState(() => _showHandled = s.first);
                  _load();
                },
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Remove anything illegal or against the chat rules. Removing deletes the message from chat; '
            'every decision is kept here as your record.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(child: Text(_error, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_reports.isEmpty) {
      return Center(
        child: Text(
          _showHandled ? 'No handled reports yet.' : 'No open reports. 🎉',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, i) {
        final r = _reports[i];
        final id = r['id'] as String;
        final busy = _busy.contains(id);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(r['reason']?.toString() ?? ''),
                      backgroundColor: Colors.red.shade50,
                      labelStyle: TextStyle(color: Colors.red.shade900, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(_when(r['timestamp'] as String?),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  '"${r['message_text'] ?? ''}"',
                  style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  'Sender: ${r['reported_uid']}\nReported by: ${r['reporter_uid']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (_showHandled) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Outcome: ${r['action'] == 'removed' ? 'message removed' : 'dismissed'}'
                    '${r['handled_at'] != null ? ' on ${_when(r['handled_at'] as String?)}' : ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  if (busy)
                    const LinearProgressIndicator()
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove message'),
                          onPressed: () => _resolve(r, 'removed'),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.gavel, size: 18),
                          label: const Text('Remove + ban sender'),
                          onPressed: () => _resolve(r, 'removed', ban: true),
                        ),
                        TextButton(
                          onPressed: () => _resolve(r, 'dismissed'),
                          child: const Text('Dismiss (no action)'),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
