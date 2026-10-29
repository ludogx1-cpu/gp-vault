import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AppUpdateBanner extends StatefulWidget {
  static const String currentVersion = 'v1.2.12';

  const AppUpdateBanner({super.key});

  @override
  State<AppUpdateBanner> createState() => _AppUpdateBannerState();
}

class _AppUpdateBannerState extends State<AppUpdateBanner> {
  String? _latestTag;
  String? _downloadUrl;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/ludogx1-cpu/gp-vault/releases/latest',
            ),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name']?.toString();
        if (tagName != null &&
            tagName.isNotEmpty &&
            _isNewerVersion(tagName, AppUpdateBanner.currentVersion)) {
          String url =
              'https://github.com/ludogx1-cpu/gp-vault/releases/latest/download/goldenpaw.apk';
          final assets = data['assets'];
          if (assets is List && assets.isNotEmpty) {
            for (final asset in assets) {
              if (asset is Map &&
                  asset['browser_download_url'] != null &&
                  asset['name'].toString().endsWith('.apk')) {
                url = asset['browser_download_url'].toString();
                break;
              }
            }
          }
          if (mounted) {
            setState(() {
              _latestTag = tagName;
              _downloadUrl = url;
            });
          }
        }
      }
    } catch (_) {
      // Ignore network errors silently
    }
  }

  bool _isNewerVersion(String remoteTag, String localTag) {
    List<int> parseParts(String v) {
      final clean = v.replaceAll(RegExp(r'^[^0-9]+'), '').split('+').first;
      return clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    }

    final remote = parseParts(remoteTag);
    final local = parseParts(localTag);
    final maxLen = remote.length > local.length ? remote.length : local.length;
    for (int i = 0; i < maxLen; i++) {
      final r = i < remote.length ? remote[i] : 0;
      final l = i < local.length ? local[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || _latestTag == null || _dismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.orange.shade800],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Golden Paw $_latestTag is available!",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(70, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (_downloadUrl != null) {
                launchUrl(
                  Uri.parse(_downloadUrl!),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: const Text(
              "UPDATE",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}
