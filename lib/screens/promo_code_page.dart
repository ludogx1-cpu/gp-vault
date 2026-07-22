import '../widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';

class PromoCodePage extends StatefulWidget {
  const PromoCodePage({super.key});

  @override
  State<PromoCodePage> createState() => _PromoCodePageState();
}

class _PromoCodePageState extends State<PromoCodePage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isClaiming = false;
  String _message = "";

  // Spinner state
  bool _isSpinning = false;
  int _currentDisplayNumber = 0;
  Timer? _spinnerTimer;

  bool _isFetchingCode = false;

  Future<void> _fetchTodayCode() async {
    setState(() => _isFetchingCode = true);
    try {
      final response = await http.get(
        Uri.parse('https://golden-paw-vault.onrender.com/today-promo'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['code'] != null) {
          setState(() {
            _codeController.text = data['code'];
            _message =
                "Today's secret word filled in! Click SPIN & CLAIM below.";
          });
        }
      }
    } catch (_) {
      setState(() => _message = "Could not fetch code automatically.");
    } finally {
      if (mounted) setState(() => _isFetchingCode = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _spinnerTimer?.cancel();
    super.dispose();
  }

  void _startSpinnerAnimation(int finalNumber, double rewardAmount) {
    setState(() {
      _isSpinning = true;
      _message = "Rolling...";
    });

    final random = Random();
    int ticks = 0;
    const maxTicks = 40; // 2 seconds at 50ms per tick

    _spinnerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      ticks++;
      if (ticks >= maxTicks) {
        timer.cancel();
        setState(() {
          _isSpinning = false;
          _currentDisplayNumber = finalNumber;
          _message = "Congratulations! You won $rewardAmount DOGE!";
        });
      } else {
        setState(() {
          _currentDisplayNumber = random.nextInt(999) + 1;
        });
      }
    });
  }

  Future<void> _claimPromoCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isClaiming = true;
      _message = "";
      _currentDisplayNumber = 0;
    });

    try {
      final response = await http.post(
        Uri.parse('https://golden-paw-vault.onrender.com/claim-promo'),
        headers: await getAuthHeaders(),
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        int rolledNumber = data['rolledNumber'];
        double reward = data['rewardAmount'];
        _startSpinnerAnimation(rolledNumber, reward);
      } else {
        setState(() {
          _message = data['error'] ?? "Failed to claim promo code.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Network error. Please try again later.";
      });
    } finally {
      setState(() {
        _isClaiming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode;

    return AppScaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Daily Promo Code",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Bitcotasks728x90AdWidget(),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.amber,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Daily Promo Spinner!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Enable Push Notifications to receive a new secret word every day at 6:00 AM UK time! Enter the code below or click the code generator to spin the wheel for up to 0.10 DOGE.",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),

                        // Code Generator Quick Button
                        OutlinedButton.icon(
                          onPressed: _isFetchingCode ? null : _fetchTodayCode,
                          icon: _isFetchingCode
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.amber,
                                  ),
                                )
                              : const Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                          label: const Text(
                            "GET TODAY'S CODE",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.amber,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // The Spinner
                        Container(
                          width: 150,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.amber, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _currentDisplayNumber.toString().padLeft(3, '0'),
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Input Field
                        TextField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter secret word...",
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                            filled: true,
                            fillColor: isDark
                                ? themeProvider.darkGreyBorder
                                : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Claim Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isClaiming || _isSpinning
                                ? null
                                : _claimPromoCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isClaiming
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    "SPIN & CLAIM",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),

                        if (_message.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _message.contains("Congratulations")
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
