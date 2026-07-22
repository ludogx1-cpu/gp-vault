import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:js_interop';

@JS('canInstallPwa')
external JSBoolean _canInstallPwaJS();

@JS('triggerPwaInstall')
external void _triggerPwaInstallJS();

class PwaInstallWidget extends StatefulWidget {
  const PwaInstallWidget({super.key});

  @override
  State<PwaInstallWidget> createState() => _PwaInstallWidgetState();
}

class _PwaInstallWidgetState extends State<PwaInstallWidget> {
  bool _isVisible = false;
  bool _isIOS = false;

  @override
  void initState() {
    super.initState();
    _checkInstallability();
  }

  Future<void> _checkInstallability() async {
    if (!kIsWeb) {
      setState(() => _isVisible = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool dismissed = prefs.getBool('pwa_banner_dismissed') ?? false;
    if (dismissed) {
      setState(() => _isVisible = false);
      return;
    }

    // Check if running on iOS browser
    final userAgent = defaultTargetPlatform;
    bool isIosWeb = userAgent == TargetPlatform.iOS;

    bool canInstall = false;
    try {
      canInstall = _canInstallPwaJS().toDart;
    } catch (_) {
      canInstall = false;
    }

    if (mounted) {
      setState(() {
        _isIOS = isIosWeb;
        _isVisible = canInstall || isIosWeb;
      });
    }
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pwa_banner_dismissed', true);
    setState(() => _isVisible = false);
  }

  void _triggerInstall() {
    try {
      _triggerPwaInstallJS();
    } catch (e) {
      debugPrint("Error triggering PWA install: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.orange.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.get_app_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Install Golden Paw App",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: _dismissBanner,
                tooltip: "Dismiss",
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isIOS
                ? "Install our Web App for quick access and instant notifications! Tap the Share button in Safari, then select 'Add to Home Screen'."
                : "Add Golden Paw to your home screen! Never miss daily promo codes, pet reminders, or staking rewards.",
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 14),
          if (!_isIOS)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _triggerInstall,
                icon: const Icon(Icons.add_to_home_screen, color: Colors.amber, size: 18),
                label: const Text(
                  "INSTALL APP TO DEVICE",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.ios_share, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tap Share ➔ 'Add to Home Screen'",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
