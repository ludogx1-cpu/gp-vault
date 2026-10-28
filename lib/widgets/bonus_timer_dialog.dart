// ignore_for_file: dead_code, duplicate_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../src/cross_tab_listener/cross_tab_listener.dart';
import '../api_constants.dart';
import '../screens/faucet/captcha_selector_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ==========================================
// 1. THE SHELL
// ==========================================

class BonusTimerDialog extends StatefulWidget {
  final String? endpoint;
  final int durationSeconds;
  final String? targetUrl;

  const BonusTimerDialog({
    super.key,
    this.endpoint,
    this.durationSeconds = 20,
    this.targetUrl,
  });

  @override
  State<BonusTimerDialog> createState() => _BonusTimerDialogState();
}

class _BonusTimerDialogState extends State<BonusTimerDialog> {
  late int _timeLeft;
  late final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Timer? _coldStartTimer;
  CrossTabListener? _crossTabListener;
  bool _claimed = false;
  bool _isProcessing = false;
  String _message = "Please wait...";

  bool _showCaptcha = false;
  bool _timerStarted = false;
  String _selectedCaptcha = 'Turnstile';
  bool _captchaLoading = false;
  int _captchaReloadCounter = 0;
  String? _captchaToken;

  DateTime _lastClickTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.durationSeconds;
    _updateBrowserTitle("Click an ad...");
    _message =
        "Stay on the page for ${widget.durationSeconds} seconds to earn your reward!";

    try {
      _crossTabListener = getCrossTabListener();
      _crossTabListener?.setup((messageStr) {
        _onCaptchaMessage(messageStr);
      });
    } catch (e) {
      // ignore on unsupported platforms
    }

    // Auto-start timer on mobile or for external video links that don't post cross-tab messages
    if (!kIsWeb ||
        (widget.targetUrl != null &&
            widget.targetUrl!.contains('youtube.com'))) {
      _timerStarted = true;
      _lastClickTime = DateTime.now();
      _stopwatch.start();
      _startTimer();
    }
  }

  void _onCaptchaMessage(String messageStr) {
    if (!mounted) return;
    try {
      if (messageStr.contains("start_bonus_timer")) {
        if (!_timerStarted) {
          setState(() {
            _timerStarted = true;
            _lastClickTime = DateTime.now();
          });
          _stopwatch.start();
          _startTimer();
        }
      } else if (messageStr.contains("captcha") ||
          messageStr.contains("token")) {
        final data = jsonDecode(messageStr) as Map<String, dynamic>;
        final token =
            data["token"] ?? data["captcha_token"] ?? data["turnstile_token"];
        if (token != null) {
          setState(() {
            _captchaToken = token;
          });
          if (_showCaptcha && !_isProcessing) {
            _processBonusClaim();
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  void _updateBrowserTitle(String title) {
    _crossTabListener?.setBrowserTitle("$title - Golden Paw");
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_isProcessing || _showCaptcha) return;
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_claimed) {
        timer.cancel();
        return;
      }

      int currentElapsed = DateTime.now().difference(_lastClickTime).inSeconds;
      int remaining = widget.durationSeconds - currentElapsed;

      if (remaining <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _timeLeft = 0;
            _showCaptcha = true;
            _message = "Solve Captcha to Claim!";
          });
          _updateBrowserTitle("Claim ready");
          HapticFeedback.vibrate();
        }
      } else {
        if (mounted &&
            remaining != _timeLeft &&
            remaining <= widget.durationSeconds) {
          setState(() {
            _timeLeft = remaining;
            _message = "Watching Ad... $_timeLeft seconds left";
          });
          _updateBrowserTitle("${remaining}s left");
        }
      }
    });
  }

  void _forceRenderCaptcha() {
    setState(() {
      _captchaReloadCounter++;
      _captchaLoading = true;
      _captchaToken = null;
    });
    Timer(const Duration(milliseconds: 200), () {
      if (_selectedCaptcha == 'hCaptcha') {
        _crossTabListener?.renderHCaptcha();
      } else if (_selectedCaptcha == 'Turnstile') {
        _crossTabListener?.renderTurnstile();
      }
      if (mounted) {
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() => _captchaLoading = false);
          }
        });
      }
    });
  }

  Future<void> _processBonusClaim() async {
    if (_isProcessing) return;
    _isProcessing = true;
    setState(() => _message = "Verifying...");
    _updateBrowserTitle("Verifying");

    _coldStartTimer?.cancel();
    _coldStartTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isProcessing) {
        setState(() => _message = "Waking up Vault server... please wait 🐾");
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetEndpoint =
        widget.endpoint ?? '${ApiConstants.baseUrl}/claim-bonus-sponsor';

    try {
      final response = await http.post(
        Uri.parse(targetEndpoint),
        headers: await getAuthHeaders(),
        body: jsonEncode({
          'captcha_token': _captchaToken,
          'captcha_provider': _selectedCaptcha,
        }),
      );
      _coldStartTimer?.cancel();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _claimed = true;
            _showCaptcha = false;
            final rwd = responseData['rewardAmount']?.toString() ?? '0.004';
            final xpRwd = responseData['xpReward']?.toString() ?? '15';
            _message = "Success! $rwd DOGE & +$xpRwd XP added!";
          });
          _updateBrowserTitle("Claim complete");
        }
      } else {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _message = "Error: ${err['error']}";
            _isProcessing = false;
            _captchaToken = null;
            _captchaLoading = false;
          });
        }
      }
    } catch (e) {
      _coldStartTimer?.cancel();
      if (mounted) {
        setState(() {
          _message = "Connection error. Try again.";
          _isProcessing = false;
          _captchaToken = null;
          _captchaLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _coldStartTimer?.cancel();
    _crossTabListener?.cancel();
    _stopwatch.stop();
    // Revert title
    _updateBrowserTitle("Golden Paw");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode;

    return Dialog(
      backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_showCaptcha && !_claimed) ...[
                const SizedBox(height: 10),
                Text(
                  "Almost done! Verify you are human.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: gpBrownText(context),
                  ),
                ),
                const SizedBox(height: 15),
                CaptchaSelectorWidget(
                  selectedCaptcha: _selectedCaptcha,
                  secondsRemaining: 0,
                  isCheckingCooldown: false,
                  captchaLoading: _captchaLoading,
                  reloadCounter: _captchaReloadCounter,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedCaptcha = value!;
                      _captchaReloadCounter++;
                      _captchaToken = null;
                      _captchaLoading = false;
                    });
                  },
                  onMessageReceived: _onCaptchaMessage,
                  onForceRender: _forceRenderCaptcha,
                ),
                const SizedBox(height: 15),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isProcessing ? Colors.blue : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ] else if (!_claimed) ...[
                const CircularProgressIndicator(color: Colors.amber),
                const SizedBox(height: 25),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _message.contains("Paused")
                        ? Colors.red
                        : gpBrownText(context),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (_message.contains("Paused") &&
                        widget.targetUrl != null) ...[
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {});
                          launchUrl(Uri.parse(widget.targetUrl!));
                        },
                        child: const Text(
                          "Resume Ad",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!_timerStarted) ...[
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      _onCaptchaMessage('{"type":"start_bonus_timer"}');
                    },
                    child: const Text(
                      "Timer didn't start? Click here",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 15),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(
                    "CLOSE",
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
