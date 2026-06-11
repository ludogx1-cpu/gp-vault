import 'package:provider/provider.dart';
import '../src/user_provider.dart';
import '../src/js_bindings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';
import '../api_constants.dart';




// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class FaucetPage extends StatefulWidget {
  const FaucetPage({super.key});
  @override
  State<FaucetPage> createState() => _FaucetPageState();
}

class _FaucetPageState extends State<FaucetPage> {
  final TextEditingController _addressController = TextEditingController();
  String _status = "Ready to Claim";
  bool _isLoading = false;
  bool _captchaLoading = false;
  String? _captchaToken;
  String _selectedCaptcha = 'hCaptcha';
  bool _saveToVault = false;
  Timer? _countdownTimer;
  Timer? _captchaPoller;
  int _secondsRemaining = 0;
  double _currentDogePrice = 0.15;

  bool _isCheckingCooldown = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
    _fetchDogePrice();
    _syncCheckLock();

    _captchaPoller = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      try {
        final div =
            web.document.getElementById('gp-captcha-token') as web.HTMLElement?;
        if (div != null) {
          final token = div.innerText;
          if (token.isNotEmpty && _captchaToken != token) {
            if (mounted) {
              setState(() {
                _captchaToken = token;
                _status = "Dog Verified! 🐾";
              });
            }
            div.innerText = "";
          }
        }
      } catch (e) {
        // ignore: empty_catches
      }
    });

    web.EventStreamProviders.messageEvent.forTarget(web.window).listen((
      web.Event event,
    ) {
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
                _status = "Dog Verified! 🐾";
              });
            }
          }
        }
      } catch (e) {
        // ignore: empty_catches
      }
    });
  }

  Future<void> _fetchDogePrice() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=DOGEUSDT',
        ),
      );
      if (res.statusCode == 200 && mounted) {
        setState(
          () => _currentDogePrice = double.parse(jsonDecode(res.body)['price']),
        );
      }
    } catch (e) {
      // ignore: empty_catches
    }
  }

  double _getBaseReward(double price) {
    if (price <= 0.05) {
      return 0.0008;
    }
    if (price >= 0.50) {
      return 0.0002;
    }
    return 0.0008 - ((price - 0.05) / 0.45) * 0.0006;
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

  void _syncCheckLock() {
    try {
      String? lock = web.window.localStorage.getItem('gp_lock_time');
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
            web.window.localStorage.removeItem('gp_lock_time');
          }
        }
      }
    } catch (e) {
      // ignore: empty_catches
    }
    if (mounted) {
      setState(() => _isCheckingCooldown = false);
    }
  }

  void _syncSaveLock() {
    try {
      web.window.localStorage.setItem(
        'gp_lock_time',
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      // ignore: empty_catches
    }
  }

  void _syncRemoveLock() {
    try {
      web.window.localStorage.removeItem('gp_lock_time');
    } catch (e) {
      // ignore: empty_catches
    }
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _secondsRemaining = 0;
      });
    }
  }

  void _resumeTimer() {
    if (mounted) {
      setState(() => _isCheckingCooldown = false);
    }
    _countdownTimer?.cancel();

    String? lock = web.window.localStorage.getItem('gp_lock_time');
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
            const SnackBar(
              content: Text(
                "Timer complete! 🐾 Please refresh the page to load your next Captcha.",
              ),
              duration: Duration(seconds: 8),
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
        // ignore: empty_catches
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

    bool? proceedToClaim = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const InterstitialAdDialog(),
    );

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
    }

    try {
      if (_saveToVault && user != null) {
        final response = await http
            .post(
              Uri.parse(ApiConstants.baseUrl + '/claim-vault'),
              headers: await getAuthHeaders(),
              body: jsonEncode({}),
            )
            .timeout(const Duration(seconds: 60));

        if (!mounted) {
          return;
        }

        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          setState(() {
            _status = "${resData['message']} (+10 XP!)";
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.star, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "+10 XP Earned! 🚀",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              backgroundColor: Colors.purple.shade600,
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
              Uri.parse(ApiConstants.baseUrl + '/send-doge'),
              headers: {"Content-Type": "application/json"},
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _captchaPoller?.cancel();
    super.dispose();
  }

  void _openFaucetPayLink() {
    web.window.open('https://faucetpay.io/?r=5173106', '_blank');
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
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GlobalAppBar(),
      body: PageWithFooter(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(context).scale(1.0) * 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BannerAdPlaceholder(),
                const SizedBox(height: 15),

                const SizedBox(
                  width: 120,
                  height: 120,
                  child: Image(
                    image: AssetImage('assets/logo_landing.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 15),

                ListenableBuilder(
                  listenable: themeProvider,
                  builder: (context, _) {
                    final isDark = themeProvider.isDarkMode;
                    return AnimatedHoverCard(
                      backgroundColor: isDark
                          ? themeProvider.darkGreyBoxColor
                          : Colors.amber[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isDark
                            ? themeProvider.darkGreyBorder
                            : Colors.amber.shade200,
                        width: 1,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    "🌟 Welcome to the Golden Paw Faucet! 🌟",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.brown,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "We make earning crypto simple. Whether you are here to grab some quick Dogecoin or want to build a long-term balance, you are in the right place.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "•  Enter your Dogecoin address below and claim your free Doge instantly to FaucetPay.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "• Optionally toggle the switch to Hold it and move it to the Staking pool to earn passive rewards.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      "•  Withdraw directly to ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    InkWell(
                                      onTap: _openFaucetPayLink,
                                      child: const Text(
                                        "FaucetPay",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      " whenever you are ready.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    if (user != null) {
                      return Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          final data = userProvider.userData;
                          int xp = (data?['xp'] ?? 0).toInt();
                          int streak = (data?['streak_count'] ?? 0).toInt();
                          int level = sqrt(xp / 100).floor();
                          if (level > 100) level = 100;
                          int levelBonus = level;
                          int streakBonus = streak;
                          int totalBonusPercent = levelBonus + streakBonus;
                          double baseReward = _getBaseReward(_currentDogePrice);
                          double expectedReward =
                              baseReward * (1 + (totalBonusPercent / 100));

                          return Column(
                            children: [
                              const ShibaPetWidget(),
                              const SizedBox(height: 15),
                              ListenableBuilder(
                                listenable: themeProvider,
                                builder: (context, _) {
                              final isDark = themeProvider.isDarkMode;
                              return Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? themeProvider.darkGreyBoxColor
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isDark
                                      ? Border.all(
                                          color: themeProvider.darkGreyBorder,
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Current Vault Reward: +${expectedReward.toStringAsFixed(6)} DOGE  &  +10 XP",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.amber.shade300
                                                : Colors.green.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Base: ${baseReward.toStringAsFixed(6)}  |  Lvl Bonus: +$levelBonus%  |  Streak Bonus: +$streakBonus%",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.amber.shade200
                                            : Colors.green.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Divider(
                                      color: isDark
                                          ? Colors.amber.withValues(alpha: 0.5)
                                          : Colors.green,
                                      height: 2,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Earn 10 XP per claim to level up and boost your daily multipliers!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.green.shade900,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "Your base reward scales dynamically against the USD value of DOGE. The cheaper DOGE gets, the more you earn!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.green.shade800,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                            },
                          );
                        },
                      );
                    } else {
                      return ListenableBuilder(
                        listenable: themeProvider,
                        builder: (context, _) {
                          final isDark = themeProvider.isDarkMode;
                          return Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 600),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? themeProvider.darkGreyBoxColor
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: isDark
                                  ? Border.all(
                                      color: themeProvider.darkGreyBorder,
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Current Base Reward: ${_getBaseReward(_currentDogePrice).toStringAsFixed(6)} DOGE\n(Log in to unlock XP & Multipliers!)",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.amber.shade300
                                        : Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Rewards scale dynamically. If the USD value of DOGE drops, you earn more DOGE!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.green.shade900,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                ),

                const SizedBox(height: 25),

                const SizedBox(height: 30),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('updates')
                      .orderBy('timestamp', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ListenableBuilder(
                      listenable: themeProvider,
                      builder: (context, _) {
                        final isDark = themeProvider.isDarkMode;
                        return Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 600),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? themeProvider.darkGreyBoxColor : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isDark ? themeProvider.darkGreyBorder : Colors.blue.shade200,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.campaign, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
                                  const SizedBox(width: 8),
                                  Text(
                                    "LATEST UPDATES",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isDark ? Colors.blueAccent : Colors.blue.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              ...snapshot.data!.docs.map((doc) {
                                var data = doc.data() as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Update',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['message'] ?? '',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 35),
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
                              color: _saveToVault
                                  ? Colors.green.shade300
                                  : Colors.amber.shade300,
                              width: 2,
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
                                        ? "Routing to Vault"
                                        : "Send to FaucetPay",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _saveToVault
                                          ? Colors.green.shade800
                                          : Colors.brown,
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
                  PointerInterceptor(
                    child: TextField(
                      controller: _addressController,
                      enabled: _secondsRemaining == 0,
                      onChanged: (value) => _saveAddress(value),
                      decoration: InputDecoration(
                        labelText: 'FaucetPay Dogecoin Address',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.amber,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security, color: Colors.brown, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Security:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ListenableBuilder(
                      listenable: themeProvider,
                      builder: (context, _) {
                        final isDark = themeProvider.isDarkMode;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? themeProvider.darkGreyBoxColor
                                : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? themeProvider.darkGreyBorder
                                  : Colors.amber.shade200,
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCaptcha,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: isDark ? Colors.amber : Colors.brown,
                            ),
                            elevation: 16,
                            style: TextStyle(
                              color: isDark ? Colors.amber : Colors.brown,
                              fontWeight: FontWeight.bold,
                            ),
                            underline: Container(),
                            onChanged: _secondsRemaining > 0
                                ? null
                                : (String? value) {
                                    setState(() {
                                      _selectedCaptcha = value!;
                                      _captchaToken = null;
                                      _captchaLoading = false;
                                      _status = "Ready to Claim";
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
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                Container(
                  height: 120,
                  width: 340,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: PointerInterceptor(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isCheckingCooldown)
                          const Center(
                            child: Text(
                              "Checking Vault Status...",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else if (_selectedCaptcha == 'hCaptcha' &&
                            _secondsRemaining == 0)
                          const SizedBox(
                            width: 320,
                            height: 90,
                            child: HtmlElementView(viewType: 'hcaptcha-widget'),
                          )
                        else if (_selectedCaptcha == 'Turnstile' &&
                            _secondsRemaining == 0)
                          const SizedBox(
                            width: 320,
                            height: 90,
                            child: HtmlElementView(
                              viewType: 'turnstile-widget',
                            ),
                          ),

                        if (!_isCheckingCooldown &&
                            !_captchaLoading &&
                            _secondsRemaining == 0)
                          ElevatedButton(
                            onPressed: _forceRenderCaptcha,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade100,
                              elevation: 0,
                            ),
                            child: const Text(
                              "Tap to Load Captcha",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        if (!_isCheckingCooldown && _secondsRemaining > 0)
                          Container(
                            color: Colors.white,
                            child: const Center(
                              child: Text(
                                "Wait for timer...",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 160,
                  runSpacing: 30,
                  children: [
                    const SquareAdPlaceholder(slotId: 'square_left'),
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
                                ),
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
                    const SquareAdPlaceholder(slotId: 'square_right'),
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

                const SizedBox(height: 40),

                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, authSnapshot) {
                    final user = authSnapshot.data;
                    if (user == null) {
                      return const SizedBox.shrink();
                    }

                    return Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        bool canClaimBonus = true;
                        int minutesLeft = 0;
                        final userData = userProvider.userData;
                        if (userData != null) {
                          final Timestamp? lastClaim =
                              userData['last_bonus_sponsor_claim'];

                          if (lastClaim != null) {
                            final now = DateTime.now();
                            final difference = now.difference(
                              lastClaim.toDate(),
                            );
                            if (difference.inHours < 3) {
                              canClaimBonus = false;
                              minutesLeft = 180 - difference.inMinutes;
                            }
                          }
                        }

                        return ListenableBuilder(
                          listenable: themeProvider,
                          builder: (context, _) {
                            final isDark = themeProvider.isDarkMode;
                            return Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 600),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? themeProvider.darkGreyBoxColor
                                    : (canClaimBonus
                                          ? Colors.amber.shade100
                                          : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isDark
                                      ? themeProvider.darkGreyBorder
                                      : (canClaimBonus
                                            ? Colors.amber.shade400
                                            : Colors.grey.shade400),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "🌟 Support Golden Paw & Boost the Faucet 🌟",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.brown,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    "Stay on the page for 30 seconds to earn\n0.006 DOGE & 60 XP!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: canClaimBonus
                                            ? Colors.amber
                                            : Colors.grey,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      icon: Icon(
                                        canClaimBonus
                                            ? Icons.card_giftcard
                                            : Icons.lock_clock,
                                      ),
                                      label: Text(
                                        canClaimBonus
                                            ? 'VIEW BONUS SPONSORS'
                                            : 'COOLDOWN: $minutesLeft MIN',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      onPressed: canClaimBonus
                                          ? () {
                                              web.window.open(
                                                '/sponsors.html',
                                                '_blank',
                                              );
                                              showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (context) =>
                                                    const BonusTimerDialog(),
                                              );
                                            }
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. THE STAKING PAGE
// ==========================================

