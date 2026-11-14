import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../src/analytics.dart';

/// Blocks the app until the player confirms they are 18 or over.
/// The answer is remembered on this device.
class AgeGate extends StatefulWidget {
  final Widget child;

  const AgeGate({super.key, required this.child});

  @override
  State<AgeGate> createState() => _AgeGateState();
}

class _AgeGateState extends State<AgeGate> {
  static const _prefsKey = 'age_confirmed_18';

  bool? _confirmed;
  bool _underage = false;
  // App only: analytics is opt-in, so the box starts unticked.
  bool _allowAnalytics = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() => _confirmed = prefs.getBool(_prefsKey) ?? false);
    });
  }

  Future<void> _confirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    if (!kIsWeb) await setAppAnalyticsConsent(_allowAnalytics);
    if (mounted) setState(() => _confirmed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmed == true) return widget.child;
    if (_confirmed == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐾', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text(
                  'Golden Paw is for players aged 18 and over',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Golden Paw is a virtual pet game with small Dogecoin rewards. '
                  'It is entertainment, not an investment or a way to make money. '
                  'Golden Paw does not take deposits and is not authorised by the FCA. '
                  'The value of Dogecoin can go down as well as up. Nothing here is financial advice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                if (_underage)
                  const Text(
                    "Sorry, you need to be 18 or over to play Golden Paw.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  )
                else ...[
                  if (!kIsWeb) ...[
                    CheckboxListTile(
                      value: _allowAnalytics,
                      onChanged: (v) => setState(() => _allowAnalytics = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.amber,
                      title: const Text(
                        'Help improve Golden Paw by sharing anonymous usage statistics (Google Analytics). Optional, and you can change it any time under Cookies & privacy.',
                        style: TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "I'm 18 or over, and I understand",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _underage = true),
                    child: const Text("I'm under 18"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
