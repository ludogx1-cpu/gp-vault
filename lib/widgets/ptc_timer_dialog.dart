import '../src/js_bindings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';

// --- GLOBAL THEME CONSTANTS 🚀 ---

// --- CAPTCHA JS BINDINGS ---

// ==========================================
// 1. THE SHELL
// ==========================================

class PtcTimerDialog extends StatefulWidget {
  final String adId;
  final int duration;
  const PtcTimerDialog({super.key, required this.adId, required this.duration});

  @override
  State<PtcTimerDialog> createState() => _PtcTimerDialogState();
}

class _PtcTimerDialogState extends State<PtcTimerDialog> {
  late int _timeLeft;
  late final Stopwatch _stopwatch = Stopwatch();
  late final String _originalTitle;
  Timer? _timer;
  bool _claimed = false;
  bool _isProcessing = false;
  String _message = "Please wait...";

  bool _showCaptcha = false;
  String _selectedCaptcha = 'hCaptcha';
  bool _captchaLoading = false;
  String? _captchaToken;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _originalTitle = web.document.title;
    _timeLeft = widget.duration;
    _updateBrowserTitle("${_timeLeft}s left");
    _stopwatch.start();
    _startTimer();

    _messageSubscription = web.EventStreamProviders.messageEvent
        .forTarget(web.window)
        .listen((web.Event event) {
          try {
            final msgEvent = event as web.MessageEvent;
            final dartData = msgEvent.data?.dartify();
            String? dataStr;
            if (dartData is String) {
              dataStr = dartData;
            } else if (dartData != null) {
              dataStr = dartData.toString();
            }

            if (dataStr != null && dataStr.contains('captcha')) {
              final data = jsonDecode(dataStr);
              if (data['type'] == 'captcha') {
                if (mounted) {
                  setState(() {
                    _captchaToken = data['token'];
                  });
                  if (_showCaptcha && !_isProcessing) {
                    _processClaim();
                  }
                }
              }
            }
          } catch (e) {
            /* ignore */
          }
        });
  }

  void _updateBrowserTitle(String title) {
    web.document.title = "$title - Golden Paw";
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_isProcessing || _showCaptcha) return;

      bool isFocused = web.document.hasFocus();

      if (isFocused) {
        if (_stopwatch.isRunning) {
          _stopwatch.stop();
          if (mounted) {
            setState(
              () => _message = "⚠️ Paused! Go back and view the Ad tab!",
            );
          }
        }
      } else {
        if (!_stopwatch.isRunning) {
          _stopwatch.start();
        }
      }

      int elapsedSeconds = _stopwatch.elapsed.inSeconds;
      int remaining = widget.duration - elapsedSeconds;

      if (remaining <= 0) {
        timer.cancel();
        _stopwatch.stop();
        if (mounted) {
          setState(() {
            _timeLeft = 0;
            _showCaptcha = true;
            _message = "Solve Captcha to Claim!";
          });
          _updateBrowserTitle("Claim ready");
        }
      } else {
        if (mounted && remaining != _timeLeft) {
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
    setState(() => _captchaLoading = true);
    Timer(const Duration(milliseconds: 200), () {
      try {
        if (_selectedCaptcha == 'hCaptcha') {
          renderHCaptcha();
        } else if (_selectedCaptcha == 'Turnstile') {
          renderTurnstile();
        }
      } catch (e) {
        /* ignore */
      }
    });
  }

  Future<void> _processClaim() async {
    if (_isProcessing) return;
    _isProcessing = true;
    setState(() => _message = "Verifying...");
    _updateBrowserTitle("Verifying");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://golden-paw-vault.onrender.com/claim-ptc'),
        headers: await getAuthHeaders(),
        body: jsonEncode({
          'captcha_token': _captchaToken,
          'captcha_provider': _selectedCaptcha,
          'ad_id': widget.adId,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _claimed = true;
            _showCaptcha = false;
            _message = "Success! DOGE & +5 XP added to Vault.";
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
    _stopwatch.stop();
    _messageSubscription?.cancel();
    web.document.title = _originalTitle;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode;

    return Dialog(
      backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(25),
        height: _showCaptcha ? 350 : 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showCaptcha && !_claimed) ...[
              Text(
                "Almost done! Verify you are human.",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: gpBrownText(context),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: DropdownButton<String>(
                  value: _selectedCaptcha,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black87,
                    size: 16,
                  ),
                  elevation: 16,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  underline: Container(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedCaptcha = value!;
                      _captchaToken = null;
                      _captchaLoading = false;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'hCaptcha',
                      child: Text('hCaptcha'),
                    ),
                    DropdownMenuItem(
                      value: 'Turnstile',
                      child: Text('Turnstile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: PointerInterceptor(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_captchaToken == null &&
                          _selectedCaptcha == 'hCaptcha')
                        const SizedBox(
                          width: 320,
                          height: 90,
                          child: HtmlElementView(viewType: 'hcaptcha-widget'),
                        )
                      else if (_captchaToken == null &&
                          _selectedCaptcha == 'Turnstile')
                        const SizedBox(
                          width: 320,
                          height: 90,
                          child: HtmlElementView(viewType: 'turnstile-widget'),
                        ),

                      if (!_captchaLoading && _captchaToken == null)
                        ElevatedButton(
                          onPressed: _forceRenderCaptcha,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade100,
                            elevation: 0,
                          ),
                          child: const Text(
                            "Tap to Verify",
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: Text(
                  "CLOSE",
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🌟 TRUSTED BONUS SPONSOR 30-SECOND TIMER DIALOG
// ==========================================
