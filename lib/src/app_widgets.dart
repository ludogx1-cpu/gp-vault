part of '../main.dart';

// ==========================================
// 🚀 THE GATEKEEPER
// ==========================================
class RootGatekeeper extends StatelessWidget {
  const RootGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }
        if (snapshot.hasData) {
          return const MainScaffold();
        }
        return LandingPage(
          onAuthTrigger: (context, isLogin) {
            showAuthDialogGlobal(context, isLogin);
          },
        );
      },
    );
  }
}

// ==========================================
// 🌟 SECURE AUTH DIALOG WIDGET
// ==========================================
void showAuthDialogGlobal(BuildContext context, bool isLogin) {
  showDialog(
    context: context,
    builder: (context) => AuthDialogWidget(isLogin: isLogin),
  );
}

class AuthDialogWidget extends StatefulWidget {
  final bool isLogin;
  const AuthDialogWidget({super.key, required this.isLogin});

  @override
  State<AuthDialogWidget> createState() => _AuthDialogWidgetState();
}

class _AuthDialogWidgetState extends State<AuthDialogWidget> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool rememberMe = false;
  bool isLoading = false;

  String _selectedCaptcha = 'hCaptcha';
  bool _captchaLoading = false;
  String? _captchaToken;
  Timer? _captchaPoller;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadPrefs();

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
              });
            }
            div.innerText = "";
          }
        }
      } catch (e) {
        // ignore: empty_catches
      }
    });

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
                }
              }
            }
          } catch (e) {
            // ignore: empty_catches
          }
        });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        emailCtrl.text = prefs.getString('vault_email') ?? '';
        passCtrl.text = prefs.getString('vault_password') ?? '';
        rememberMe = prefs.getString('vault_email') != null;
      });
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    _captchaPoller?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode;

    return AlertDialog(
      backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.isLogin ? "Welcome Back!" : "Join Golden Paw",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: gpBrownText(context),
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email Address",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      activeColor: Colors.amber,
                      onChanged: (bool? value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    Text(
                      "Remember Me",
                      style: TextStyle(
                        color: gpBrownText(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (widget.isLogin)
                  TextButton(
                    onPressed: () async {
                      if (emailCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter your email first."),
                          ),
                        );
                        return;
                      }
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: emailCtrl.text.trim(),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Reset email sent!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot?",
                      style: TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),

            // --- CAPTCHA UI ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? themeProvider.darkGreyBoxColor
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? themeProvider.darkGreyBorder
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security,
                        color: gpBrownText(context),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Bot Check:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.brown,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
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
                            color: Colors.brown,
                            size: 16,
                          ),
                          elevation: 16,
                          style: const TextStyle(
                            color: Colors.brown,
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _captchaToken != null
                            ? Colors.green
                            : Colors.amber,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: PointerInterceptor(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 🔑 FIXED: Removed illegal 'const' keyword that breaks HtmlElementView builds
                          if (_captchaToken == null &&
                              _selectedCaptcha == 'hCaptcha')
                            SizedBox(
                              width: 320,
                              height: 90,
                              child: HtmlElementView(
                                viewType: 'hcaptcha-widget',
                              ),
                            )
                          else if (_captchaToken == null &&
                              _selectedCaptcha == 'Turnstile')
                            SizedBox(
                              width: 320,
                              height: 90,
                              child: HtmlElementView(
                                viewType: 'turnstile-widget',
                              ),
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
                                style: TextStyle(color: Colors.brown),
                              ),
                            ),
                          if (_captchaToken != null)
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 30,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Verified Human!",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // --- EMAIL SIGN IN BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _captchaToken == null
                      ? Colors.grey.shade300
                      : Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: (isLoading || _captchaToken == null)
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          if (rememberMe) {
                            await prefs.setString(
                              'vault_email',
                              emailCtrl.text.trim(),
                            );
                            await prefs.setString(
                              'vault_password',
                              passCtrl.text.trim(),
                            );
                          } else {
                            await prefs.remove('vault_email');
                            await prefs.remove('vault_password');
                          }

                          if (widget.isLogin) {
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                  email: emailCtrl.text.trim(),
                                  password: passCtrl.text.trim(),
                                );
                          } else {
                            UserCredential userCred = await FirebaseAuth
                                .instance
                                .createUserWithEmailAndPassword(
                                  email: emailCtrl.text.trim(),
                                  password: passCtrl.text.trim(),
                                );
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userCred.user!.uid)
                                .set({
                                  'email': userCred.user!.email,
                                  'doge_balance': 0.0,
                                  'staked_balance': 0.0,
                                  'ads_balance': 0.0,
                                  'offerwall_balance':
                                      0.0, // 🔑 FIXED: Added missing init to prevent null errors in Wallet
                                  'xp': 0,
                                  'streak_count': 0,
                                  'joined_date': DateTime.now()
                                      .toIso8601String(),
                                });
                          }
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _captchaToken == null
                            ? "SOLVE CAPTCHA TO CONTINUE"
                            : (widget.isLogin
                                  ? "LOG IN WITH EMAIL"
                                  : "SIGN UP WITH EMAIL"),
                        style: TextStyle(
                          color: _captchaToken == null
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey.shade600)
                              : gpBrownText(
                                  context,
                                  darkColor: Colors.grey.shade900,
                                ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 15),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "OR",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 15),

            // --- 🚀 GOOGLE SIGN IN BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton.icon(
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                  height: 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.account_circle, color: Colors.blue),
                ),
                label: const Text(
                  "CONTINUE WITH GOOGLE",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          final authProvider = GoogleAuthProvider();
                          UserCredential userCred = await FirebaseAuth.instance
                              .signInWithPopup(authProvider);

                          final doc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userCred.user!.uid)
                              .get();
                          if (!doc.exists) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userCred.user!.uid)
                                .set({
                                  'email': userCred.user!.email,
                                  'doge_balance': 0.0,
                                  'staked_balance': 0.0,
                                  'ads_balance': 0.0,
                                  'offerwall_balance': 0.0,
                                  'xp': 0,
                                  'streak_count': 0,
                                  'joined_date': DateTime.now()
                                      .toIso8601String(),
                                });
                          }
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🚀 THE GLOBAL BINANCE REFERRAL TICKER
// ==========================================
class LiveReferralTracker extends StatefulWidget {
  const LiveReferralTracker({super.key});

  @override
  State<LiveReferralTracker> createState() => _LiveReferralTrackerState();
}

class _LiveReferralTrackerState extends State<LiveReferralTracker> {
  double _price = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchPrice();
    _timer = Timer.periodic(const Duration(seconds: 30), (t) => _fetchPrice());
  }

  Future<void> _fetchPrice() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=DOGEUSDT',
        ),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() => _price = double.parse(jsonDecode(res.body)['price']));
        }
      }
    } catch (e) {
      // ignore: empty_catches
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => web.window.open(
        'https://www.binance.com/activity/referral-entry/CPA?ref=CPA_00SAJGMUIA',
        '_blank',
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: kAppBarColor,
          border: Border(
            bottom: BorderSide(color: Colors.amber.shade700, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            const Text(
              "LIVE DOGE: ",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "\$${_price.toStringAsFixed(4)}",
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 15),
            const Text(
              "|  TRADE ON BINANCE 🚀",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 💰 WALLET DROPDOWN BUTTON
// ==========================================
class WalletDropdownButton extends StatefulWidget {
  const WalletDropdownButton({super.key});
  @override
  State<WalletDropdownButton> createState() => _WalletDropdownButtonState();
}

class _WalletDropdownButtonState extends State<WalletDropdownButton> {
  double _mainBal = 0.0;
  double _offerwallBal = 0.0;
  StreamSubscription<DocumentSnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _listenToBalances();
  }

  void _listenToBalances() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          if (snapshot.exists) {
            final data = snapshot.data();
            setState(() {
              _mainBal = (data?['doge_balance'] ?? 0.0).toDouble();
              _offerwallBal = (data?['offerwall_balance'] ?? 0.0).toDouble();
            });
          }
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: Icon(Icons.account_balance_wallet, color: Colors.grey),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.account_balance_wallet,
          color: kAppBarIconColor,
          size: 28,
        ),
        tooltip: "View Balances",
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        offset: const Offset(0, 50),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Main Wallet",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Faucet & Staking rewards — stakable",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.monetization_on,
                        color: Colors.amber.shade800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${_mainBal.toStringAsFixed(6)} DOGE",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Offerwall Wallet",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Task rewards — withdrawable only",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment_turned_in,
                        color: Colors.purple.shade800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${_offerwallBal.toStringAsFixed(6)} DOGE",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ✨ GLOBAL APP BAR WIDGET ✨
// ==========================================
class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackArrow;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showWallet;

  const GlobalAppBar({
    super.key,
    this.showBackArrow = false,
    this.actions,
    this.centerTitle = false,
    this.showWallet = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      color: kAppBarColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LiveReferralTracker(),
            AppBar(
              primary: false,
              toolbarHeight: 70,
              backgroundColor: kAppBarColor,
              elevation: 10,
              shadowColor: Colors.black45,
              centerTitle: isMobile ? false : centerTitle,
              iconTheme: const IconThemeData(color: kAppBarIconColor),
              titleSpacing: showBackArrow ? 0 : 16,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/logo2.png',
                    height: isMobile ? 36 : 42,
                    fit: BoxFit.contain,
                  ),
                  Transform.translate(
                    offset: const Offset(-4, 0),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0.5),
                      child: Text(
                        'Doge Hub',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              leading: showBackArrow
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              actions: [
                if (actions != null) ...actions!,
                if (showWallet)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: WalletDropdownButton(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(140);
}

// ==========================================
// 🌟 THE LANDING PAGE
// ==========================================
class LandingPage extends StatelessWidget {
  final void Function(BuildContext, bool) onAuthTrigger;

  const LandingPage({super.key, required this.onAuthTrigger});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlobalAppBar(
        centerTitle: false,
        showWallet: false,
        actions: [
          // --- LOG IN BUTTON ---
          TextButton(
            onPressed: () => onAuthTrigger(context, true),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
            ),
            child: Text(
              "LOG IN",
              style: TextStyle(
                color: kTextColorOnBlack,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 13 : 16,
              ),
            ),
          ),

          // --- SIGN UP BUTTON ---
          isMobile
              ? TextButton(
                  onPressed: () => onAuthTrigger(context, false),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    "SIGN UP",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ElevatedButton(
                    onPressed: () => onAuthTrigger(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "SIGN UP",
                      style: TextStyle(
                        color: Colors.brown,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: PageWithFooter(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/logo_landing.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 25),
                  ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, child) {
                      return Text(
                        "The Smartest Way to\nEarn Dogecoin",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Arial Black',
                          fontSize: isMobile ? 26 : 33,
                          letterSpacing: -1.0,
                          fontWeight: FontWeight.w900,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.brown.shade900.withValues(alpha: 0.9),
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: themeProvider.isDarkMode
                                  ? Colors.black
                                  : Colors.white.withValues(alpha: 0.9),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, child) {
                      return Text(
                        "Claim free DOGE every 5 minutes, earn 8.5% interest in The Vault,\nand grow your wealth with our automated ecosystem.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 18,
                          color: themeProvider.isDarkMode
                              ? Colors.white70
                              : Colors.brown.shade800,
                          height: 1.5,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: themeProvider.isDarkMode
                                  ? Colors.black
                                  : Colors.white.withValues(alpha: 0.9),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 250,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => onAuthTrigger(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        shadowColor: Colors.amber.withValues(alpha: 0.5),
                      ),
                      child: const Text(
                        "CREATE FREE ACCOUNT",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ListenableBuilder(
              listenable: themeProvider,
              builder: (context, child) {
                return Text(
                  "How it Works",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.brown,
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 30,
              runSpacing: 30,
              children: [
                FeatureCard(
                  icon: Icons.water_drop,
                  title: "Instant Faucet",
                  desc:
                      "Visit every 5 minutes to claim free Dogecoin. No hidden limits, just pure rewards.",
                  color: Colors.blue,
                ),
                FeatureCard(
                  icon: Icons.bolt,
                  title: "The Vault Staking",
                  desc:
                      "Lock your Doge in The Vault and earn 8.5% APY interest, calculated every single second.",
                  color: Colors.green,
                ),
                FeatureCard(
                  icon: Icons.group_add,
                  title: "20% Referrals",
                  desc:
                      "Invite your friends and earn 20% of every claim they make, for life. Passive income simplified.",
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color color;
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          width: 300,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDark ? Colors.black54 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.amber.withValues(alpha: 0.3)
                  : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.brown,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// THE GLOBAL DRAWER (HAMBURGER MENU)
// ==========================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // 🔒 HARDCODED ADMIN SECURITY CHECK
    final bool isAdmin = user != null && user.email == 'ludogx1@gmail.com';

    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        final Color titleColor = isDark ? Colors.white : Colors.brown;
        final Color subColor = isDark ? Colors.white70 : Colors.black87;
        final Color dividerColor = isDark
            ? themeProvider.darkGreyBorder
            : Colors.grey.shade300;

        return Drawer(
          backgroundColor: isDark
              ? themeProvider.darkGreyBoxColor
              : Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                // 👑 Softened the black to a deep charcoal (grey.shade900)
                decoration: BoxDecoration(color: Colors.grey.shade900),
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, authSnapshot) {
                    if (authSnapshot.hasData && authSnapshot.data != null) {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(authSnapshot.data!.uid)
                            .snapshots(),
                        builder: (context, dbSnapshot) {
                          int xp = 0;
                          int streak = 0;
                          if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                            var data =
                                dbSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                            xp = (data?['xp'] ?? 0).toInt();
                            streak = (data?['streak_count'] ?? 0).toInt();
                          }

                          int level = sqrt(xp / 100).floor();
                          if (level > 100) level = 100;
                          int currentLevelXp = 100 * (level * level);
                          int nextLevelXp = level >= 100
                              ? currentLevelXp
                              : 100 * ((level + 1) * (level + 1));
                          double progress = level >= 100
                              ? 1.0
                              : (xp - currentLevelXp) /
                                    (nextLevelXp - currentLevelXp);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.amber,
                                    radius: 25,
                                    child: Text(
                                      level.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Golden Paw Rank",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department,
                                              color: Colors.deepOrange,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              "$streak Day Streak",
                                              style: const TextStyle(
                                                color: Colors.deepOrange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white24,
                                color: Colors.green.shade500,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              const SizedBox(height: 5),
                              PlatformIndicatorLevelText(
                                level: level,
                                xp: xp,
                                currentLevelXp: currentLevelXp,
                                nextLevelXp: nextLevelXp,
                              ),
                            ],
                          );
                        },
                      );
                    }

                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.pets, size: 50, color: Colors.amber),
                        SizedBox(height: 10),
                        Text(
                          "Golden Paw Menu",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Guest User - Log in to Level Up!",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mouse, color: Colors.green),
                title: Text(
                  'Earn DOGE (PTC)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Click ads to earn crypto',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PtcEarnPage(),
                    ),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.group_add, color: Colors.purple),
                title: Text(
                  'Referral Program',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Earn 20% of friend claims',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReferralPage(),
                    ),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.campaign, color: Colors.blue),
                title: Text(
                  'Buy Ads / PTC',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Advertise your links here',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdHubPage()),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.green),
                title: Text(
                  'Bonus Partners',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Earn more crypto',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AffiliateLinksPage(),
                    ),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(
                  Icons.assignment_turned_in,
                  color: Colors.deepPurple,
                ),
                title: Text(
                  'Offerwalls',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Complete tasks to earn DOGE',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OfferwallHubPage(),
                    ),
                  );
                },
              ),
              Divider(color: dividerColor),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.orange),
                title: Text(
                  'VIP Premium',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  'Coming Soon...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white30 : Colors.grey,
                  ),
                ),
                onTap: () {},
              ),

              if (isAdmin) ...[
                const Divider(color: Colors.red, thickness: 2),
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: const Text(
                    'Boss Mode Activated',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardPage(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class PlatformIndicatorLevelText extends StatelessWidget {
  const PlatformIndicatorLevelText({
    super.key,
    required this.level,
    required this.xp,
    required this.currentLevelXp,
    required this.nextLevelXp,
  });

  final int level;
  final int xp;
  final int currentLevelXp;
  final int nextLevelXp;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        level >= 100
            ? "MAX LEVEL"
            : "${xp - currentLevelXp} / ${nextLevelXp - currentLevelXp} XP to Level ${level + 1}",
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ==========================================
// ✨ SMART FALLBACK AD LOGIC (MERGED LISTS)
// ==========================================
class SmartFallbackAd extends StatelessWidget {
  final double width;
  final double height;

  const SmartFallbackAd({super.key, required this.width, required this.height});

  IconData _getAdminIcon(String name) {
    switch (name) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'ptc':
        return Icons.ads_click;
      case 'faucet':
        return Icons.water_drop;
      case 'mining':
        return Icons.cloud_sync;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('partners').snapshots(),
      builder: (context, snapshot) {
        return ListenableBuilder(
          listenable: themeProvider,
          builder: (context, _) {
            final isDark = themeProvider.isDarkMode;

            // 1. 10% chance to show the "Buy an Ad" banner
            if (Random().nextInt(100) < 10) {
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdHubPage()),
                ),
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: isDark
                        ? themeProvider.darkGreyBoxColor
                        : Colors.orange.shade50,
                    border: isDark
                        ? Border.all(color: themeProvider.darkGreyBorder)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign,
                        color: isDark ? Colors.amber : Colors.orange,
                        size: height > 100 ? 40 : 24,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Get your ad placed here!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: height > 100 ? 14 : 12,
                          color: isDark ? Colors.white : Colors.brown,
                        ),
                      ),
                      Text(
                        "Click to visit Buy Ads",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: height > 100 ? 11 : 9,
                          color: isDark
                              ? Colors.white70
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 2. Otherwise, load the hybrid Affiliate Partners list!
            List<Map<String, dynamic>> allPartners = [];

            for (var p in partnerList) {
              allPartners.add({
                'title': p.title,
                'url': p.url,
                'iconName': 'star',
                'colorHex': p.color.toARGB32().toRadixString(16),
                '_isHardcoded': true,
                '_iconData': p.icon,
              });
            }

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                allPartners.add(doc.data() as Map<String, dynamic>);
              }
            }

            if (allPartners.isEmpty) {
              return SizedBox(width: width, height: height);
            }

            var data = allPartners[Random().nextInt(allPartners.length)];
            Color iconColor = data['_isHardcoded'] == true
                ? Color(int.parse(data['colorHex'] ?? 'ffffc107', radix: 16))
                : Colors.amber;
            IconData displayIcon = data['_isHardcoded'] == true
                ? data['_iconData']
                : _getAdminIcon(data['iconName'] ?? '');

            return InkWell(
              onTap: () => web.window.open(data['url'] ?? '', '_blank'),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: isDark
                      ? themeProvider.darkGreyBoxColor
                      : Colors.amber.shade50,
                  border: isDark
                      ? Border.all(color: themeProvider.darkGreyBorder)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      displayIcon,
                      color: iconColor,
                      size: height > 100 ? 40 : 24,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['title'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: height > 100 ? 14 : 12,
                        color: isDark ? Colors.white : Colors.brown,
                      ),
                    ),
                    Text(
                      "Partner Promotion",
                      style: TextStyle(
                        fontSize: height > 100 ? 10 : 9,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// ✨ SMART AD PLACEHOLDERS
// ==========================================
class BannerAdPlaceholder extends StatefulWidget {
  final String text;
  const BannerAdPlaceholder({super.key, this.text = ""});

  @override
  State<BannerAdPlaceholder> createState() => _BannerAdPlaceholderState();
}

class _BannerAdPlaceholderState extends State<BannerAdPlaceholder> {
  static const double _bannerWidth = 970;
  static const double _bannerHeight = 120;
  final int _seed = Random().nextInt(10000);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .where('slot_id', isEqualTo: 'global_banner')
          .snapshots(),
      builder: (context, snapshot) {
        Widget content;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final now = DateTime.now();
          var activeAds = snapshot.data!.docs.where((doc) {
            String expiresAtStr =
                (doc.data() as Map<String, dynamic>)['expires_at'] ?? '';
            if (expiresAtStr.isEmpty) return false;
            DateTime? expiresAt = DateTime.tryParse(expiresAtStr);
            return expiresAt != null && expiresAt.isAfter(now);
          }).toList();

          if (activeAds.isNotEmpty) {
            var adData =
                activeAds[_seed % activeAds.length].data()
                    as Map<String, dynamic>;
            if ((adData['image_url'] ?? '').isNotEmpty) {
              content = InkWell(
                onTap: () {
                  if ((adData['target_url'] ?? '').isNotEmpty) {
                    web.window.open(adData['target_url'], '_blank');
                  }
                },
                child: Image.network(
                  adData['image_url'],
                  fit: BoxFit.cover,
                  width: _bannerWidth,
                  height: _bannerHeight,
                ),
              );
            } else {
              content = const SmartFallbackAd(
                width: _bannerWidth,
                height: _bannerHeight,
              );
            }
          } else {
            content = const SmartFallbackAd(
              width: _bannerWidth,
              height: _bannerHeight,
            );
          }
        } else {
          content = const SmartFallbackAd(
            width: _bannerWidth,
            height: _bannerHeight,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _bannerWidth),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: _bannerWidth,
                height: _bannerHeight,
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SquareAdPlaceholder extends StatefulWidget {
  final String slotId;
  const SquareAdPlaceholder({super.key, required this.slotId});
  @override
  State<SquareAdPlaceholder> createState() => _SquareAdPlaceholderState();
}

class _SquareAdPlaceholderState extends State<SquareAdPlaceholder> {
  final int _seed = Random().nextInt(10000);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .where('slot_id', isEqualTo: widget.slotId)
          .snapshots(),
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final now = DateTime.now();
          var activeAds = snapshot.data!.docs.where((doc) {
            String expiresAtStr =
                (doc.data() as Map<String, dynamic>)['expires_at'] ?? '';
            if (expiresAtStr.isEmpty) return false;
            DateTime? expiresAt = DateTime.tryParse(expiresAtStr);
            return expiresAt != null && expiresAt.isAfter(now);
          }).toList();

          if (activeAds.isNotEmpty) {
            var adData =
                activeAds[_seed % activeAds.length].data()
                    as Map<String, dynamic>;
            if ((adData['image_url'] ?? '').isNotEmpty) {
              content = InkWell(
                onTap: () {
                  if ((adData['target_url'] ?? '').isNotEmpty) {
                    web.window.open(adData['target_url'], '_blank');
                  }
                },
                child: Image.network(
                  adData['image_url'],
                  fit: BoxFit.cover,
                  width: 300,
                  height: 250,
                ),
              );
            } else {
              content = const SmartFallbackAd(width: 300, height: 250);
            }
          } else {
            content = const SmartFallbackAd(width: 300, height: 250);
          }
        } else {
          content = const SmartFallbackAd(width: 300, height: 250);
        }

        return SizedBox(
          width: 300,
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: content,
          ),
        );
      },
    );
  }
}

class InterstitialAdDialog extends StatefulWidget {
  const InterstitialAdDialog({super.key});
  @override
  State<InterstitialAdDialog> createState() => _InterstitialAdDialogState();
}

class _InterstitialAdDialogState extends State<InterstitialAdDialog> {
  int _timeLeft = 6;
  Timer? _timer;
  final int _seed = Random().nextInt(10000);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) setState(() => _timeLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 350,
        height: 450,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Sponsor Advertisement",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ads')
                    .where('slot_id', isEqualTo: 'interstitial')
                    .snapshots(),
                builder: (context, snapshot) {
                  Widget content;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final now = DateTime.now();
                    var activeAds = snapshot.data!.docs.where((doc) {
                      String expiresAtStr =
                          (doc.data() as Map<String, dynamic>)['expires_at'] ??
                          '';
                      if (expiresAtStr.isEmpty) return false;
                      DateTime? expiresAt = DateTime.tryParse(expiresAtStr);
                      return expiresAt != null && expiresAt.isAfter(now);
                    }).toList();

                    if (activeAds.isNotEmpty) {
                      var adData =
                          activeAds[_seed % activeAds.length].data()
                              as Map<String, dynamic>;
                      if ((adData['image_url'] ?? '').isNotEmpty) {
                        content = InkWell(
                          onTap: () {
                            if ((adData['target_url'] ?? '').isNotEmpty) {
                              web.window.open(adData['target_url'], '_blank');
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber, width: 2),
                              image: DecorationImage(
                                image: NetworkImage(adData['image_url']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      } else {
                        content = const SmartFallbackAd(
                          width: 300,
                          height: 250,
                        );
                      }
                    } else {
                      content = const SmartFallbackAd(width: 300, height: 250);
                    }
                  } else {
                    content = const SmartFallbackAd(width: 300, height: 250);
                  }

                  return PointerInterceptor(child: content);
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_timeLeft > 0)
              Text(
                "You can claim in $_timeLeft seconds...",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            else
              PointerInterceptor(
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "CONTINUE TO CLAIM",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ✨ PROFESSIONAL FOOTER WIDGET ✨
// ==========================================
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  void _showDonateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Support Golden Paw 🐾",
          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Your donations help keep the faucet filled and rewards high for the whole community!",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "Our Dogecoin (DOGE) Address:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const SelectableText(
                "DDcrrGX7SzzdExq3pFo7fayrWfuvrPgX9d",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "(Long press to copy address)",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 12.0),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.amber.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: const Text(
                  "GOLDEN PAW DOGE",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.amber,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: themeProvider,
                builder: (context, child) => IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Colors.amber,
                    size: 20,
                  ),
                  tooltip: "Toggle Dark/Light Mode",
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServicePage(),
                  ),
                ),
                child: const Text(
                  "Terms of Service",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                ),
                child: const Text(
                  "Privacy Policy",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CookiePolicyPage(),
                  ),
                ),
                child: const Text(
                  "Cookie Policy",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FAQPage()),
                ),
                child: const Text(
                  "FAQ",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactPage()),
                ),
                child: const Text(
                  "Contact / Help Desk",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.discord, color: Colors.indigo),
                onPressed: () {
                  web.window.open('https://discord.com', '_blank');
                },
                tooltip: 'Join our Discord',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () {
                  web.window.open('https://twitter.com', '_blank');
                },
                tooltip: 'Follow us on X',
              ),
              IconButton(
                icon: const Icon(Icons.facebook, color: Colors.blue),
                onPressed: () {
                  web.window.open('https://facebook.com', '_blank');
                },
                tooltip: 'Follow us on Facebook',
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.pink),
                onPressed: () {
                  web.window.open('https://instagram.com', '_blank');
                },
                tooltip: 'Follow us on Instagram',
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = constraints.maxWidth > 300
                  ? 280.0
                  : constraints.maxWidth * 0.92;
              final fontSize = buttonWidth < 200 ? 12.0 : 13.0;
              return Center(
                child: SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDonateDialog(context),
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "SUPPORT THE PROJECT (DONATE)",
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.brown,
                      side: const BorderSide(color: Colors.brown, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Container(height: 1, width: 250, color: Colors.amber.shade700),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                "© 2026 Golden Paw. All rights reserved.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              SizedBox(height: 4),
              Text(
                "Made with ❤️ by Luke in England, UK",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ✨ PAGE WRAPPER: KEEPS FOOTER AT BOTTOM ✨
// ==========================================
class PageWithFooter extends StatelessWidget {
  final Widget child;
  const PageWithFooter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? null : Colors.white,
            gradient: isDark ? themeProvider.darkModeGradient : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SafeArea(
                bottom: true,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Keep the page content first. When the content is
                        // shorter than the viewport the footer will be pushed
                        // to the bottom by the ConstrainedBox minHeight.
                        child,
                        const AppFooter(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
