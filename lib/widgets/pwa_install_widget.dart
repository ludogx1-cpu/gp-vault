import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../api_constants.dart';
import '../src/pwa_interop.dart' if (dart.library.html) '../src/pwa_interop_web.dart';
import 'package:gp_faucet/src/brand_colors.dart';

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

    final userAgent = defaultTargetPlatform;
    bool isIosWeb = userAgent == TargetPlatform.iOS;

    if (mounted) {
      setState(() {
        _isIOS = isIosWeb;
        _isVisible = true; // Always visible on Web so users can download/install
      });
    }
  }

  void _dismissBanner() {
    setState(() => _isVisible = false);
  }

  void _triggerInstall() {
    try {
      bool canPrompt = canInstallPwa();
      if (canPrompt) {
        triggerPwaInstall();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("To install: tap your browser menu (⋮ or Share) and select 'Add to Home screen' or 'Install App'!"),
            backgroundColor: kGold.shade800,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("To install: tap your browser menu (⋮ or Share) and select 'Add to Home screen' or 'Install App'!"),
          backgroundColor: kGold.shade800,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kGold.shade600, kGold.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.get_app_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Get the app",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: _dismissBanner,
                tooltip: "Dismiss",
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isIOS
                ? "Add Golden Paw to your home screen for notifications and daily promo codes."
                : "Install the web app or the Android app for notifications and daily promo codes.",
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 14),
          if (!_isIOS)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _triggerInstall,
                icon: const Icon(Icons.add_to_home_screen, color: kGold, size: 18),
                label: const Text(
                  "Install web app",
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                downloadApk(ApiConstants.apkDownloadUrl);
              },
              icon: const Icon(Icons.android, color: kGold, size: 18),
              label: const Text(
                "Download Android app",
                style: TextStyle(
                  color: kGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kCharcoal,
                side: const BorderSide(color: kGold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    )));
  }
}
