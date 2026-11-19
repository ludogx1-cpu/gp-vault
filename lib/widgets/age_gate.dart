import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../src/analytics.dart';
import 'package:gp_faucet/src/brand_colors.dart';

/// Asks the player to confirm they are 18 or over before they can use the app.
///
/// The page is shown underneath, dimmed and not interactive, so new visitors
/// get a first look at Golden Paw instead of a blank screen. Nothing can be
/// tapped or scrolled until they confirm. The answer is remembered on this
/// device.
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

    // Preview of the page underneath: visible, but no taps, scrolling or
    // screen-reader focus until the player confirms.
    final preview = ExcludeSemantics(
      child: AbsorbPointer(child: widget.child),
    );

    return Stack(
      children: [
        Positioned.fill(child: preview),
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
        ),
        if (_confirmed == false)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(12),
              child: _buildCard(context),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
      child: Material(
        color: const Color(0xFF141926),
        elevation: 16,
        shadowColor: Colors.black,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: kGold.withValues(alpha: 0.5), width: 1.2),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 18, 20, isMobile ? 14 : 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🐾  Golden Paw is for players aged 18+',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Golden Paw is a virtual pet game with small Dogecoin rewards. '
                  'It is entertainment, not an investment or a way to make money. '
                  'Golden Paw does not take deposits and is not authorised by the FCA. '
                  'The value of Dogecoin can go down as well as up. Nothing here is financial advice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                if (_underage)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      "Sorry, you need to be 18 or over to play Golden Paw.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  )
                else ...[
                  if (!kIsWeb) ...[
                    CheckboxListTile(
                      value: _allowAnalytics,
                      onChanged: (v) => setState(() => _allowAnalytics = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: kGold,
                      title: const Text(
                        'Help improve Golden Paw by sharing anonymous usage statistics (Google Analytics). Optional, and you can change it any time under Cookies & privacy.',
                        style: TextStyle(fontSize: 12, height: 1.3, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "I'm 18 or over. Let me in",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => setState(() => _underage = true),
                    style: TextButton.styleFrom(foregroundColor: Colors.white60),
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
