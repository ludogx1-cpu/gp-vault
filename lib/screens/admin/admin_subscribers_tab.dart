import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../api_constants.dart';
import '../../src/firebase_service.dart';

/// Newsletter sign-ups. "Copy all emails" puts one email per line on the
/// clipboard, ready to paste into Substack (Subscribers → Add subscribers).
class AdminSubscribersTab extends StatefulWidget {
  const AdminSubscribersTab({super.key});

  @override
  State<AdminSubscribersTab> createState() => _AdminSubscribersTabState();
}

class _AdminSubscribersTabState extends State<AdminSubscribersTab> {
  bool _loading = true;
  String _error = '';
  List<String> _emails = [];
  bool _allAccounts = false;
  int _optedOut = 0;

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
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/${_allAccounts ? 'account-emails' : 'subscribers'}'),
        headers: await getAuthHeaders(),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (response.statusCode == 200) {
          _emails = List<String>.from(data['emails'] as List);
          _optedOut = (data['opted_out'] as num?)?.toInt() ?? 0;
        } else {
          _error = (data['error'] ?? 'Could not load subscribers').toString();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not reach the server. Try again in a moment.';
      });
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _emails.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${_emails.length} emails. Paste them into Substack.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(child: Text(_error, style: const TextStyle(color: Colors.redAccent)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Newsletter sign-ups'), icon: Icon(Icons.mail_outline)),
            ButtonSegment(value: true, label: Text('All account holders'), icon: Icon(Icons.people_outline)),
          ],
          selected: {_allAccounts},
          onSelectionChanged: (v) {
            setState(() => _allAccounts = v.first);
            _load();
          },
        ),
        const SizedBox(height: 16),
        Text(_allAccounts ? '${_emails.length} account emails' : '${_emails.length} newsletter subscribers',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          _allAccounts
              ? 'Everyone with a Golden Paw account, except the $_optedOut who unsubscribed or whose account is '
                  'disabled. Copy the emails, then in Substack go to Subscribers → Add subscribers → paste. '
                  'Make sure every email you send has an unsubscribe link (Substack adds one automatically).'
              : 'People who signed up in a newsletter box on the site. Copy the emails, then in Substack go to '
                  'Subscribers → Add subscribers → paste.',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _emails.isEmpty ? null : _copy,
              icon: const Icon(Icons.copy),
              label: const Text('Copy all emails'),
            ),
            OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
          ],
        ),
        const SizedBox(height: 16),
        for (final e in _emails) SelectableText(e),
        if (_emails.isEmpty)
          const Text('No sign-ups yet.', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
