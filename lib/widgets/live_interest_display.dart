import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---




// ==========================================
// 1. THE SHELL
// ==========================================

class LiveInterestDisplay extends StatefulWidget {
  final double stakedBalance;
  final Timestamp? stakeTimestamp;
  const LiveInterestDisplay({
    super.key,
    required this.stakedBalance,
    this.stakeTimestamp,
  });
  @override
  State<LiveInterestDisplay> createState() => _LiveInterestDisplayState();
}

class _LiveInterestDisplayState extends State<LiveInterestDisplay> {
  Timer? _timer;
  double _liveInterest = 0.0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(LiveInterestDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stakedBalance != widget.stakedBalance ||
        oldWidget.stakeTimestamp != widget.stakeTimestamp) {
      _calculateInterest();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateInterest();
    });
  }

  void _calculateInterest() {
    if (widget.stakedBalance <= 0 || widget.stakeTimestamp == null) {
      if (mounted && _liveInterest != 0.0) setState(() => _liveInterest = 0.0);
      return;
    }
    const double interestPerSecond = 0.085 / 31536000;
    final now = DateTime.now();
    final stakeTime = widget.stakeTimestamp!.toDate();
    final secondsPassed = now.difference(stakeTime).inSeconds;

    if (secondsPassed > 0 && mounted) {
      setState(() {
        _liveInterest =
            widget.stakedBalance * interestPerSecond * secondsPassed;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 👑 Wrapped in ListenableBuilder for dark mode text matching
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;

        return Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.stakedBalance.toStringAsFixed(8),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            Text(
              "DOGE",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.amber : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white.withAlpha(102),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "+ ${_liveInterest.toStringAsFixed(10)} Pending Yield",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.greenAccent : Colors.black87,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// 4. THE ACCOUNT PAGE
// ==========================================

