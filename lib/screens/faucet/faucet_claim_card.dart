import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../src/theme_provider.dart';
import '../../src/firebase_service.dart';
import '../../src/js_bindings.dart';
import '../../src/notification_service.dart';
import '../../api_constants.dart';
import '../../widgets/universal_web_view/universal_web_view.dart';
import '../../widgets/widgets.dart';
import 'captcha_selector_widget.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FaucetClaimCard extends StatefulWidget {
  const FaucetClaimCard({super.key});

  @override
  State<FaucetClaimCard> createState() => _FaucetClaimCardState();
}

class _FaucetClaimCardState extends State<FaucetClaimCard> {
  final TextEditingController _addressController = TextEditingController();
  String _status = "Ready to Claim";
  bool _isLoading = false;
  bool _captchaLoading = false;
  String? _captchaToken;
  String _selectedCaptcha = 'hCaptcha';
  bool _saveToVault = false;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  bool _isCheckingCooldown = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
    _syncCheckLock();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  void _onCaptchaMessage(String messageStr) {
    try {
      if (messageStr.contains('captcha') || messageStr.contains('token')) {
        final data = jsonDecode(messageStr);
        final token = data['token'] ?? data['captcha_token'] ?? data['turnstile_token'];
        if (token != null) {
          if (mounted) {
            setState(() {
              _captchaToken = token;
              _status = "Dog Verified! 🐾";
            });
          }
        }
      }
    } catch (e) {
      /* ignore */
    }
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedAddress = prefs.getString('doge_address');
    if (savedAddress != null && savedAddress.isNotEmpty) {
      if (mounted) {
        setState(() {
          _addressController.text = savedAddress;
        });
      }
    }
  }

  Future<void> _saveAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doge_address', address.trim());
  }

  Future<void> _syncCheckLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? lock = prefs.getString('gp_lock_time');
      if (lock != null) {
        int ms = int.tryParse(lock) ?? 0;
        if (ms > 0) {
          int passed = DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(ms))
              .inSeconds;
          if (passed >= 0 && passed < 300) {
            if (mounted) {
              setState(() {
                _secondsRemaining = 300 - passed;
              });
            }
            _resumeTimer();
            return;
          } else {
            await prefs.remove('gp_lock_time');
          }
        }
      }
    } catch (e) {
      // ignore
    }
    if (mounted) {
      setState(() => _isCheckingCooldown = false);
    }
  }

  Future<void> _syncSaveLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'gp_lock_time',
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      // ignore
    }
  }

  Future<void> _syncRemoveLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gp_lock_time');
    } catch (e) {
      // ignore
    }
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _secondsRemaining = 0;
      });
    }
  }

  Future<void> _resumeTimer() async {
    if (mounted) {
      setState(() => _isCheckingCooldown = false);
    }
    _countdownTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    String? lock = prefs.getString('gp_lock_time');
    DateTime unlockTime;
    if (lock != null) {
      unlockTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lock),
      ).add(const Duration(seconds: 300));
    } else {
      unlockTime = DateTime.now().add(Duration(seconds: _secondsRemaining));
    }

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      int remaining = unlockTime.difference(DateTime.now()).inSeconds;

      if (remaining > 0) {
        if (remaining != _secondsRemaining) {
          setState(() => _secondsRemaining = remaining);
        }
      } else {
        setState(() {
          _secondsRemaining = 0;
          _status = "Ready to Claim";
          _captchaToken = null;
          _countdownTimer?.cancel();
          _syncRemoveLock();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Timer complete! 🐶 Please refresh the page to load your next Captcha.",
                style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black87),
              ),
              duration: const Duration(seconds: 8),
              backgroundColor: Colors.blue,
            ),
          );
        });
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
        // ignore
      }
      
      // Give the widget time to load, then hide the spinner
      if (mounted) {
        Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _captchaLoading = false);
          }
        });
      }
    });
  }

  Future<void> _claimDoge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!_saveToVault && _addressController.text.isEmpty) {
      setState(() => _status = "Address Required!");
      return;
    }

    setState(() {
      _isLoading = true;
      _status = "Waking up server...";
    });

    bool? proceedToClaim = await InterstitialAdDialog.showIfReady(context);

    if (proceedToClaim != true) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = "Ready to Claim";
        });
      }
      return;
    }

    _syncSaveLock();

    if (mounted) {
      setState(() {
        _secondsRemaining = 300;
        _status = "Verifying & Sending...";
      });
      _resumeTimer();
      NotificationService().scheduleBonusTimerNotification(const Duration(seconds: 300));
    }

    try {
      if (_saveToVault && user != null) {
        final response = await http
            .post(
              Uri.parse('${ApiConstants.baseUrl}/claim-vault'),
              headers: await getAuthHeaders(),
              body: jsonEncode({}),
            )
            .timeout(const Duration(seconds: 60));

        if (!mounted) {
          return;
        }

        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          FirebaseAnalytics.instance.logEvent(name: 'faucet_claim_vault_success');
          setState(() {
            _status = "${resData['message']} (+10 XP!)";
            _isLoading = false;
          });
          final earnedStr = resData['earned'] != null ? resData['earned'].toStringAsFixed(8) : "0.00000000";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.star, color: themeProvider.isDarkMode ? Colors.white : null),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "+10 XP Earned! 🐶\nYou claimed $earnedStr DOGE!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: themeProvider.isDarkMode ? 14 : 16, 
                        color: themeProvider.isDarkMode ? Colors.white : null,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.purple.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          _syncRemoveLock();
          setState(() {
            _status = "Error claiming to Vault.";
            _isLoading = false;
          });
        }
      } else {
        final response = await http
            .post(
              Uri.parse('${ApiConstants.baseUrl}/send-doge'),
              headers: await getAuthHeaders(),
              body: jsonEncode({
                "user_address": _addressController.text.trim(),
                "captcha_token": _captchaToken,
                "captcha_provider": _selectedCaptcha,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (!mounted) {
          return;
        }

        if (response.statusCode == 200) {
          FirebaseAnalytics.instance.logEvent(name: 'faucet_claim_direct_success');
          setState(() {
            _status = "Claim Sent to FaucetPay! 🚀 (+10 XP!)";
            _isLoading = false;
          });
        } else {
          _syncRemoveLock();
          final errorData = jsonDecode(response.body);
          setState(() {
            _status = "Declined: ${errorData['error']}";
            _captchaToken = null;
            _captchaLoading = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _syncRemoveLock();
      if (mounted) {
        setState(() {
          _status =
              "Server timeout. Trying to wake Render... try again in 10s.";
          _captchaLoading = false;
          _isLoading = false;
        });
      }
    }
  }

  String _getClaimButtonText() {
    if (_isCheckingCooldown) {
      return "LOADING...";
    }
    if (_secondsRemaining > 0) {
      return "WAIT: ${_secondsRemaining}s";
    }
    if (_captchaToken == null) {
      return "SOLVE CAPTCHA";
    }
    if (_isLoading) {
      return "SENDING...";
    }
    return _saveToVault ? "CLAIM TO VAULT" : "CLAIM DOGE";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        children: [
        StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 5,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _saveToVault
                        ? Colors.green.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _saveToVault
                                ? Icons.account_balance
                                : Icons.account_balance_wallet,
                            color: _saveToVault
                                ? Colors.green
                                : Colors.amber,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _saveToVault
                                ? "Routing to your wallet"
                                : "Send to FaucetPay",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _saveToVault
                                  ? Colors.green.shade800
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _saveToVault,
                        activeThumbColor: Colors.green,
                        inactiveThumbColor: Colors.amber,
                        onChanged: _secondsRemaining > 0
                            ? null
                            : (bool value) {
                                setState(() {
                                  _saveToVault = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Text(
                  "Create an account to unlock Vault saving & XP! 🏦",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              );
            }
          },
        ),

        const SizedBox(height: 10),
        if (!_saveToVault)
          TextField(
            controller: _addressController,
            enabled: _secondsRemaining == 0,
            onChanged: (value) => _saveAddress(value),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'FaucetPay Dogecoin Address',
              prefixIcon: const Icon(
                Icons.account_balance_wallet,
                color: Colors.amber,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.amber : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.amber : Colors.blue,
                  width: 2.0,
                ),
              ),
            ),
          ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Don't forget to toggle the button if you are not sending your claims directly to FaucetPay and are sending them to your Golden Paw Wallet instead.",
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),


        CaptchaSelectorWidget(
          selectedCaptcha: _selectedCaptcha,
          secondsRemaining: _secondsRemaining,
          isCheckingCooldown: _isCheckingCooldown,
          captchaLoading: _captchaLoading,
          onChanged: (String? value) {
            setState(() {
              _selectedCaptcha = value!;
              _captchaToken = null;
              _captchaLoading = false;
              _status = "Ready to Claim";
            });
          },
          onMessageReceived: _onCaptchaMessage,
          onForceRender: _forceRenderCaptcha,
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            SizedBox(
              width: 160,
              height: 60,
              child: ElevatedButton(
                onPressed:
                    (_isCheckingCooldown ||
                        _captchaToken == null ||
                        _isLoading ||
                        _secondsRemaining > 0)
                    ? null
                    : _claimDoge,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _secondsRemaining > 0 || _captchaToken == null
                      ? Colors.grey
                      : (_saveToVault ? Colors.green : Colors.amber),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      )
                    : Text(
                        _getClaimButtonText(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              height: 250,
              child: UniversalWebView.create(viewType: 'adsterra-300x250', width: 300, height: 250),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              height: 250,
              child: UniversalWebView.create(viewType: 'ccnsad-300x250', width: 300, height: 250),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Text(
          _status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _saveToVault
                ? Colors.green
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey.shade600),
          ),
        ),
      ],
    ));
  }
}
