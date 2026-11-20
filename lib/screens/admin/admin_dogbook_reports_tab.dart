import 'package:flutter/material.dart';

import '../book_of_dog/dogbook_api.dart';

/// Reported Book Of Dog posts, comments and dog profiles (Online Safety Act). Each reported
/// item appears once, with how many people reported it and why. Remove it,
/// remove it and stop the author posting, or keep it (which un-hides it).
/// Every decision is saved on the reports as a record.
class AdminDogbookReportsTab extends StatefulWidget {
  const AdminDogbookReportsTab({super.key});

  @override
  State<AdminDogbookReportsTab> createState() => _AdminDogbookReportsTabState();
}

class _AdminDogbookReportsTabState extends State<AdminDogbookReportsTab> {
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
    final result = await DogbookApi.listReports(handled: _showHandled);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _reports = List<Map<String, dynamic>>.from(result.data['reports'] as List);
      } else {
        _error = result.error;
      }
    });
  }

  Future<void> _resolve(String key, String action) async {
    setState(() => _busy.add(key));
    final result = await DogbookApi.resolveReport(key, action);
    if (!mounted) return;
    setState(() => _busy.remove(key));
    final messenger = ScaffoldMessenger.of(context);
    if (result.ok) {
      messenger.showSnackBar(SnackBar(
          content: Text(switch (action) {
        'banned' => 'Removed, and the author can no longer post.',
        'removed' => 'Removed.',
        _ => 'Kept and back on show.',
      })));
      setState(() => _reports.removeWhere((r) => r['target_key'] == key));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result.error)));
    }
  }

  String _when(String? iso) {
    final t = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
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
              IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _load),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Anything reported by 3 or more people is already hidden. Remove what breaks the rules; '
            '"Keep" puts it back on show. Every decision is kept here as your record.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _list()),
      ],
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(child: Text(_error, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_reports.isEmpty) {
      return Center(
        child: Text(_showHandled ? 'No handled reports yet.' : 'No open reports. 🎉',
            style: const TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, i) {
        final r = _reports[i];
        final key = r['target_key'] as String;
        final typeLabel = switch (r['target_type']) {
          'post' => 'Post',
          'dog' => 'Dog profile',
          _ => 'Comment',
        };
        final image = (r['image_url'] ?? '').toString();
        final reasons = List<String>.from(r['reasons'] as List? ?? const []);
        final count = (r['reporters'] as num?)?.toInt() ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(label: Text(typeLabel)),
                    Chip(
                      label: Text('$count report${count == 1 ? '' : 's'}'),
                      backgroundColor: count >= 3 ? Colors.red.shade100 : null,
                    ),
                    for (final reason in reasons)
                      Chip(
                        label: Text(reason),
                        backgroundColor: Colors.red.shade50,
                        labelStyle: TextStyle(color: Colors.red.shade900, fontSize: 12),
                      ),
                    Text(_when(r['latest'] as String?),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                if (image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      image,
                      height: 220,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (c, e, s) => const Text('(photo already removed)'),
                    ),
                  ),
                const SizedBox(height: 6),
                SelectableText('"${r['text'] ?? ''}"',
                    style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                SelectableText('Author: ${r['reported_uid']}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 10),
                if (_showHandled)
                  Text(
                    'Outcome: ${switch (r['action']) {
                      'banned' => 'removed and author stopped',
                      'removed' => 'removed',
                      _ => 'kept'
                    }}${r['handled_at'] != null ? ' on ${_when(r['handled_at'] as String?)}' : ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  )
                else if (_busy.contains(key))
                  const LinearProgressIndicator()
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                        onPressed: () => _resolve(key, 'removed'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.gavel, size: 18),
                        label: const Text('Remove + stop author posting'),
                        onPressed: () => _resolve(key, 'banned'),
                      ),
                      TextButton(
                        onPressed: () => _resolve(key, 'kept'),
                        child: const Text('Keep (nothing wrong)'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
