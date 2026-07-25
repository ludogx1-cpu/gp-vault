import 'package:provider/provider.dart';
import '../src/user_provider.dart';
import '../src/js_bindings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:url_launcher/url_launcher.dart';
import '../widgets/universal_web_view/universal_web_view.dart';
import '../widgets/newsletter_subscribe_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';

import '../widgets/pet_overlay_widget.dart';
import '../widgets/chat_box_widget.dart';
import '../api_constants.dart';
import '../src/notification_service.dart';



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

  bool _isLoadingLeaderboard = true;
  List<dynamic> _leaderboard = [];
  String _leaderboardError = '';


  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
    _fetchDogePrice();
    _syncCheckLock();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoadingLeaderboard = true;
      _leaderboardError = '';
    });
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/leaderboard'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _leaderboard = data['leaderboard'] ?? [];
              _isLoadingLeaderboard = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _leaderboardError = data['error'] ?? 'Failed to load leaderboard.';
              _isLoadingLeaderboard = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _leaderboardError = 'Server error: ${response.statusCode}';
            _isLoadingLeaderboard = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leaderboardError = 'Network error: $e';
          _isLoadingLeaderboard = false;
        });
      }
    }
  }

  Widget _buildPrizeTier(String rank, String prize, Color color) {
    return Column(
      children: [
        Text(rank, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(prize, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _captchaPoller?.cancel();
    _addressController.dispose();
    super.dispose();
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
    if (price <= 0.02) {
      return 0.01;
    }
    if (price >= 0.20) {
      return 0.001;
    }
    return 0.01 - ((price - 0.02) / 0.18) * 0.009;
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
      // ignore: empty_catches
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
      // ignore: empty_catches
    }
  }

  Future<void> _syncRemoveLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gp_lock_time');
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


  void _openFaucetPayLink() {
    launchUrl(Uri.parse('https://faucetpay.io/?r=5173106'));
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
    return AppScaffold(
      appBar: const GlobalAppBar(),
      body: MouseRegion(
        onHover: (event) {
          globalMouseX = event.position.dx;
          globalMouseY = event.position.dy;
        },
        hitTestBehavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            PageWithFooter(
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

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 728,
                    height: 90,
                    child: UniversalWebView.create(viewType: 'adsterra-728x90', width: 728, height: 90),
                  ),
                ),
                const SizedBox(height: 20),
                const BitcotasksAdWidget(),
                const SizedBox(height: 20),

                const SizedBox(
                  width: 120,
                  height: 120,
                  child: Image(
                    image: AssetImage('assets/logo_landing.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),

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
                                          : Colors.black87,
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

                const SizedBox(height: 20),

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
                          if (streak < 1) { streak = 1; }
                          
                          double streakMultiplier = 1.0;
                          if (streak == 2) {
                            streakMultiplier = 1.1;
                          } else if (streak == 3) { streakMultiplier = 1.2; }
                          else if (streak == 4) { streakMultiplier = 1.3; }
                          else if (streak == 5) { streakMultiplier = 1.4; }
                          else if (streak == 6) { streakMultiplier = 1.5; }
                          else if (streak >= 7) { streakMultiplier = 1.6; }
                          
                          int level = sqrt(xp / 100).floor();
                          if (level > 100) { level = 100; }
                          int levelBonus = level;
                          int streakBonus = streak;
                          int totalBonusPercent = levelBonus + streakBonus;
                          double baseReward = _getBaseReward(_currentDogePrice);
                          double expectedReward =
                              baseReward * (1 + (totalBonusPercent / 100));

                          return Column(
                            children: [
                              const ShibaPetWidget(),
                              const SizedBox(height: 20),
                              ListenableBuilder(
                                listenable: themeProvider,
                                builder: (context, _) {
                                  final isDark = themeProvider.isDarkMode;
                                  return Container(
                                    width: double.infinity,
                                    constraints: const BoxConstraints(maxWidth: 800),
                                    decoration: BoxDecoration(
                                      color: isDark ? themeProvider.darkGreyBoxColor : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: isDark
                                          ? Border.all(color: themeProvider.darkGreyBorder, width: 1)
                                          : null,
                                    ),
                                    child: ExpansionTile(
                                      title: const Text(
                                        '🏆 Weekly Pet Leaderboard (Top 10)',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      subtitle: const Text(
                                        'Take the best care of your pet to win free DOGE every Sunday at midnight!',
                                        style: TextStyle(fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            children: [
                                              Card(
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                color: isDark ? Colors.grey.shade800 : Colors.amber.shade50,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12.0),
                                                  child: Column(
                                                    children: [
                                                      const Text(
                                                        'Top 5 Prizes',
                                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          _buildPrizeTier('1st', '3 DOGE', Colors.amber),
                                                          _buildPrizeTier('2nd', '2 DOGE', Colors.grey.shade400),
                                                          _buildPrizeTier('3rd', '1 DOGE', Colors.orange.shade300),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          _buildPrizeTier('4th', '0.5 DOGE', Colors.blueGrey),
                                                          _buildPrizeTier('5th', '0.25 DOGE', Colors.blueGrey),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              if (_isLoadingLeaderboard)
                                                const Padding(
                                                  padding: EdgeInsets.all(20.0),
                                                  child: CircularProgressIndicator(),
                                                )
                                              else if (_leaderboardError.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.all(20.0),
                                                  child: Text(_leaderboardError, style: const TextStyle(color: Colors.red)),
                                                )
                                              else if (_leaderboard.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.all(20.0),
                                                  child: Text('No scores yet! Feed your pet to get on the board.'),
                                                )
                                              else
                                                Container(
                                                  constraints: const BoxConstraints(maxHeight: 350),
                                                  child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: _leaderboard.length > 10 ? 10 : _leaderboard.length,
                                                    itemBuilder: (context, index) {
                                                      final item = _leaderboard[index];
                                                      final rank = index + 1;
                                                      final username = item['username'] ?? 'Anonymous';
                                                      final score = item['weekly_time_above_40'] ?? 0;
                                                      final petName = item['pet_name'] ?? 'Golden Paw Shiba';
                                                      final isAi = item['is_ai'] == true;

                                                      Color rankColor;
                                                      if (rank == 1) { rankColor = Colors.amber; }
                                                      else if (rank == 2) { rankColor = Colors.grey.shade400; }
                                                      else if (rank == 3) { rankColor = Colors.orange.shade300; }
                                                      else { rankColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black; }

                                                      return Card(
                                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                                        child: ListTile(
                                                          leading: CircleAvatar(
                                                            backgroundColor: rankColor.withValues(alpha: 0.2),
                                                            child: Text(
                                                              '#$rank',
                                                              style: TextStyle(color: rankColor, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                          title: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    username,
                                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                                  ),
                                                                  if (isAi)
                                                                    const Padding(
                                                                      padding: EdgeInsets.only(left: 4.0),
                                                                      child: Icon(Icons.verified, size: 14, color: Colors.blue),
                                                                    ),
                                                                ],
                                                              ),
                                                              Text(
                                                                'Pet: $petName',
                                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                              ),
                                                            ],
                                                          ),
                                                          trailing: Text(
                                                            '$score Hours >40% Stats',
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              ListenableBuilder(
                                listenable: themeProvider,
                                builder: (context, _) {
                                  final isDark = themeProvider.isDarkMode;
                                  return Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
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
                                      "Base: ${baseReward.toStringAsFixed(6)}  |  Lvl Bonus: +$levelBonus%  |  Streak: Day $streak (${streakMultiplier}x)",
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
                                      "Your base reward scales dynamically against the USD value of DOGE between 0.001 and 0.01. The cheaper DOGE gets, the more you earn!",
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
                              );
                            },
                          ),
                        ],
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
                            constraints: const BoxConstraints(maxWidth: 800),
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
                                  "Rewards scale dynamically between 0.001 and 0.01. If the USD value of DOGE drops, you earn more DOGE!",
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

                const SizedBox(height: 20),


          const SizedBox(height: 20),

                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('updates')
                      .orderBy('timestamp', descending: true)
                      .limit(10)
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
                          constraints: const BoxConstraints(maxWidth: 800),
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
                              const SizedBox(height: 20),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: Scrollbar(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: snapshot.data!.docs.asMap().entries.map((entry) {
                                        int index = entry.key;
                                        var data = entry.value.data() as Map<String, dynamic>;
                                        bool isLatest = index == 0;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 15, right: 10, left: 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                data['title'] ?? 'Update',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isLatest ? 15 : 12,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                data['content'] ?? (data['message'] ?? ''),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: isLatest ? 13 : 11,
                                                  color: isDark ? Colors.white70 : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "For support, contact: goldenpaw.dogeadmin@gmail.com",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security, color: Colors.yellow, size: 20),
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
                              color: isDark ? Colors.amber : Colors.black87,
                            ),
                            elevation: 16,
                            style: TextStyle(
                              color: isDark ? Colors.amber : Colors.black87,
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

                const SizedBox(height: 20),
                Container(
                  height: 120,
                  width: 340,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
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
                          UniversalWebView.create(
                            viewType: 'hcaptcha-widget',
                            width: 320,
                            height: 90,
                            onMessageReceived: _onCaptchaMessage,
                          )
                        else if (_selectedCaptcha == 'Turnstile' &&
                            _secondsRemaining == 0)
                          UniversalWebView.create(
                            viewType: 'turnstile-widget',
                            width: 320,
                            height: 90,
                            onMessageReceived: _onCaptchaMessage,
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
                              style: TextStyle(color: Colors.black87),
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
                        int minutesLeftBonus = 0;
                        
                        bool canClaimEcoVideo = true;
                        int minutesLeftEcoVideo = 0;

                        final userData = userProvider.userData;
                        if (userData != null) {
                          final Timestamp? lastClaimBonus = userData['last_bonus_sponsor_claim'];
                          if (lastClaimBonus != null) {
                            final difference = DateTime.now().difference(lastClaimBonus.toDate());
                            if (difference.inMinutes < 15) { // The backend is 15 minutes!
                              canClaimBonus = false;
                              minutesLeftBonus = 15 - difference.inMinutes;
                            }
                          }

                          final Timestamp? lastEcoVideo = userData['last_ecosystem_video_claim'];
                          if (lastEcoVideo != null) {
                            final difference = DateTime.now().difference(lastEcoVideo.toDate());
                            if (difference.inMinutes < 30) { // The backend is 30 minutes!
                              canClaimEcoVideo = false;
                              minutesLeftEcoVideo = 30 - difference.inMinutes;
                            }
                          }
                        }
                        return ListenableBuilder(
                          listenable: themeProvider,
                          builder: (context, _) {
                            final isDark = themeProvider.isDarkMode;
                            return Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(maxWidth: 800),
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
                                              : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      const Text(
                                        "Support Sponsors (0.004 DOGE) or Watch the\nEcosystem Video (0.003 DOGE) for extra rewards & XP!",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
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
                                                : 'COOLDOWN: $minutesLeftBonus MIN',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          onPressed: canClaimBonus
                                              ? () {
                                                  launchUrl(Uri.base.resolve('sponsors.html'));
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
                                      const SizedBox(height: 15),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: canClaimEcoVideo
                                                ? Colors.red.shade600
                                                : Colors.grey,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: Icon(
                                            canClaimEcoVideo
                                                ? Icons.play_circle_fill
                                                : Icons.lock_clock,
                                          ),
                                          label: Text(
                                            canClaimEcoVideo
                                                ? 'WATCH: GOLDEN PAW ECOSYSTEM'
                                                : 'COOLDOWN: $minutesLeftEcoVideo MIN',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          onPressed: canClaimEcoVideo
                                              ? () {
                                                  launchUrl(Uri.parse('https://www.youtube.com/watch?v=_P9YSHwbcC0'));
                                                  showDialog(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder: (context) =>
                                                        const BonusTimerDialog(
                                                          durationSeconds: 30,
                                                          endpoint: 'https://golden-paw-vault.onrender.com/claim-ecosystem-video',
                                                          targetUrl: 'https://www.youtube.com/watch?v=_P9YSHwbcC0',
                                                        ),
                                                  );
                                                }
                                              : null,
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
                  },
                ),
                const SizedBox(height: 20),
                const Bitcotasks160x600AdWidget(),
                const SizedBox(height: 20),
                const NewsletterSubscribeWidget(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      const PetOverlayWidget(),
      const ChatBoxWidget(),
      ],
    ),
  ),
);
  }
}

// ==========================================
// 3. THE STAKING PAGE
// ==========================================


