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


import 'src/theme_provider.dart';
import 'create_ad_page.dart';
import 'src/firebase_service.dart';
part 'src/app_widgets.dart';


// --- GLOBAL THEME CONSTANTS 🚀 ---
const kAppBarColor = Colors.black87; 
const kAppBarIconColor = Colors.amber; 
const kAppBarLogoColor = Colors.white; 
const kTextColorOnBlack = Colors.white;

// --- CAPTCHA JS BINDINGS ---
@JS('renderHCaptcha')
external void renderHCaptcha();

@JS('renderTurnstile')
external void renderTurnstile();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 REGISTER VIEWS (CAPTCHAS & TENOR GIF)
  try {
    // 1. hCaptcha
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'hcaptcha-widget',
      (int viewId) {
        final div = web.HTMLDivElement();
        div.id = 'hcaptcha-target';
        div.setAttribute('style', 'display: flex; justify-content: center; align-items: center; width: 100%; height: 100%; transform: scale(0.85); transform-origin: center center;');
        return div;
      },
    );

    // 2. Turnstile
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'turnstile-widget',
      (int viewId) {
        final div = web.HTMLDivElement();
        div.id = 'turnstile-target';
        div.setAttribute('style', 'display: flex; justify-content: center; align-items: center; width: 100%; height: 100%; transform: scale(0.85); transform-origin: center center;');
        return div;
      },
    );

    // 3. Tenor Dogecoin Animated GIF View (Original Embed + Hover Blocked!)
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'tenor-gif-view',
      (int viewId) {
        final iframe = web.HTMLIFrameElement();
        // pointer-events: none completely blocks the Tenor hover menu
        iframe.setAttribute('style', 'border: none; width: 100%; height: 100%; pointer-events: none;');
        
        iframe.setAttribute('srcdoc', '''
          <!DOCTYPE html>
          <html>
            <head>
              <style>
                body { margin: 0; display: flex; justify-content: center; align-items: center; overflow: hidden; background: transparent; }
                .tenor-gif-embed { width: 100% !important; max-width: 120px; pointer-events: none; }
              </style>
            </head>
            <body>
              <!-- YOUR EXACT ORIGINAL EMBED CODE -->
              <div class="tenor-gif-embed" data-postid="4351659229197618111" data-share-method="host" data-aspect-ratio="1" data-width="100%">
                <a href="https://tenor.com/view/dogecoin-logo-animation-dogecoin-logo-animation-crypto-gif-4351659229197618111">Dogecoin Logo GIF</a>
              </div>
              <script type="text/javascript" async src="https://tenor.com/embed.js"></script>
            </body>
          </html>
        ''');
        return iframe;
      },
    );
  } catch (e) {
    /* ignore if already registered */
  }
  
  await FirebaseService.initialize();

  runApp(
    ListenableBuilder(
      listenable: themeProvider,
      builder: (context, child) => MaterialApp(
        title: 'Golden Paw',
        home: const RootGatekeeper(),
        debugShowCheckedModeBanner: false,
        theme: themeProvider.lightTheme,
        darkTheme: themeProvider.darkTheme,
        themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      ),
    ),
  );
}
// ==========================================
// 1. THE SHELL 
// ==========================================
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  static final List<Widget> _pages = [const FaucetPage(), const StakingPage(), const AccountPage()];

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: kAppBarColor,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Faucet'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Staking'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

// ==========================================
// 2. THE FAUCET PAGE 
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
        final div = web.document.getElementById('gp-captcha-token') as web.HTMLElement?;
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
      } catch (e) { /* ignore */ }
    });

    web.EventStreamProviders.messageEvent.forTarget(web.window).listen((web.Event event) {
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
      } catch (e) { /* Ignore parsing errors */ }
    });
  }

  Future<void> _fetchDogePrice() async {
    try {
      final res = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=DOGEUSDT'));
      if (res.statusCode == 200 && mounted) setState(() => _currentDogePrice = double.parse(jsonDecode(res.body)['price']));
    } catch (e) { /* ignore */ }
  }

  double _getBaseReward(double price) {
    if (price <= 0.05) return 0.0008;
    if (price >= 0.50) return 0.0002;
    return 0.0008 - ((price - 0.05) / 0.45) * 0.0006;
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedAddress = prefs.getString('doge_address');
    if (savedAddress != null && savedAddress.isNotEmpty) {
      if (mounted) setState(() { _addressController.text = savedAddress; });
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
          int passed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms)).inSeconds;
          if (passed >= 0 && passed < 300) {
            if (mounted) setState(() { _secondsRemaining = 300 - passed; });
            _resumeTimer();
            return;
          } else {
            web.window.localStorage.removeItem('gp_lock_time');
          }
        }
      }
    } catch(e) {}
    if (mounted) setState(() => _isCheckingCooldown = false);
  }

  void _syncSaveLock() {
    try {
      web.window.localStorage.setItem('gp_lock_time', DateTime.now().millisecondsSinceEpoch.toString());
    } catch(e) {}
  }

  void _syncRemoveLock() {
    try {
      web.window.localStorage.removeItem('gp_lock_time');
    } catch(e) {}
    _countdownTimer?.cancel();
    if (mounted) setState(() { _secondsRemaining = 0; });
  }

  void _resumeTimer() {
    if (mounted) setState(() => _isCheckingCooldown = false); 
    _countdownTimer?.cancel();
    
    String? lock = web.window.localStorage.getItem('gp_lock_time');
    DateTime unlockTime;
    if (lock != null) {
      unlockTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lock)).add(const Duration(seconds: 300));
    } else {
      unlockTime = DateTime.now().add(Duration(seconds: _secondsRemaining));
    }

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) { timer.cancel(); return; }
      
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
              content: Text("Timer complete! 🐾 Please refresh the page to load your next Captcha."),
              duration: Duration(seconds: 8),
              backgroundColor: Colors.blue
            )
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
      } catch (e) { /* ignore */ }
    });
  }

  Future<void> _claimDoge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!_saveToVault && _addressController.text.isEmpty) {
      setState(() => _status = "Address Required!");
      return;
    }

    setState(() { _isLoading = true; _status = "Waking up server..."; });
    
    bool? proceedToClaim = await showDialog<bool>(
      context: context,
      barrierDismissible: false, 
      builder: (context) => const InterstitialAdDialog(),
    );

    if (proceedToClaim != true) {
      if (mounted) setState(() { _isLoading = false; _status = "Ready to Claim"; });
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
        String? token = await user.getIdToken(true);
        final response = await http.post(
          Uri.parse('https://golden-paw-vault.onrender.com/claim-vault'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"idToken": token}),
        ).timeout(const Duration(seconds: 60));
        
        if (!mounted) return;
        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          setState(() { _status = "${resData['message']} (+10 XP!)"; _isLoading = false; });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.star, color: Colors.white), 
                  SizedBox(width: 10), 
                  Text("+10 XP Earned! 🚀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ],
              ),
              backgroundColor: Colors.purple.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
              duration: const Duration(seconds: 4),
            )
          );

        } else {
          _syncRemoveLock(); 
          setState(() { _status = "Error claiming to Vault."; _isLoading = false; });
        }
      } else {
        final response = await http.post(
          Uri.parse('https://golden-paw-vault.onrender.com/send-doge'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_address": _addressController.text.trim(), "captcha_token": _captchaToken, "captcha_provider": _selectedCaptcha}),
        ).timeout(const Duration(seconds: 60));
        
        if (!mounted) return;
        if (response.statusCode == 200) {
          setState(() { _status = "Claim Sent to FaucetPay! 🚀 (+10 XP!)"; _isLoading = false; });
        } else {
          _syncRemoveLock(); 
          final errorData = jsonDecode(response.body);
          setState(() { _status = "Declined: ${errorData['error']}"; _captchaToken = null; _captchaLoading = false; _isLoading = false; });
        }
      }
    } catch (e) {
      _syncRemoveLock(); 
      if (mounted) setState(() { _status = "Server timeout. Trying to wake Render... try again in 10s."; _captchaLoading = false; _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _captchaPoller?.cancel(); 
    super.dispose();
  }

  void _openFaucetPayLink() { web.window.open('https://faucetpay.io/?r=5173106', '_blank'); }

  String _getClaimButtonText() {
    if (_isCheckingCooldown) return "LOADING...";
    if (_secondsRemaining > 0) return "WAIT: ${_secondsRemaining}s";
    if (_captchaToken == null) return "SOLVE CAPTCHA";
    if (_isLoading) return "SENDING...";
    return _saveToVault ? "CLAIM TO VAULT" : "CLAIM DOGE";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(), 
      appBar: const GlobalAppBar(),
      body: PageWithFooter(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: MediaQuery.of(context).textScaleFactor * 1.2),
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
                  return Card(
                    elevation: 0, 
                    color: isDark ? themeProvider.darkGreyBoxColor : Colors.amber[50], 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), 
                      side: BorderSide(color: isDark ? themeProvider.darkGreyBorder : Colors.amber.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, 
                    children: [
                      Text(
                        "Welcome to the Golden Paw Faucet! 🌟", 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "We make earning crypto simple. Whether you are here to grab some quick Dogecoin or want to build a long-term balance, you are in the right place.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center, 
                        children: [
                          Text(
                            "•  Enter your Dogecoin address below and claim your free Doge instantly to FaucetPay.", 
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                          ),
                          const SizedBox(height: 16), 
                          Text(
                            "• Optionally toggle the switch to Hold it and move it to the Staking pool to earn passive rewards.", 
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                          ),
                          const SizedBox(height: 16), 
                          Wrap(
                            alignment: WrapAlignment.center, 
                            runSpacing: 4,
                            children: [
                              Text("•  Withdraw directly to ", style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87), textAlign: TextAlign.center),
                              InkWell(
                                onTap: _openFaucetPayLink, 
                                child: const Text("FaucetPay", style: TextStyle(fontSize: 14, color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                              ),
                              Text(" whenever you are ready.", style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87), textAlign: TextAlign.center),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
                }
              ),
              
              const SizedBox(height: 25),

              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user != null) {
                    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                      builder: (context, dbSnapshot) {
                        int xp = 0; int streak = 0;
                        if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                          final data = dbSnapshot.data!.data();
                          xp = (data?['xp'] ?? 0).toInt(); 
                          streak = (data?['streak_count'] ?? 0).toInt();
                        }
                        int level = sqrt(xp / 100).floor(); if (level > 100) level = 100;
                        int levelBonus = level; int streakBonus = streak; int totalBonusPercent = levelBonus + streakBonus;
                        double baseReward = _getBaseReward(_currentDogePrice); 
                        double expectedReward = baseReward * (1 + (totalBonusPercent / 100));

                        return ListenableBuilder(
                          listenable: themeProvider,
                          builder: (context, _) {
                            final isDark = themeProvider.isDarkMode;
                            return Container(
                              padding: const EdgeInsets.all(12), 
                              decoration: BoxDecoration(
                                color: isDark ? themeProvider.darkGreyBoxColor : Colors.green.shade100, 
                                borderRadius: BorderRadius.circular(10),
                                border: isDark ? Border.all(color: themeProvider.darkGreyBorder, width: 1) : null,
                              ),
                              child: Column(children: [
                                Text("Current Vault Reward: +${expectedReward.toStringAsFixed(6)} DOGE  &  +10 XP", style: TextStyle(color: isDark ? Colors.amber.shade300 : Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 5),
                                Text("Base: ${baseReward.toStringAsFixed(6)}  |  Lvl Bonus: +$levelBonus%  |  Streak Bonus: +$streakBonus%", style: TextStyle(color: isDark ? Colors.amber.shade200 : Colors.green.shade800, fontSize: 13)),
                                const SizedBox(height: 8),
                                Divider(color: isDark ? Colors.amber.withOpacity(0.5) : Colors.green, height: 2),
                                const SizedBox(height: 8),
                                Text("Earn 10 XP per claim to level up and boost your daily multipliers!", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : Colors.green.shade900, fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Text("Your base reward scales dynamically against the USD value of DOGE. The cheaper DOGE gets, the more you earn!", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white60 : Colors.green.shade800, fontSize: 13, fontStyle: FontStyle.italic)),
                              ]),
                            );
                          }
                        );
                      }
                    );
                  } else {
                    return ListenableBuilder(
                      listenable: themeProvider,
                      builder: (context, _) {
                        final isDark = themeProvider.isDarkMode;
                        return Container(
                          padding: const EdgeInsets.all(12), 
                          decoration: BoxDecoration(
                            color: isDark ? themeProvider.darkGreyBoxColor : Colors.green.shade100, 
                            borderRadius: BorderRadius.circular(10),
                            border: isDark ? Border.all(color: themeProvider.darkGreyBorder, width: 1) : null,
                          ),
                          child: Column(children: [
                            Text("Current Base Reward: ${_getBaseReward(_currentDogePrice).toStringAsFixed(6)} DOGE\n(Log in to unlock XP & Multipliers!)", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.amber.shade300 : Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 5),
                            Text("Rewards scale dynamically. If the USD value of DOGE drops, you earn more DOGE!", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : Colors.green.shade900, fontSize: 13, fontStyle: FontStyle.italic)),
                          ]),
                        );
                      }
                    );
                  }
                }
              ),
              
              const SizedBox(height: 25),

              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(color: _saveToVault ? Colors.green.shade50 : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _saveToVault ? Colors.green.shade300 : Colors.amber.shade300, width: 2)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(_saveToVault ? Icons.account_balance : Icons.account_balance_wallet, color: _saveToVault ? Colors.green : Colors.amber), 
                                const SizedBox(width: 10), 
                                Text(_saveToVault ? "Routing to Vault" : "Send to FaucetPay", style: TextStyle(fontWeight: FontWeight.bold, color: _saveToVault ? Colors.green.shade800 : Colors.brown))
                              ],
                            ),
                            Switch(
                              value: _saveToVault, 
                              activeThumbColor: Colors.green, 
                              inactiveThumbColor: Colors.amber, 
                              onChanged: _secondsRemaining > 0 ? null : (bool value) { setState(() { _saveToVault = value; }); }
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const Padding(padding: EdgeInsets.only(bottom: 15), child: Text("Create an account to unlock Vault saving & XP! 🏦", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)));
                  }
                }
              ),
              
              const SizedBox(height: 10),
              if (!_saveToVault)
                PointerInterceptor(
                  child: TextField(
                    controller: _addressController, 
                    enabled: _secondsRemaining == 0, 
                    onChanged: (value) => _saveAddress(value), 
                    decoration: InputDecoration(labelText: 'FaucetPay Dogecoin Address', prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.amber), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
                  ),
                ),
              
              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, color: Colors.brown, size: 20), 
                  const SizedBox(width: 8), 
                  const Text("Security:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)), 
                  const SizedBox(width: 10),
                  ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, _) {
                      final isDark = themeProvider.isDarkMode;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), 
                        decoration: BoxDecoration(
                          color: isDark ? themeProvider.darkGreyBoxColor : Colors.amber.shade50, 
                          borderRadius: BorderRadius.circular(8), 
                          border: Border.all(color: isDark ? themeProvider.darkGreyBorder : Colors.amber.shade200)
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCaptcha, 
                          icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.amber : Colors.brown), 
                          elevation: 16, 
                          style: TextStyle(color: isDark ? Colors.amber : Colors.brown, fontWeight: FontWeight.bold), 
                          underline: Container(), 
                          onChanged: _secondsRemaining > 0 ? null : (String? value) { setState(() { _selectedCaptcha = value!; _captchaToken = null; _captchaLoading = false; _status = "Ready to Claim"; }); },
                          items: const [
                            DropdownMenuItem(value: 'hCaptcha', child: Text('hCaptcha')), 
                            DropdownMenuItem(value: 'Turnstile', child: Text('Turnstile'))
                          ],
                        ),
                      );
                    }
                  ),
                ],
              ),
              
              const SizedBox(height: 15),
              Container(
                height: 120, 
                width: 340, 
                decoration: BoxDecoration(border: Border.all(color: Colors.amber, width: 2), borderRadius: BorderRadius.circular(12), color: Colors.white),
                child: PointerInterceptor(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isCheckingCooldown) 
                        const Center(child: Text("Checking Vault Status...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                      else if (_selectedCaptcha == 'hCaptcha' && _secondsRemaining == 0) 
                        const SizedBox(width: 320, height: 90, child: HtmlElementView(viewType: 'hcaptcha-widget'))
                      else if (_selectedCaptcha == 'Turnstile' && _secondsRemaining == 0) 
                        const SizedBox(width: 320, height: 90, child: HtmlElementView(viewType: 'turnstile-widget')),
                      
                      if (!_isCheckingCooldown && !_captchaLoading && _secondsRemaining == 0) 
                        ElevatedButton(onPressed: _forceRenderCaptcha, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, elevation: 0), child: const Text("Tap to Load Captcha", style: TextStyle(color: Colors.brown))),
                      if (!_isCheckingCooldown && _secondsRemaining > 0) 
                        Container(color: Colors.white, child: const Center(child: Text("Wait for timer...", style: TextStyle(color: Colors.grey))))
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
                    width: 160, height: 60, 
                    child: ElevatedButton(
                      onPressed: (_isCheckingCooldown || _captchaToken == null || _isLoading || _secondsRemaining > 0) ? null : _claimDoge,
                      style: ElevatedButton.styleFrom(backgroundColor: _secondsRemaining > 0 || _captchaToken == null ? Colors.grey : (_saveToVault ? Colors.green : Colors.amber), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_getClaimButtonText(), textAlign: TextAlign.center, style: TextStyle(color: _saveToVault && _captchaToken != null ? Colors.white : Colors.brown, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SquareAdPlaceholder(slotId: 'square_right'),
                ],
              ),
              
              const SizedBox(height: 20),
              Text(_status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _saveToVault ? Colors.green : Colors.brown)),
              
              const SizedBox(height: 40),

              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, authSnapshot) {
                  final user = authSnapshot.data;
                  if (user == null) return const SizedBox.shrink();

                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                    builder: (context, dbSnapshot) {
                      bool canClaimBonus = true;
                      int minutesLeft = 0;

                      if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                        final userData = dbSnapshot.data!.data();
                        final Timestamp? lastClaim = userData?['last_bonus_sponsor_claim'];
                        
                        if (lastClaim != null) {
                          final now = DateTime.now();
                          final difference = now.difference(lastClaim.toDate());
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
                              color: isDark ? themeProvider.darkGreyBoxColor : (canClaimBonus ? Colors.amber.shade100 : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isDark ? themeProvider.darkGreyBorder : (canClaimBonus ? Colors.amber.shade400 : Colors.grey.shade400), 
                                width: 2
                              ),
                            ),
                            child: Column(
                              children: [
                                Text("🌟 Support Golden Paw & Boost the Faucet 🌟", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown, fontSize: 16)),
                                const SizedBox(height: 5),
                                const Text("Stay on the page for 30 seconds to earn\n0.003 DOGE & 30 XP!", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canClaimBonus ? Colors.amber : Colors.grey,
                                      foregroundColor: canClaimBonus ? Colors.brown.shade900 : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: Icon(canClaimBonus ? Icons.card_giftcard : Icons.lock_clock),
                                    label: Text(
                                      canClaimBonus ? 'VIEW BONUS SPONSORS' : 'COOLDOWN: $minutesLeft MIN',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.1),
                                    ),
                                    onPressed: canClaimBonus ? () {
                                      web.window.open('/sponsors.html', '_blank');
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) => const BonusTimerDialog(),
                                      );
                                    } : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
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
class StakingPage extends StatefulWidget {
  const StakingPage({super.key});
  @override
  State<StakingPage> createState() => _StakingPageState();
}

class _StakingPageState extends State<StakingPage> {
  final TextEditingController _amountController = TextEditingController();

  Future<void> _harvestInterest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("User not found!");

        final data = snapshot.data();
        double currentBalance = (data?['doge_balance'] ?? 0.0).toDouble();
        double currentStaked = (data?['staked_balance'] ?? 0.0).toDouble();
        Timestamp? stakeTime = data?['stake_timestamp'] as Timestamp?;

        double pendingInterest = 0.0;
        if (currentStaked > 0 && stakeTime != null) {
          int secondsPassed = DateTime.now().difference(stakeTime.toDate()).inSeconds;
          if (secondsPassed > 0) {
            pendingInterest = currentStaked * (0.085 / 31536000) * secondsPassed;
          }
        }

        if (pendingInterest <= 0) throw Exception("No interest to harvest yet!");

        transaction.update(docRef, {
          'doge_balance': currentBalance + pendingInterest,
          'stake_timestamp': FieldValue.serverTimestamp(), 
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully Harvested Interest! 🌾", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.orange));
    }
  }

  Future<void> _stakeDoge(double amountToStake) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("User not found!");

        final data = snapshot.data();
        double currentBalance = (data?['doge_balance'] ?? 0.0).toDouble();
        double currentStaked = (data?['staked_balance'] ?? 0.0).toDouble();
        Timestamp? stakeTime = data?['stake_timestamp'] as Timestamp?;

        double pendingInterest = 0.0;
        if (currentStaked > 0 && stakeTime != null) {
          int secondsPassed = DateTime.now().difference(stakeTime.toDate()).inSeconds;
          if (secondsPassed > 0) pendingInterest = currentStaked * (0.085 / 31536000) * secondsPassed;
        }

        currentBalance += pendingInterest;

        if (currentBalance >= amountToStake && amountToStake > 0) {
          transaction.update(docRef, {
            'doge_balance': currentBalance - amountToStake,
            'staked_balance': currentStaked + amountToStake,
            'stake_timestamp': FieldValue.serverTimestamp(), 
          });
        } else {
          throw Exception("Not enough Doge in your Stakable Balance!");
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully staked $amountToStake DOGE! 🐾", style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
      _amountController.clear(); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vault Error: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
    }
  }

  Future<void> _unstakeDoge(double amountToUnstake) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("User not found!");

        final data = snapshot.data();
        double currentBalance = (data?['doge_balance'] ?? 0.0).toDouble();
        double currentStaked = (data?['staked_balance'] ?? 0.0).toDouble();
        Timestamp? stakeTime = data?['stake_timestamp'] as Timestamp?;

        double pendingInterest = 0.0;
        if (currentStaked > 0 && stakeTime != null) {
          int secondsPassed = DateTime.now().difference(stakeTime.toDate()).inSeconds;
          if (secondsPassed > 0) pendingInterest = currentStaked * (0.085 / 31536000) * secondsPassed;
        }

        currentBalance += pendingInterest;

        if (currentStaked >= amountToUnstake && amountToUnstake > 0) {
          transaction.update(docRef, {
            'doge_balance': currentBalance + amountToUnstake,
            'staked_balance': currentStaked - amountToUnstake,
            'stake_timestamp': FieldValue.serverTimestamp(), 
          });
        } else {
          throw Exception("Not enough Staked Doge to unstake!");
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully unstaked $amountToUnstake DOGE! 🔓", style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.blue));
      _amountController.clear(); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vault Error: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(), 
      appBar: const GlobalAppBar(),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final User? user = authSnapshot.data;

          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text("You must log in to access The Vault.", style: TextStyle(fontSize: 18, color: Colors.brown, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
              if (dbSnapshot.hasError) return const Center(child: Text("Error connecting to Vault. Check your connection.", style: TextStyle(color: Colors.red)));
              
              if (!dbSnapshot.hasData || !dbSnapshot.data!.exists) {
                FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'email': user.email,
                  'doge_balance': 0.0,
                  'staked_balance': 0.0,
                  'ads_balance': 0.0,
                  'offerwall_balance': 0.0,
                  'pending_offer_balance': 0.0,
                  'xp': 0,
                  'streak_count': 0,
                  'joined_date': DateTime.now().toIso8601String(),
                }, SetOptions(merge: true));
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              final userData = dbSnapshot.data!.data() as Map<String, dynamic>?;
              double dogeBalance = (userData?['doge_balance'] ?? 0.0).toDouble();
              double stakedBalance = (userData?['staked_balance'] ?? 0.0).toDouble();
              Timestamp? stakeTimestamp = userData?['stake_timestamp'] as Timestamp?;

              return PageWithFooter(
                // 👑 Wrapped the main padding layout in ListenableBuilder
                child: ListenableBuilder(
                  listenable: themeProvider,
                  builder: (context, _) {
                    final isDark = themeProvider.isDarkMode;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏦', style: TextStyle(fontSize: 80)),
                          const SizedBox(height: 15),
                          Text("Earn 8.5% APY on your DOGE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown)),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                            decoration: BoxDecoration(color: isDark ? themeProvider.darkGreyBoxColor : Colors.green.shade100, borderRadius: BorderRadius.circular(20), border: isDark ? Border.all(color: themeProvider.darkGreyBorder, width: 1) : null), 
                            child: Row(
                              mainAxisSize: MainAxisSize.min, 
                              children: [
                                Icon(Icons.update, size: 20, color: isDark ? Colors.amber : Colors.green.shade800), 
                                const SizedBox(width: 5), 
                                Text("Interest paid every second", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.amber : Colors.green.shade800))
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Colors.amber.shade700, size: 18), 
                                  const SizedBox(width: 8), 
                                  Text(
                                    "Available Stakable Balance", 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 👑 THEMED BALANCE BOX
                          Container(
                            width: double.infinity, 
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20), 
                            decoration: BoxDecoration(
                              color: isDark ? themeProvider.darkGreyBoxColor : Colors.white, 
                              borderRadius: BorderRadius.circular(15), 
                              border: Border.all(color: isDark ? themeProvider.darkGreyBorder : Colors.amber.shade300, width: 2)
                            ), 
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${dogeBalance.toStringAsFixed(8)} DOGE", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isDark ? Colors.amber : Colors.brown),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "⚠️ Note: Offerwall rewards cannot be staked.",
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // 👑 THEMED HARVEST BOX
                          Container(
                            width: double.infinity, 
                            padding: const EdgeInsets.all(25), 
                            decoration: BoxDecoration(
                              color: isDark ? themeProvider.darkGreyBoxColor : null,
                              gradient: isDark ? null : LinearGradient(colors: [Colors.amber.shade300, Colors.amber.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight), 
                              borderRadius: BorderRadius.circular(20), 
                              border: isDark ? Border.all(color: themeProvider.darkGreyBorder, width: 2) : null,
                              boxShadow: isDark ? null : const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]
                            ),
                            child: Column(
                              children: [
                                Text("Total Staked (Principal)", style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.brown, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                LiveInterestDisplay(stakedBalance: stakedBalance, stakeTimestamp: stakeTimestamp),
                                const SizedBox(height: 8),
                                Text("💡 The more you stake, the faster your yield ticks up!", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.brown, fontStyle: FontStyle.italic)),
                                const SizedBox(height: 15),
                                SizedBox(
                                  height: 35, 
                                  child: ElevatedButton.icon(
                                    onPressed: stakedBalance > 0 ? _harvestInterest : null, 
                                    icon: const Icon(Icons.agriculture, color: Colors.white, size: 16), 
                                    label: const Text("HARVEST REWARDS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), 
                                    style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.green.shade700 : Colors.orange.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 30),

                          TextField(
                            controller: _amountController, 
                            keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Principal Amount to Stake / Unstake', 
                              labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
                              prefixIcon: const Icon(Icons.monetization_on, color: Colors.amber), 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                              enabledBorder: isDark ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)) : null,
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.amber, width: 2))
                            )
                          ),
                          const SizedBox(height: 25),

                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 50, 
                                  child: ElevatedButton.icon(
                                    onPressed: () { 
                                      double amount = double.tryParse(_amountController.text.trim()) ?? 0.0; 
                                      if (amount > 0) {
                                        _stakeDoge(amount);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount to stake.")));
                                      } 
                                    }, 
                                    icon: const Icon(Icons.lock, color: Colors.white, size: 18), 
                                    label: const Text("STAKE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), 
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: SizedBox(
                                  height: 50, 
                                  child: ElevatedButton.icon(
                                    onPressed: () { 
                                      double amount = double.tryParse(_amountController.text.trim()) ?? 0.0; 
                                      if (amount > 0) {
                                        _unstakeDoge(amount);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount to unstake.")));
                                      } 
                                    }, 
                                    icon: Icon(Icons.lock_open, color: isDark ? Colors.brown.shade900 : Colors.brown, size: 18), 
                                    label: Text("UNSTAKE", style: TextStyle(color: isDark ? Colors.brown.shade900 : Colors.brown, fontWeight: FontWeight.bold, fontSize: 16)), 
                                    style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.amber : Colors.amber.shade100, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
              );
            }
          );
        }
      ),
    );
  }
}

class LiveInterestDisplay extends StatefulWidget {
  final double stakedBalance;
  final Timestamp? stakeTimestamp;
  const LiveInterestDisplay({super.key, required this.stakedBalance, this.stakeTimestamp});
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
    if (oldWidget.stakedBalance != widget.stakedBalance || oldWidget.stakeTimestamp != widget.stakeTimestamp) _calculateInterest();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) { _calculateInterest(); });
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
      setState(() { _liveInterest = widget.stakedBalance * interestPerSecond * secondsPassed; });
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
                child: Text(widget.stakedBalance.toStringAsFixed(8), style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown)),
              ),
            ),
            Text("DOGE", style: TextStyle(fontSize: 16, color: isDark ? Colors.amber : Colors.brown, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.white.withAlpha(102), borderRadius: BorderRadius.circular(10)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("+ ${_liveInterest.toStringAsFixed(10)} Pending Yield", style: TextStyle(fontSize: 13, color: isDark ? Colors.greenAccent : Colors.brown, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      }
    );
  }
}

// ==========================================
// 4. THE ACCOUNT PAGE 
// ==========================================
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _withdrawAddressController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController();
  bool _isWithdrawing = false;
  String _withdrawMessage = "";
  final bool _twoFactorEnabled = false; 

  @override
  void initState() {
    super.initState();
    _loadSavedInfo();
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedAddress = prefs.getString('doge_address');
    if (savedAddress != null) {
      setState(() { _withdrawAddressController.text = savedAddress; });
    }
  }

  Future<void> _processWithdrawal(double maxBalance) async {
    double? amountToWithdraw = double.tryParse(_withdrawAmountController.text.trim());
    if (amountToWithdraw == null) { setState(() => _withdrawMessage = "Please enter a valid number."); return; }
    if (amountToWithdraw < 0.001) { setState(() => _withdrawMessage = "Minimum withdrawal is 0.001 DOGE."); return; }
    if (amountToWithdraw > maxBalance) { setState(() => _withdrawMessage = "Insufficient Vault Balance."); return; }
    if (_withdrawAddressController.text.trim().isEmpty) { setState(() => _withdrawMessage = "Please enter a FaucetPay Dogecoin address."); return; }

    setState(() { _isWithdrawing = true; _withdrawMessage = "Processing withdrawal..."; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? idToken = await user.getIdToken(); 
        
        final response = await http.post(
          Uri.parse('https://golden-paw-vault.onrender.com/withdraw'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"idToken": idToken, "user_address": _withdrawAddressController.text.trim(), "amount": amountToWithdraw}),
        );

        if (!mounted) return;
        if (response.statusCode == 200) {
          setState(() { _withdrawMessage = "Success! $amountToWithdraw DOGE sent to FaucetPay."; _withdrawAmountController.clear(); });
        } else {
          try {
            final errorData = jsonDecode(response.body);
            setState(() { _withdrawMessage = "Declined: ${errorData['error'] ?? 'Unknown error'}"; });
          } catch (_) {
            setState(() { _withdrawMessage = "Server Error ${response.statusCode}: The server is still updating. Try again in a few mins!"; });
          }
        }
      }
    } catch (e) {
      setState(() => _withdrawMessage = "Bug: $e");
    } finally {
      setState(() => _isWithdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(), 
      appBar: const GlobalAppBar(),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final User? user = authSnapshot.data;
          return PageWithFooter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 70, backgroundColor: Colors.amber.shade100, child: const Icon(Icons.pets, size: 70, color: Colors.brown)),
                  const SizedBox(height: 20),
                  
                  if (user == null) ...[
                    const Text("Not Logged In", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown)),
                    const SizedBox(height: 10),
                    const Text("Create a Golden Paw account to unlock the full ecosystem.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 30),
                    ListenableBuilder(
                      listenable: themeProvider,
                      builder: (context, _) {
                        final isDark = themeProvider.isDarkMode;
                        return Card(
                          elevation: 0, 
                          color: isDark ? Colors.grey.shade900 : Colors.amber.shade50, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.amber.shade200)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 28), 
                                  title: Text("Save Your Doge", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown, fontSize: 16)), 
                                  subtitle: Text("Store claims internally instead of instantly sending to FaucetPay.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87))
                                ),
                                ListTile(
                                  leading: const Icon(Icons.bolt, color: Colors.amber, size: 28), 
                                  title: Text("Earn Staking Rewards", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown, fontSize: 16)), 
                                  subtitle: Text("Lock your saved Doge in the Vault to earn daily interest.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87))
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity, 
                      height: 50, 
                      child: ElevatedButton(
                        onPressed: () => showAuthDialogGlobal(context, true), 
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), 
                        child: const Text("LOG IN", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 16))
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity, 
                      height: 50, 
                      child: OutlinedButton(
                        onPressed: () => showAuthDialogGlobal(context, false), 
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.amber.shade700, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), 
                        child: Text("CREATE ACCOUNT", style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 16))
                      ),
                    ),
                  ] 
                  else ...[
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                      builder: (context, dbSnapshot) {
                        double currentBalance = 0.0;
                        if (dbSnapshot.hasData && dbSnapshot.data!.exists) {
                          var userData = dbSnapshot.data!.data() as Map<String, dynamic>?;
                          currentBalance = (userData?['doge_balance'] ?? 0.0).toDouble();
                        }

                        return Column(
                          children: [
                            const Text("Welcome back!", style: TextStyle(fontSize: 16, color: Colors.grey)),
                            Text(user.email ?? "Unknown Doge", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                            const SizedBox(height: 20),
                            
                            ListenableBuilder(
                              listenable: themeProvider,
                              builder: (context, _) {
                                final isDark = themeProvider.isDarkMode;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), 
                                  decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.security, color: Colors.green),
                                    title: Text("Two-Factor Auth (2FA)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                                    subtitle: Text("Protect your Vault balance", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                                    trailing: Switch(
                                      value: _twoFactorEnabled,
                                      activeThumbColor: Colors.green,
                                      onChanged: (val) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("2FA Setup coming soon!")));
                                      },
                                    ),
                                  ),
                                );
                              }
                            ),
                            
                            const SizedBox(height: 30),
                            ListenableBuilder(
                              listenable: themeProvider,
                              builder: (context, _) {
                                final isDark = themeProvider.isDarkMode;
                                return Card(
                                  elevation: 2, 
                                  color: isDark ? Colors.grey.shade900 : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.amber.shade300, width: 1)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.outbound, color: isDark ? Colors.amber : Colors.brown), 
                                            const SizedBox(width: 10), 
                                            Text("Withdraw to FaucetPay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown))
                                          ]
                                        ),
                                        Divider(height: 20, color: isDark ? Colors.amber.withOpacity(0.3) : Colors.grey),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                          children: [
                                            Text("Available to Withdraw:", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontWeight: FontWeight.bold)), 
                                            Text("${currentBalance.toStringAsFixed(8)} DOGE", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.amber : Colors.green))
                                          ]
                                        ),
                                        const SizedBox(height: 5),
                                        Text("Minimum Withdrawal: 0.001 DOGE", style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54, fontStyle: FontStyle.italic)),
                                        const SizedBox(height: 20),
                                        TextField(
                                          controller: _withdrawAddressController,
                                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                          onChanged: (value) async {
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.setString('doge_address', value.trim());
                                          },
                                          decoration: InputDecoration(
                                            labelText: "FaucetPay Dogecoin Address", 
                                            labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                                            prefixIcon: const Icon(Icons.account_balance_wallet, size: 20), 
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), 
                                            contentPadding: const EdgeInsets.symmetric(vertical: 0)
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        TextField(
                                          controller: _withdrawAmountController, 
                                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                                          decoration: InputDecoration(
                                            labelText: "Amount (DOGE)", 
                                            labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                                            prefixIcon: const Icon(Icons.monetization_on, size: 20), 
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), 
                                            contentPadding: const EdgeInsets.symmetric(vertical: 0)
                                          )
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity, 
                                          height: 45, 
                                          child: ElevatedButton(
                                            onPressed: _isWithdrawing ? null : () => _processWithdrawal(currentBalance), 
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                                            child: _isWithdrawing 
                                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                              : const Text("WITHDRAW NOW", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        if (_withdrawMessage.isNotEmpty) ...[
                                          const SizedBox(height: 15), 
                                          Center(
                                            child: Text(_withdrawMessage, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _withdrawMessage.contains("Success") ? Colors.green : Colors.red)),
                                          )
                                        ]
                                      ],
                                    ),
                                  ),
                                );
                              }
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity, 
                              height: 50, 
                              child: OutlinedButton.icon(
                                onPressed: () async { await FirebaseAuth.instance.signOut(); }, 
                                icon: const Icon(Icons.logout, color: Colors.red), 
                                label: const Text("LOG OUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)), 
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)))
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ],
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

// ==========================================
// 🌟 THE AD HUB & DEPOSIT PAGE 🌟
// ==========================================
class AdHubPage extends StatefulWidget {
  const AdHubPage({super.key});

  @override
  State<AdHubPage> createState() => _AdHubPageState();
}

class _AdHubPageState extends State<AdHubPage> {
  final TextEditingController _depositAmountController = TextEditingController();
  final TextEditingController _swapAmountController = TextEditingController();
  bool _isSwapping = false;

  web.HTMLInputElement _createHiddenInput(String name, String value) {
    final input = web.HTMLInputElement();
    input.setAttribute('type', 'hidden');
    input.setAttribute('name', name);
    input.setAttribute('value', value);
    return input;
  }

  Future<void> _swapDogeToUsdt() async {
    final user = FirebaseAuth.instance.currentUser;
    double? amount = double.tryParse(_swapAmountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isSwapping = true);

    try {
      String? idToken = await user?.getIdToken();

      final response = await http.post(
        Uri.parse('https://golden-paw-vault.onrender.com/swap-doge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken, 'amount': amount}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Swap Successful! 💸", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        _swapAmountController.clear();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${error['error']}")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Swap failed. Server busy!")));
    } finally {
      if (mounted) setState(() => _isSwapping = false);
    }
  }

  void _showDepositDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dContext) {
        return AlertDialog(
          title: const Text("Deposit USDT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the amount of Tether (USDT) you want to deposit.", style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 15),
              TextField(
                controller: _depositAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Amount (USDT)", prefixIcon: Icon(Icons.attach_money, color: Colors.green), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dContext), 
              child: const Text("Cancel", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                String amount = _depositAmountController.text.trim();
                
                if (user != null && amount.isNotEmpty) {
                  final htmlForm = web.HTMLFormElement()
                    ..method = 'POST'
                    ..action = 'https://faucetpay.io/merchant/webscr' 
                    ..target = '_blank';

                  htmlForm.append(_createHiddenInput('merchant_username', 'ludogx1'));
                  htmlForm.append(_createHiddenInput('item_description', 'Golden Paw Ad Balance'));
                  htmlForm.append(_createHiddenInput('amount1', amount));
                  htmlForm.append(_createHiddenInput('currency1', 'USDT'));
                  htmlForm.append(_createHiddenInput('custom', user.uid)); 
                  htmlForm.append(_createHiddenInput('callback_url', 'https://golden-paw-vault.onrender.com/ipn'));

                  web.document.body!.append(htmlForm);
                  htmlForm.submit();
                  htmlForm.remove();
                  
                  if (dContext.mounted) Navigator.pop(dContext);
                }
              },
              child: const Text("PAY WITH FAUCETPAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      }
    );
  }

  void _buyAd(double currentAdsBalance, String docId, String title, double defaultCost) {
    final imgCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (BuildContext dContext) => StatefulBuilder(
        builder: (dContext, setDialogState) => AlertDialog(
          title: Text("Buy $title", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Cost: \$${defaultCost.toStringAsFixed(2)} USDT", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: "Image URL")),
              const SizedBox(height: 10),
              TextField(controller: targetCtrl, decoration: const InputDecoration(labelText: "Target Link (URL)")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dContext), 
              child: const Text("Cancel")
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: loading ? null : () async {
                if (currentAdsBalance < defaultCost) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Insufficient Ad Balance! Need \$${defaultCost.toStringAsFixed(2)}"), backgroundColor: Colors.red));
                  return;
                }
                if (targetCtrl.text.isEmpty || imgCtrl.text.isEmpty) return;

                setDialogState(() => loading = true);
                final user = FirebaseAuth.instance.currentUser!;
                
                try {
                  String? idToken = await user.getIdToken();
                  
                  final response = await http.post(
                    Uri.parse('https://golden-paw-vault.onrender.com/buy-banner'), 
                    headers: {'Content-Type': 'application/json'}, 
                    body: jsonEncode({'idToken': idToken, 'doc_id': docId, 'image_url': imgCtrl.text.trim(), 'target_url': targetCtrl.text.trim()})
                  );

                  if (!mounted) return;

                  if (response.statusCode == 200) {
                    if (dContext.mounted) Navigator.pop(dContext);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ad Campaign Successfully Launched! 🚀"), backgroundColor: Colors.green));
                  } else {
                    throw "Server returned error";
                  }
                } catch (e) {
                  setDialogState(() => loading = false);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: Text(loading ? "Processing..." : "PURCHASE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        )
      )
    );
  }

  void _buyPtcAd(double currentAdsBalance) {
    final targetCtrl = TextEditingController();
    bool loading = false;
    int selectedTier = 1;
    int selectedClicks = 100;

    Map<int, double> costs = {1: 0.50, 2: 1.00, 3: 1.50, 4: 3.00};
    Map<int, String> labels = {1: "10 Seconds", 2: "20 Seconds", 3: "30 Seconds", 4: "60 Seconds"};
    List<int> clickOptions = [100, 200, 300, 500, 1000];

    showDialog(
      context: context,
      builder: (BuildContext dContext) => StatefulBuilder(
        builder: (dContext, setDialogState) {
          double totalCost = costs[selectedTier]! * (selectedClicks / 100);

          return AlertDialog(
            title: const Text("Buy Guaranteed PTC Clicks", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Total Cost: \$${totalCost.toStringAsFixed(2)} USDT", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  initialValue: selectedTier,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Select View Duration"),
                  items: [1, 2, 3, 4].map((t) => DropdownMenuItem(value: t, child: Text("${labels[t]} (+\$${costs[t]!.toStringAsFixed(2)} per 100)", style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedTier = val);
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  initialValue: selectedClicks,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Number of Clicks"),
                  items: clickOptions.map((c) => DropdownMenuItem(value: c, child: Text("$c Guaranteed Views", style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedClicks = val);
                  },
                ),
                const SizedBox(height: 15),
                TextField(controller: targetCtrl, decoration: const InputDecoration(labelText: "Target Link (URL)", border: OutlineInputBorder())),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dContext), 
                child: const Text("Cancel")
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: loading ? null : () async {
                  if (currentAdsBalance < totalCost) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Insufficient Balance! Need \$${totalCost.toStringAsFixed(2)}"), backgroundColor: Colors.red));
                    return;
                  }
                  if (targetCtrl.text.isEmpty) return;

                  setDialogState(() => loading = true);
                  final user = FirebaseAuth.instance.currentUser!;
                  
                  try {
                    final idToken = await user.getIdToken();
                    final response = await http.post(
                      Uri.parse('https://golden-paw-vault.onrender.com/buy-ptc'), 
                      headers: {'Content-Type': 'application/json'}, 
                      body: jsonEncode({'idToken': idToken, 'target_url': targetCtrl.text.trim(), 'tier': selectedTier, 'clicks': selectedClicks})
                    );

                    if (!mounted) return;

                    if (response.statusCode == 200) {
                      if (dContext.mounted) Navigator.pop(dContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PTC Ad added to pool! 🚀"), backgroundColor: Colors.green));
                    } else {
                      final err = jsonDecode(response.body);
                      throw err['error'];
                    }
                  } catch (e) {
                    setDialogState(() => loading = false);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: Text(loading ? "Processing..." : "PAY \$${totalCost.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final User? user = authSnapshot.data;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  const Icon(Icons.campaign, size: 80, color: Colors.grey), 
                  const SizedBox(height: 20), 
                  const Text("Log in to buy Ads!", style: TextStyle(fontSize: 18, color: Colors.brown, fontWeight: FontWeight.bold)), 
                  const SizedBox(height: 20), 
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context), 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), 
                    child: const Text("Go Back", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))
                  )
                ]
              )
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
              var userData = dbSnapshot.data?.data() as Map<String, dynamic>?;
              double adsBalance = (userData?['ads_balance'] ?? 0.0).toDouble();
              double dogeBalance = (userData?['doge_balance'] ?? 0.0).toDouble();

              // 👑 WRAPPING THE PAGE IN THE THEME BUILDER
              return ListenableBuilder(
                listenable: themeProvider,
                builder: (context, _) {
                  final isDark = themeProvider.isDarkMode;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity, 
                            padding: const EdgeInsets.all(20), 
                            decoration: BoxDecoration(
                              color: isDark ? themeProvider.darkGreyBoxColor : Colors.orange.shade50, 
                              borderRadius: BorderRadius.circular(15), 
                              border: Border.all(color: isDark ? themeProvider.darkGreyBorder : Colors.orange.shade300, width: 2)
                            ),
                            child: Column(
                              children: [
                                const Text("Ready to Promote?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity, 
                                  child: ElevatedButton.icon(
                                    onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAdPage())); }, 
                                    icon: const Icon(Icons.rocket_launch, color: Colors.white), 
                                    label: const Text("LAUNCH NEW CAMPAIGN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                                  )
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity, 
                            padding: const EdgeInsets.all(20), 
                            decoration: BoxDecoration(
                              color: isDark ? themeProvider.darkGreyBoxColor : Colors.amber.shade50, 
                              borderRadius: BorderRadius.circular(15), 
                              border: Border.all(color: isDark ? themeProvider.darkGreyBorder : Colors.amber.shade300, width: 2)
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.swap_horizontal_circle, color: isDark ? Colors.amber : Colors.brown),
                                    const SizedBox(width: 10),
                                    Text("Instant Vault Swap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text("Balance: ${dogeBalance.toStringAsFixed(4)} DOGE", style: TextStyle(fontSize: 12, color: isDark ? Colors.amber.shade200 : Colors.brown)),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: _swapAmountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  decoration: InputDecoration(
                                    labelText: "DOGE to Convert", 
                                    labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
                                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                    enabledBorder: isDark ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)) : null,
                                    hintText: "1.0",
                                    hintStyle: TextStyle(color: isDark ? Colors.white30 : null),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text("⚠️ Includes a tiny 1% exchange fee", style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey, fontStyle: FontStyle.italic)),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isSwapping ? null : _swapDogeToUsdt,
                                    icon: const Icon(Icons.bolt),
                                    label: Text(_isSwapping ? "Converting..." : "SWAP FOR AD CREDIT"),
                                    style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.amber : Colors.brown, foregroundColor: isDark ? Colors.brown.shade900 : Colors.white),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity, 
                            padding: const EdgeInsets.all(15), 
                            decoration: BoxDecoration(
                              color: isDark ? themeProvider.darkGreyBoxColor : Colors.red.shade50, 
                              border: Border.all(color: isDark ? Colors.red.shade900 : Colors.red.shade200, width: 2), 
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                                SizedBox(width: 15),
                                Expanded(child: Text("IMPORTANT: Funds deposited here are strictly for purchasing advertising. They CANNOT be staked, transferred, or withdrawn back to FaucetPay.", style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)))
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity, 
                            padding: const EdgeInsets.all(20), 
                            decoration: BoxDecoration(
                              color: isDark ? themeProvider.darkGreyBoxColor : Colors.green.shade50, 
                              borderRadius: BorderRadius.circular(15), 
                              border: Border.all(color: isDark ? themeProvider.darkGreyBorder : Colors.green.shade200, width: 2)
                            ),
                            child: Column(
                              children: [
                                const Text("Advertising Balance", style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text("\$${adsBalance.toStringAsFixed(2)} USDT", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.green.shade300 : Colors.green.shade900)),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity, 
                                  child: ElevatedButton.icon(
                                    onPressed: _showDepositDialog, 
                                    icon: const Icon(Icons.add_circle, color: Colors.white), 
                                    label: const Text("DEPOSIT USDT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                                  )
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Align(
                            alignment: Alignment.centerLeft, 
                            child: Text("Ad Store", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown))
                          ),
                          const SizedBox(height: 15),
                          
                          Card(
                            color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                            elevation: isDark ? 0 : 2, 
                            shape: isDark ? RoundedRectangleBorder(side: BorderSide(color: themeProvider.darkGreyBorder), borderRadius: BorderRadius.circular(10)) : null,
                            child: ListTile(
                              leading: const Icon(Icons.image, color: Colors.purple, size: 30), 
                              title: Text("Global Top Banner", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : null)), 
                              subtitle: Text("Top of Faucet page (7 Days).", style: TextStyle(color: isDark ? Colors.white70 : null)), 
                              trailing: const Text("\$7.00", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), 
                              onTap: () => _buyAd(adsBalance, 'global_banner', 'Global Banner', 7.0)
                            )
                          ),
                          Card(
                            color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                            elevation: isDark ? 0 : 2, 
                            shape: isDark ? RoundedRectangleBorder(side: BorderSide(color: themeProvider.darkGreyBorder), borderRadius: BorderRadius.circular(10)) : null,
                            child: ListTile(
                              leading: const Icon(Icons.check_box_outline_blank, color: Colors.blue, size: 30), 
                              title: Text("Square Ad (Left)", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : null)), 
                              subtitle: Text("Next to Claim Button (7 Days).", style: TextStyle(color: isDark ? Colors.white70 : null)), 
                              trailing: const Text("\$3.50", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), 
                              onTap: () => _buyAd(adsBalance, 'square_left', 'Left Square Ad', 3.5)
                            )
                          ),
                          Card(
                            color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                            elevation: isDark ? 0 : 2, 
                            shape: isDark ? RoundedRectangleBorder(side: BorderSide(color: themeProvider.darkGreyBorder), borderRadius: BorderRadius.circular(10)) : null,
                            child: ListTile(
                              leading: const Icon(Icons.check_box_outline_blank, color: Colors.blue, size: 30), 
                              title: Text("Square Ad (Right)", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : null)), 
                              subtitle: Text("Next to Claim Button (7 Days).", style: TextStyle(color: isDark ? Colors.white70 : null)), 
                              trailing: const Text("\$3.50", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), 
                              onTap: () => _buyAd(adsBalance, 'square_right', 'Right Square Ad', 3.5)
                            )
                          ),
                          Card(
                            color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                            elevation: isDark ? 0 : 2, 
                            shape: isDark ? RoundedRectangleBorder(side: BorderSide(color: themeProvider.darkGreyBorder), borderRadius: BorderRadius.circular(10)) : null,
                            child: ListTile(
                              leading: const Icon(Icons.ad_units, color: Colors.red, size: 30), 
                              title: Text("Interstitial Pop-up", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : null)), 
                              subtitle: Text("Shows during claim loading (7 Days).", style: TextStyle(color: isDark ? Colors.white70 : null)), 
                              trailing: const Text("\$14.00", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), 
                              onTap: () => _buyAd(adsBalance, 'interstitial', 'Interstitial Pop-up', 14.0)
                            )
                          ),
                          Card(
                            color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                            elevation: isDark ? 0 : 2, 
                            shape: isDark ? RoundedRectangleBorder(side: BorderSide(color: themeProvider.darkGreyBorder), borderRadius: BorderRadius.circular(10)) : null,
                            child: ListTile(
                              leading: const Icon(Icons.ads_click, color: Colors.orange, size: 30), 
                              title: Text("Buy PTC Clicks", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : null)), 
                              subtitle: Text("Select your duration & volume.", style: TextStyle(color: isDark ? Colors.white70 : null)), 
                              trailing: const Text("Custom", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), 
                              onTap: () => _buyPtcAd(adsBalance)
                            )
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                }
              );
            }
          );
        }
      ),
    );
  }
}

// ==========================================
// ✨ MULTI-TIER PTC EARN PAGE 
// ==========================================
class PtcEarnPage extends StatefulWidget {
  const PtcEarnPage({super.key});

  @override
  State<PtcEarnPage> createState() => _PtcEarnPageState();
}

class _PtcEarnPageState extends State<PtcEarnPage> {
  Stream<DocumentSnapshot>? _userStream;
  Stream<QuerySnapshot>? _clicksStream;
  Stream<QuerySnapshot>? _adsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 🔑 Initialize streams exactly ONCE to prevent Firebase Web crashes
      _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
      _clicksStream = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('ptc_clicks').snapshots();
      _adsStream = FirebaseFirestore.instance.collection('ptc_ads').where('clicks_remaining', isGreaterThan: 0).snapshots();
    }
  }

  void _watchAd(BuildContext context, String adId, String targetUrl, int duration) {
    web.window.open(targetUrl, '_blank'); 
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => PtcTimerDialog(adId: adId, duration: duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || _userStream == null || _clicksStream == null || _adsStream == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('EARN DOGE (PTC)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)), backgroundColor: Colors.amber, centerTitle: true),
        body: const Center(child: Text("You must log in to earn from PTC ads!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 18))),
      );
    }

    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, userDocSnapshot) {
          
          bool canClaimBonus = true;
          int minutesLeft = 0;
          if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
            var uData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
            Timestamp? lastClaim = uData?['last_bonus_sponsor_claim'] as Timestamp?;
            if (lastClaim != null) {
              final now = DateTime.now();
              final difference = now.difference(lastClaim.toDate());
              if (difference.inHours < 3) {
                canClaimBonus = false;
                minutesLeft = 180 - difference.inMinutes; 
              }
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _clicksStream,
            builder: (context, userClicksSnapshot) {
              
              List<String> clickedLast24h = [];
              if (userClicksSnapshot.hasData) {
                final now = DateTime.now();
                for (var doc in userClicksSnapshot.data!.docs) {
                  final clickData = doc.data() as Map<String, dynamic>?;
                  Timestamp? ts = clickData?['timestamp'] as Timestamp?;
                  if (ts != null && now.difference(ts.toDate()).inHours < 24) {
                    clickedLast24h.add(doc.id); 
                  }
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _adsStream,
                builder: (context, adsSnapshot) {
                  if (adsSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  
                  var allAds = adsSnapshot.data?.docs ?? [];
                  var availableAds = allAds.where((doc) => !clickedLast24h.contains(doc.id)).toList();

                  // 👑 WRAP THE REST OF THE PAGE IN THE THEME BUILDER
                  return ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, _) {
                      final isDark = themeProvider.isDarkMode;

                      Widget adContent;
                      if (allAds.isEmpty) {
                        adContent = const Center(child: Text("No ads available right now. Check back later!", style: TextStyle(color: Colors.grey)));
                      } else if (availableAds.isEmpty) {
                        adContent = Center(child: Text("You have clicked all available ads today!\nCome back tomorrow for more.", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)));
                      } else {
                        adContent = Column(
                          children: availableAds.map((doc) {
                            final adData = doc.data() as Map<String, dynamic>? ?? {};
                            
                            int duration = adData['duration'] as int? ?? 10;
                            double reward = (adData['reward'] as num? ?? 0.001).toDouble();
                            String title = adData['title'] as String? ?? "Sponsored Website";
                            String targetUrl = adData['target_url'] as String? ?? "";

                            return Card(
                              // THEMED AD CARDS
                              color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                              elevation: isDark ? 0 : 3,
                              margin: const EdgeInsets.only(bottom: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: isDark ? themeProvider.darkGreyBorder : Colors.transparent, width: 1),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(15),
                                leading: const Icon(Icons.monetization_on, color: Colors.amber, size: 40),
                                title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown)),
                                subtitle: Text("Reward: +${reward.toStringAsFixed(4)} DOGE\nTimer: $duration Seconds", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () => _watchAd(context, doc.id, targetUrl, duration),
                                  child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              // THEMED SUPPORT BOX
                              color: isDark ? themeProvider.darkGreyBoxColor : (canClaimBonus ? Colors.amber.shade100 : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isDark ? themeProvider.darkGreyBorder : (canClaimBonus ? Colors.amber.shade400 : Colors.grey.shade400), 
                                width: 2
                              ),
                            ),
                            child: Column(
                              children: [
                                Text("🌟 Support Golden Paw & Earn DOGE 🌟", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown, fontSize: 16)),
                                const SizedBox(height: 5),
                                const Text("Stay on the page for 30 seconds to earn\n0.003 DOGE & 30 XP!", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canClaimBonus ? Colors.amber : Colors.grey,
                                      foregroundColor: canClaimBonus ? Colors.brown.shade900 : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: Icon(canClaimBonus ? Icons.card_giftcard : Icons.lock_clock),
                                    label: Text(
                                      canClaimBonus ? 'VIEW BONUS SPONSORS' : 'COOLDOWN: $minutesLeft MIN',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.1),
                                    ),
                                    onPressed: canClaimBonus ? () {
                                      web.window.open('/sponsors.html', '_blank');
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) => const BonusTimerDialog(),
                                      );
                                    } : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          adContent, 
                        ],
                      );
                    }
                  );
                }
              );
            }
          );
        }
      ),
    );
  }
}

// ==========================================
// 🚀 SECRET ADMIN DASHBOARD 🚀
// ==========================================
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _adminTabController;

  // Tab 1: PTC fields
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController(text: "10");
  final TextEditingController _rewardCtrl = TextEditingController(text: "0.001");
  final TextEditingController _clicksCtrl = TextEditingController(text: "1000");

  // Tab 2: Partner Links fields
  final TextEditingController _pTitleCtrl = TextEditingController();
  final TextEditingController _pSubCtrl = TextEditingController();
  final TextEditingController _pRewardCtrl = TextEditingController();
  final TextEditingController _pUrlCtrl = TextEditingController();
  String _selectedCategory = 'Wallets';
  String _selectedIcon = 'wallet';
  String _selectedColorHex = '0xFF2196F3'; 

  // Tab 3: Bonus Sponsor fields
  final TextEditingController _bTitleCtrl = TextEditingController();
  final TextEditingController _bImgCtrl = TextEditingController();
  final TextEditingController _bUrlCtrl = TextEditingController();

  // Tab 4: Raw HTML Placeholder fields
  final TextEditingController _phTitleCtrl = TextEditingController();
  final TextEditingController _phCodeCtrl = TextEditingController();
  String _phPosition = 'Top'; // 🚀 NEW: Lets you choose where the ad goes!

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _adminTabController = TabController(length: 4, vsync: this); 
  }

  @override
  void dispose() {
    _adminTabController.dispose();
    super.dispose();
  }

  Future<void> _injectAd() async {
    if (_titleCtrl.text.trim().isEmpty || _urlCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('ptc_ads').add({
        'title': _titleCtrl.text.trim(),
        'target_url': _urlCtrl.text.trim(),
        'duration': int.tryParse(_durationCtrl.text) ?? 10,
        'reward': double.tryParse(_rewardCtrl.text) ?? 0.001,
        'clicks_remaining': int.tryParse(_clicksCtrl.text) ?? 1000,
        'created_at': FieldValue.serverTimestamp(),
      });
      _titleCtrl.clear(); _urlCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PTC Ad Injected!"), backgroundColor: Colors.green));
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _injectPartner() async {
    if (_pTitleCtrl.text.trim().isEmpty || _pUrlCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('partners').add({
        'title': _pTitleCtrl.text.trim(),
        'sub': _pSubCtrl.text.trim(),
        'reward': _pRewardCtrl.text.trim(),
        'url': _pUrlCtrl.text.trim(),
        'category': _selectedCategory,
        'iconName': _selectedIcon,
        'colorHex': _selectedColorHex,
      });
      _pTitleCtrl.clear(); _pSubCtrl.clear(); _pRewardCtrl.clear(); _pUrlCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Partner Link Saved!"), backgroundColor: Colors.green));
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _injectBonusSponsor() async {
    if (_bTitleCtrl.text.trim().isEmpty || _bUrlCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('bonus_sponsors').add({
        'title': _bTitleCtrl.text.trim(),
        'image_url': _bImgCtrl.text.trim(),
        'target_url': _bUrlCtrl.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
      _bTitleCtrl.clear(); _bImgCtrl.clear(); _bUrlCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sponsor Card Added!"), backgroundColor: Colors.green));
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _injectPlaceholder() async {
    if (_phCodeCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('sponsor_placeholders').add({
        'title': _phTitleCtrl.text.trim(),
        'iframe_code': _phCodeCtrl.text.trim(),
        'position': _phPosition, // 🚀 SAVES THE POSITION
        'created_at': FieldValue.serverTimestamp(),
      });
      _phTitleCtrl.clear(); _phCodeCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("HTML Placeholder Injected!"), backgroundColor: Colors.green));
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email != 'ludogx1@gmail.com') {
      return Scaffold(appBar: AppBar(title: const Text('Access Denied'), backgroundColor: Colors.red));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BOSS DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)), 
        backgroundColor: Colors.red.shade900, 
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          // 🚀 INSTANT PREVIEW BUTTON (Bypasses 3 hour lock)
          TextButton.icon(
            icon: const Icon(Icons.visibility, color: Colors.white),
            label: const Text("Preview Sponsors", style: TextStyle(color: Colors.white)),
            onPressed: () => web.window.open('/sponsors.html', '_blank'),
          )
        ],
        bottom: TabBar(
          controller: _adminTabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.ads_click), text: "PTC Config"),
            Tab(icon: Icon(Icons.handshake), text: "Partner Links"),
            Tab(icon: Icon(Icons.card_giftcard), text: "Sponsor Banners"),
            Tab(icon: Icon(Icons.code), text: "Ad Placeholders"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _adminTabController,
        children: [
          // --- TAB 1: PTC CONTROLS ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Ad Title")),
                        const SizedBox(height: 10),
                        TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: "Target URL")),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: _durationCtrl, decoration: const InputDecoration(labelText: "Timer (Seconds)"))),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(controller: _rewardCtrl, decoration: const InputDecoration(labelText: "DOGE Reward"))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(controller: _clicksCtrl, decoration: const InputDecoration(labelText: "Total Clicks Available")),
                        const SizedBox(height: 15),
                        SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: _isLoading ? null : _injectAd, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("PUSH AD LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text("Live Ad Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('ptc_ads').orderBy('created_at', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    return ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.campaign, color: Colors.orange),
                            title: Text(data['title'] ?? 'No Title'), subtitle: Text("${data['reward']} DOGE | ${data['duration']}s"),
                            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('ptc_ads').doc(doc.id).delete()),
                          ),
                        );
                      }
                    );
                  }
                )
              ],
            ),
          ),
          
          // --- TAB 2: PARTNER LINKS ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        TextField(controller: _pTitleCtrl, decoration: const InputDecoration(labelText: "Platform Title")),
                        TextField(controller: _pSubCtrl, decoration: const InputDecoration(labelText: "Description Subtitle")),
                        TextField(controller: _pRewardCtrl, decoration: const InputDecoration(labelText: "Marketing / Reward Text")),
                        TextField(controller: _pUrlCtrl, decoration: const InputDecoration(labelText: "Affiliate Tracking Link")),
                        DropdownButtonFormField<String>(initialValue: _selectedCategory, decoration: const InputDecoration(labelText: "Category"), items: ['Wallets', 'PTC', 'Faucets', 'Mining', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (val) => setState(() => _selectedCategory = val!)),
                        DropdownButtonFormField<String>(initialValue: _selectedIcon, decoration: const InputDecoration(labelText: "Icon Setup"), items: const [DropdownMenuItem(value: 'wallet', child: Text("Wallet Icon")), DropdownMenuItem(value: 'ptc', child: Text("PTC Cursor")), DropdownMenuItem(value: 'faucet', child: Text("Water Faucet")), DropdownMenuItem(value: 'mining', child: Text("Cloud Sync Engine"))], onChanged: (val) => setState(() => _selectedIcon = val!)),
                        DropdownButtonFormField<String>(initialValue: _selectedColorHex, decoration: const InputDecoration(labelText: "Color Tint"), items: const [DropdownMenuItem(value: '0xFF2196F3', child: Text("Blue")), DropdownMenuItem(value: '0xFFFF9800', child: Text("Orange")), DropdownMenuItem(value: '0xFFE91E63', child: Text("Pink")), DropdownMenuItem(value: '0xFF009688', child: Text("Teal"))], onChanged: (val) => setState(() => _selectedColorHex = val!)),
                        const SizedBox(height: 15),
                        SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: _isLoading ? null : _injectPartner, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("INJECT PARTNER LINK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Text("Active Partner Links", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('partners').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    return ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        return Card(child: ListTile(title: Text(data['title'] ?? ''), subtitle: Text("Category: ${data['category']}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('partners').doc(doc.id).delete())));
                      },
                    );
                  },
                )
              ],
            ),
          ),

          // --- TAB 3: BONUS SPONSORS (CARDS) ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        const Text("Add Visual Sponsor Banner", style: TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(),
                        TextField(controller: _bTitleCtrl, decoration: const InputDecoration(labelText: "Sponsor Title")),
                        TextField(controller: _bImgCtrl, decoration: const InputDecoration(labelText: "Banner Image URL")),
                        TextField(controller: _bUrlCtrl, decoration: const InputDecoration(labelText: "Target Affiliate URL")),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: _isLoading ? null : _injectBonusSponsor, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple), child: const Text("INJECT SPONSOR CARD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
                      ]
                    )
                  )
                ),
                const SizedBox(height: 25),
                const Text("Active Sponsor Cards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bonus_sponsors').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    return ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.card_giftcard, color: Colors.purple),
                            title: Text(data['title'] ?? ''),
                            subtitle: Text(data['target_url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('bonus_sponsors').doc(doc.id).delete()),
                          ),
                        );
                      }
                    );
                  }
                )
              ],
            ),
          ),

          // --- TAB 4: AD PLACEHOLDERS (RAW HTML) ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        const Text("Inject Raw HTML (A-Ads / iFrames)", style: TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(),
                        TextField(controller: _phTitleCtrl, decoration: const InputDecoration(labelText: "Reference Title (e.g., Top Banner)")),
                        TextField(controller: _phCodeCtrl, decoration: const InputDecoration(labelText: "Raw iframe Code"), maxLines: 3),
                        
                        // 🚀 NEW DROPDOWN: Choose Top, Middle, or Bottom
                        DropdownButtonFormField<String>(
                          initialValue: _phPosition,
                          decoration: const InputDecoration(labelText: "Page Position"),
                          items: ['Top', 'Middle', 'Bottom'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (val) => setState(() => _phPosition = val!),
                        ),

                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: _isLoading ? null : _injectPlaceholder, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo), child: const Text("INJECT HTML PLACEHOLDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
                      ]
                    )
                  )
                ),
                const SizedBox(height: 25),
                const Text("Active HTML Placeholders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('sponsor_placeholders').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    return ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.code, color: Colors.indigo),
                            title: Text(data['title'] ?? 'Unnamed Snippet'),
                            subtitle: Text("Position: ${data['position'] ?? 'Top'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('sponsor_placeholders').doc(doc.id).delete()),
                          ),
                        );
                      }
                    );
                  }
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 🌟 AFFILIATE LINKS PAGE (HYBRID TABBED)
// ==========================================
class PartnerData {
  final String title, sub, reward, url;
  final IconData icon;
  final Color color;
  final String category; // 🚀 Crucial for Categorization!
  PartnerData(this.title, this.sub, this.reward, this.icon, this.color, this.url, this.category);
}

final partnerList = [
  PartnerData("FaucetPay", "The ultimate crypto micro-wallet. Collect earnings with low fees.", "Best Micro-Wallet", Icons.account_balance_wallet, Colors.blue, "https://faucetpay.io/?r=5173106", "Wallets"),
  PartnerData("Cointiply", "The highest-paying Bitcoin rewards site. Play games, watch videos.", "Huge Survey Payouts", Icons.monetization_on, Colors.red, "https://cointiply.mobi/W6PYqv", "Faucets"),
  PartnerData("CoinPayU", "Earn free crypto by viewing advertisements and completing offers.", "Earn for Viewing Ads", Icons.ads_click, Colors.orange, "https://www.coinpayu.com/?r=ludogx1", "PTC"),
  PartnerData("AdBTC", "Get paid in Bitcoin for surfing the web. A trusted PTC platform.", "Bitcoin Web Surfing", Icons.currency_bitcoin, Colors.amber, "https://r.adbtc.top/2107663", "PTC"),
  PartnerData("DutchyCorp", "Automated faucet that lets you claim dozens of cryptos at once.", "Automated Claims", Icons.autorenew, Colors.teal, "https://autofaucet.dutchycorp.space/?r=woo270", "Faucets"),
  PartnerData("Contract-Miner", "Virtual cloud mining simulator. Earn real crypto passively.", "Simulated Cloud Mining", Icons.cloud_sync, Colors.indigo, "https://www.contract-miner.com/?r=91714744460d2dde189cc5", "Mining"),
  PartnerData("FireFaucet", "Level up and earn crypto automatically with daily bonuses.", "Level Up & Earn", Icons.local_fire_department, Colors.deepOrange, "https://firefaucet.win/ref/505709", "Faucets"),
  PartnerData("VieFaucet", "Fast crypto faucet. Complete shortlinks, PTC ads, and claims.", "Fast Shortlink Payouts", Icons.bolt, Colors.yellow.shade800, "https://viefaucet.com?r=637313decfe45da7ea2d376e", "Faucets"),
  PartnerData("CoinAdster", "Claim bits every hour! Features a reliable faucet and offerwalls.", "Hourly Crypto Faucet", Icons.watch_later, Colors.cyan, "https://coinadster.com/?ref=186362", "Faucets"),
  PartnerData("EarnBitMoon", "Claim crypto every 5 minutes. Watch ads and build bonuses.", "5-Minute Claims", Icons.nightlight_round, Colors.blueGrey, "https://earnbitmoon.club/?ref=59132", "Faucets"),
  PartnerData("Coinpayz", "Multi-coin faucet with instant payouts to your wallet.", "Instant Payouts", Icons.account_balance, Colors.green.shade700, "https://coinpayz.xyz/?r=784813", "Faucets"),
  PartnerData("Honeygain", "Earn passive income by sharing unused internet bandwidth.", "Passive Income", Icons.wifi_tethering, Colors.blueAccent, "https://join.honeygain.com/LUDOG88986", "Other"),
];

class AffiliateLinksPage extends StatefulWidget {
  const AffiliateLinksPage({super.key});
  @override
  State<AffiliateLinksPage> createState() => _AffiliateLinksPageState();
}

class _AffiliateLinksPageState extends State<AffiliateLinksPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['Wallets', 'PTC', 'Faucets', 'Mining', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getAdminIcon(String name) {
    switch (name) {
      case 'wallet': return Icons.account_balance_wallet;
      case 'ptc': return Icons.ads_click;
      case 'faucet': return Icons.water_drop;
      case 'mining': return Icons.cloud_sync;
      default: return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: Column(
        children: [
          const SizedBox(height: 15),
          const Text("Earn More Crypto", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Text("Sign up for our trusted partner sites below to maximize your daily crypto earnings.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const SizedBox(height: 10),
          Container(
            height: 40, margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
            child: TabBar(
              controller: _tabController, isScrollable: true, indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
              labelColor: Colors.brown.shade900, unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: _categories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),
          const SizedBox(height: 15),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                var staticPartners = partnerList.where((p) => p.category == category).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('partners').where('category', isEqualTo: category).snapshots(),
                  builder: (context, snapshot) {
                    var dynamicDocs = snapshot.hasData ? snapshot.data!.docs : [];
                    if (staticPartners.isEmpty && dynamicDocs.isEmpty) return const Center(child: Text("No partners in this category yet.", style: TextStyle(color: Colors.grey)));

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      children: [
                        ...staticPartners.map((p) => _buildCompactCard(title: p.title, sub: p.sub, reward: p.reward, icon: p.icon, color: p.color, url: p.url)),
                        ...dynamicDocs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          Color iconColor = Color(int.tryParse(data['colorHex'] ?? '0xFF000000') ?? 0xFF000000);
                          return _buildCompactCard(title: data['title'] ?? '', sub: data['sub'] ?? '', reward: data['reward'] ?? '', icon: _getAdminIcon(data['iconName'] ?? ''), color: iconColor, url: data['url'] ?? '');
                        }),
                        const SizedBox(height: 30), 
                      ],
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard({required String title, required String sub, required String reward, required IconData icon, required Color color, required String url}) {
    return Card(
      elevation: 2, margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundColor: color.withAlpha(30), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text(reward, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => web.window.open(url, '_blank'),
              child: const Text("JOIN", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🌟 UPDATED REFERRAL DASHBOARD 🌟
// ==========================================
class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String refLink = user != null ? "https://golden-paw-database.web.app/?ref=${user.uid.substring(0, 8)}" : "Login to get your referral link!";

    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_add, size: 80, color: Colors.purple),
              const SizedBox(height: 20),
              const Text("Earn 20% For Life!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 10),
              const Text("Share your link. Every time your friend claims from the faucet, you get a 20% bonus automatically added to your Vault!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple.shade200)),
                child: Column(
                  children: [
                    const Text("Your Unique Link:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                    const SizedBox(height: 10),
                    SelectableText(refLink, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              const Align(
                alignment: Alignment.centerLeft, 
                child: Text("Your Referral Network", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown))
              ),
              const SizedBox(height: 15),
              
              if (user == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20), 
                    child: Text("Log in to see your referral stats!", style: TextStyle(color: Colors.grey))
                  )
                )
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('referred_by', isEqualTo: user.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Card(
                        elevation: 0, 
                        color: Colors.grey.shade100, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: const Padding(
                          padding: EdgeInsets.all(20), 
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey), 
                              SizedBox(width: 15), 
                              Expanded(child: Text("You haven't referred any users yet. Start sharing your link to earn passive DOGE!", style: TextStyle(color: Colors.grey, fontSize: 13)))
                            ],
                          ),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Earned (20%)', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: snapshot.data!.docs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          double commission = (data['referral_earnings_for_parent'] ?? 0.0).toDouble();
                          return DataRow(cells: [
                            DataCell(Text("${doc.id.substring(0, 8)}...")),
                            DataCell(Text("${commission.toStringAsFixed(6)} DOGE", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          ]);
                        }).toList(),
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), 
                child: const Text("Back to Faucet", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 🌟 LEGAL & SUPPORT PAGES 🌟
// ==========================================

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const ExpansionTile(
                  title: Text("What is Golden Paw?", style: TextStyle(fontWeight: FontWeight.bold)), 
                  children: [Padding(padding: EdgeInsets.all(15), child: Text("Golden Paw is a premier Dogecoin reward platform and advertising network. Users can earn free DOGE by claiming from our faucet or viewing sponsored PTC (Paid-To-Click) ads. Advertisers can purchase high-quality crypto traffic."))]
                ),
                const ExpansionTile(
                  title: Text("How do I withdraw my earnings?", style: TextStyle(fontWeight: FontWeight.bold)), 
                  children: [Padding(padding: EdgeInsets.all(15), child: Text("Once you reach the minimum withdrawal threshold of 0.001 DOGE in your Vault, you can navigate to your Profile, enter your FaucetPay Dogecoin address, and initiate an instant withdrawal."))]
                ),
                const ExpansionTile(
                  title: Text("Can I use a VPN or Proxy?", style: TextStyle(fontWeight: FontWeight.bold)), 
                  children: [Padding(padding: EdgeInsets.all(15), child: Text("Absolutely not. The use of VPNs, Proxies, Tor nodes, or automated claiming bots is strictly prohibited. Our security systems will automatically flag and permanently ban any accounts caught using these methods."))]
                ),
                const ExpansionTile(
                  title: Text("How does Staking work?", style: TextStyle(fontWeight: FontWeight.bold)), 
                  children: [Padding(padding: EdgeInsets.all(15), child: Text("You can lock your available DOGE into the Vault to earn an 8.5% Annual Percentage Yield (APY). Interest is calculated and distributed every single second."))]
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CookiePolicyPage extends StatelessWidget {
  const CookiePolicyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Cookie Policy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                const SizedBox(height: 15),
                const Text("Last Updated: May 2026\n\nGolden Paw uses minimal cookies and local storage to ensure the basic functionality and security of our platform.\n\n"
                "1. Essential Storage\nWe use secure local browser storage to remember your FaucetPay address and maintain your login session.\n\n"
                "2. Security Cookies\nOur anti-bot providers (Cloudflare Turnstile and hCaptcha) may place temporary session cookies on your device to verify that you are a human.", 
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Terms of Service", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                const SizedBox(height: 15),
                const Text("1. User Conduct & Fair Play\nUsers are permitted strictly ONE account per person. The use of automated claiming scripts, bots, VPNs, or VPS services is strictly prohibited.\n\n"
                "2. Earnings and Withdrawals\nBalances held within the Vault hold no real-world fiat value until successfully withdrawn to a third-party wallet.\n\n"
                "3. Advertising Network\nFunds deposited into the Advertising Balance are strictly for the purchase of on-site ad campaigns. All ad purchases are final and non-refundable.", 
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Privacy Policy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                const SizedBox(height: 15),
                const Text("1. Data We Collect\nWhen you register, we collect your email address. When you withdraw, we collect your FaucetPay linked Dogecoin address.\n\n"
                "2. Third-Party Services\nWe utilize Google Firebase for secure authentication and database management. We use Cloudflare and hCaptcha for bot mitigation.", 
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.support_agent, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text("Need Help?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 15),
              const Text("If you have questions about a withdrawal, an ad campaign, or need to report a bug, please reach out!", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade200, width: 2)),
                child: const Column(
                  children: [
                    Text("Email Support", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18)),
                    SizedBox(height: 10),
                    Text("support@goldenpaw.com", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text("We aim to respond to all inquiries within 24-48 hours.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), 
                onPressed: () => Navigator.pop(context), 
                child: const Text("Back", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ⏱️ PTC AD TIMER DIALOG
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
    _timeLeft = widget.duration;
    _stopwatch.start();
    _startTimer();

    _messageSubscription = web.EventStreamProviders.messageEvent.forTarget(web.window).listen((web.Event event) {
      try {
        final msgEvent = event as web.MessageEvent;
        final dartData = msgEvent.data?.dartify(); 
        String? dataStr;
        if (dartData is String) { dataStr = dartData; } else if (dartData != null) { dataStr = dartData.toString(); }

        if (dataStr != null && dataStr.contains('captcha')) {
          final data = jsonDecode(dataStr);
          if (data['type'] == 'captcha') {
            if (mounted) {
              setState(() { _captchaToken = data['token']; });
              if (_showCaptcha && !_isProcessing) {
                _processClaim();
              }
            }
          }
        }
      } catch (e) { /* ignore */ }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_isProcessing || _showCaptcha) return;

      bool isFocused = web.document.hasFocus();
      
      if (isFocused) {
        if (_stopwatch.isRunning) {
          _stopwatch.stop();
          if (mounted) setState(() => _message = "⚠️ Paused! Go back and view the Ad tab!");
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
        }
      } else {
        if (mounted && remaining != _timeLeft) {
          setState(() {
            _timeLeft = remaining;
            _message = "Watching Ad... $_timeLeft seconds left";
          });
        }
      }
    });
  }

  void _forceRenderCaptcha() {
    setState(() => _captchaLoading = true); 
    Timer(const Duration(milliseconds: 200), () {
      try {
        if (_selectedCaptcha == 'hCaptcha') { renderHCaptcha(); } else if (_selectedCaptcha == 'Turnstile') { renderTurnstile(); }
      } catch (e) { /* ignore */ }
    });
  }

  Future<void> _processClaim() async {
    if (_isProcessing) return;
    _isProcessing = true;
    setState(() => _message = "Verifying...");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('https://golden-paw-vault.onrender.com/claim-ptc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken, 
          'ad_id': widget.adId,
          'captcha_token': _captchaToken,
          'captcha_provider': _selectedCaptcha
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _claimed = true;
            _showCaptcha = false;
            _message = "Success! DOGE & +5 XP added to Vault.";
          });
        }
      } else {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) setState(() { _message = "Error: ${err['error']}"; _isProcessing = false; _captchaToken = null; _captchaLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _message = "Connection error. Try again."; _isProcessing = false; _captchaToken = null; _captchaLoading = false; });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(25),
        height: _showCaptcha ? 350 : 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showCaptcha && !_claimed) ...[
              const Text("Almost done! Verify you are human.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 15),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.amber.shade200)),
                child: DropdownButton<String>(
                  value: _selectedCaptcha, icon: const Icon(Icons.arrow_drop_down, color: Colors.brown, size: 16), elevation: 16, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 13), underline: Container(), 
                  onChanged: (String? value) { setState(() { _selectedCaptcha = value!; _captchaToken = null; _captchaLoading = false; }); },
                  items: const [DropdownMenuItem(value: 'hCaptcha', child: Text('hCaptcha')), DropdownMenuItem(value: 'Turnstile', child: Text('Turnstile'))],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 120, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.amber, width: 2), borderRadius: BorderRadius.circular(8), color: Colors.white),
                child: PointerInterceptor(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_captchaToken == null && _selectedCaptcha == 'hCaptcha') const SizedBox(width: 320, height: 90, child: HtmlElementView(viewType: 'hcaptcha-widget'))
                      else if (_captchaToken == null && _selectedCaptcha == 'Turnstile') const SizedBox(width: 320, height: 90, child: HtmlElementView(viewType: 'turnstile-widget')),
                      
                      if (!_captchaLoading && _captchaToken == null) ElevatedButton(onPressed: _forceRenderCaptcha, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, elevation: 0), child: const Text("Tap to Verify", style: TextStyle(color: Colors.brown))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(_message, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _isProcessing ? Colors.blue : Colors.red, fontSize: 14)),
            ] 
            else if (!_claimed) ...[
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 25),
              Text(_message, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _message.contains("Paused") ? Colors.red : Colors.brown, fontSize: 16)),
            ] 
            else ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 15),
              Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text("CLOSE", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🌟 TRUSTED BONUS SPONSOR 30-SECOND TIMER DIALOG
// ==========================================
class BonusTimerDialog extends StatefulWidget {
  const BonusTimerDialog({super.key});

  @override
  State<BonusTimerDialog> createState() => _BonusTimerDialogState();
}

class _BonusTimerDialogState extends State<BonusTimerDialog> {
  late int _timeLeft;
  late final Stopwatch _stopwatch = Stopwatch();
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
    _timeLeft = 30; // 30 seconds required
    _stopwatch.start();
    _startTimer();

    _messageSubscription = web.EventStreamProviders.messageEvent.forTarget(web.window).listen((web.Event event) {
      try {
        final msgEvent = event as web.MessageEvent;
        final dartData = msgEvent.data?.dartify();
        String? dataStr;
        if (dartData is String) { dataStr = dartData; } else if (dartData != null) { dataStr = dartData.toString(); }

        if (dataStr != null && dataStr.contains('captcha')) {
          final data = jsonDecode(dataStr);
          if (data['type'] == 'captcha') {
            if (mounted) {
              setState(() { _captchaToken = data['token']; });
              if (_showCaptcha && !_isProcessing) {
                _processBonusClaim();
              }
            }
          }
        }
      } catch (e) { /* ignore */ }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_isProcessing || _showCaptcha) return;

      bool isFocused = web.document.hasFocus();
      
      if (isFocused) {
        if (_stopwatch.isRunning) {
          _stopwatch.stop();
          if (mounted) setState(() => _message = "⚠️ Paused! Go back and view the Sponsor tab!");
        }
      } else {
        if (!_stopwatch.isRunning) {
          _stopwatch.start();
        }
      }

      int elapsedSeconds = _stopwatch.elapsed.inSeconds;
      int remaining = 30 - elapsedSeconds;

      if (remaining <= 0) {
        timer.cancel();
        _stopwatch.stop();
        if (mounted) {
          setState(() {
            _timeLeft = 0;
            _showCaptcha = true;
            _message = "Solve Captcha to Claim!";
          });
        }
      } else {
        if (mounted && remaining != _timeLeft) {
          setState(() {
            _timeLeft = remaining;
            _message = "Watching Sponsor... $_timeLeft seconds left";
          });
        }
      }
    });
  }

  void _forceRenderCaptcha() {
    setState(() => _captchaLoading = true); 
    Timer(const Duration(milliseconds: 200), () {
      try {
        if (_selectedCaptcha == 'hCaptcha') { renderHCaptcha(); } else if (_selectedCaptcha == 'Turnstile') { renderTurnstile(); }
      } catch (e) { /* ignore */ }
    });
  }

  Future<void> _processBonusClaim() async {
    if (_isProcessing) return;
    _isProcessing = true;
    setState(() => _message = "Verifying...");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('https://golden-paw-vault.onrender.com/claim-bonus-sponsor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'captcha_token': _captchaToken,
          'captcha_provider': _selectedCaptcha
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _claimed = true;
            _showCaptcha = false;
            _message = "Success! 0.003 DOGE & +30 XP added!";
          });
        }
      } else {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) setState(() { _message = "Error: ${err['error']}"; _isProcessing = false; _captchaToken = null; _captchaLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _message = "Connection error. Try again."; _isProcessing = false; _captchaToken = null; _captchaLoading = false; });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(25),
        height: _showCaptcha ? 350 : 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showCaptcha && !_claimed) ...[
              const Text("Almost done! Verify you are human.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 15),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.amber.shade200)),
                child: DropdownButton<String>(
                  value: _selectedCaptcha, icon: const Icon(Icons.arrow_drop_down, color: Colors.brown, size: 16), elevation: 16, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 13), underline: Container(), 
                  onChanged: (String? value) { setState(() { _selectedCaptcha = value!; _captchaToken = null; _captchaLoading = false; }); },
                  items: const [DropdownMenuItem(value: 'hCaptcha', child: Text('hCaptcha')), DropdownMenuItem(value: 'Turnstile', child: Text('Turnstile'))],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 120, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.amber, width: 2), borderRadius: BorderRadius.circular(8), color: Colors.white),
                child: PointerInterceptor(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_captchaToken == null && _selectedCaptcha == 'hCaptcha') const SizedBox(width: 320, height: 90, child: HtmlElementView(viewType: 'hcaptcha-widget'))
                      else if (_captchaToken == null && _selectedCaptcha == 'Turnstile') const SizedBox(width: 320, height: 90, child: HtmlElementView(viewType: 'turnstile-widget')),
                      
                      if (!_captchaLoading && _captchaToken == null) ElevatedButton(onPressed: _forceRenderCaptcha, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, elevation: 0), child: const Text("Tap to Verify", style: TextStyle(color: Colors.brown))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(_message, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _isProcessing ? Colors.blue : Colors.red, fontSize: 14)),
            ] 
            else if (!_claimed) ...[
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 25),
              Text(_message, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _message.contains("Paused") ? Colors.red : Colors.brown, fontSize: 16)),
            ] 
            else ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 15),
              Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text("CLOSE", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 📋 SECURE DEDICATED OFFERWALL HUB
// ==========================================
class OfferwallHubPage extends StatefulWidget {
  const OfferwallHubPage({super.key});

  @override
  State<OfferwallHubPage> createState() => _OfferwallHubPageState();
}

class _OfferwallHubPageState extends State<OfferwallHubPage> {
  // Tracks which network engine is currently loaded into the container view
  String selectedNetwork = "NONE"; 

  // Generates the personalized, cryptographically tracked wall link for each user
  String getOfferwallUrl(String provider, String uid) {
    if (provider == "MONLIX") {
      // ⚠️ Replace 'YOUR_MONLIX_ID' with your real API ID from your Monlix account
      return "https://offers.monlix.com/wall?appid=YOUR_MONLIX_ID&userid=$uid";
    }
    if (provider == "LOOTABLY") {
      // ⚠️ Replace 'YOUR_LOOTABLY_ID' with your real API ID from your Lootably account
      return "https://wall.lootably.com/web/YOUR_LOOTABLY_ID/$uid";
    }
    return "https://google.com"; // Fallback placeholder
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offerwalls'), backgroundColor: Colors.amber),
        body: const Center(child: Text("Please log in to view high-paying tasks!", style: TextStyle(fontWeight: FontWeight.bold))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Offerwall Tasks', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          
          var userData = snapshot.data?.data() as Map<String, dynamic>?;
          double pendingBalance = (userData?['pending_offer_balance'] ?? 0.0).toDouble();
          int xp = (userData?['xp'] ?? 0).toInt();
          int level = sqrt(xp / 100).floor(); 

          // 🔒 Level Protection Gate
          if (level < 3) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_person, size: 70, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text("Offerwalls Locked!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                    const SizedBox(height: 10),
                    Text("To prevent fraud, you must reach Level 3 before unlocking premium offers. You are currently Level $level.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 💼 Balance Staging Display Card
                Card(
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.amber.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Pending Offer Yield:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                            SizedBox(height: 5),
                            Text("Held for verification safety", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        Text("${pendingBalance.toStringAsFixed(4)} DOGE", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // ⚠️ Quarantine Policy Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade200)),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 18),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Safety Policy: Offerwall rewards remain pending for 7 days to clear network anti-fraud sweeps before routing to your main balance.",
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)
                        )
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // 🌐 PROVIDER SELECTION INTERFACE
                const Text("Select a Task Provider Network:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Monlix Selection Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedNetwork == "MONLIX" ? Colors.orange : Colors.grey.shade200,
                          foregroundColor: selectedNetwork == "MONLIX" ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.rocket_launch),
                        label: const Text("Monlix Engine", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => setState(() => selectedNetwork = "MONLIX"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Lootably Selection Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedNetwork == "LOOTABLY" ? Colors.purple : Colors.grey.shade200,
                          foregroundColor: selectedNetwork == "LOOTABLY" ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.flash_on),
                        label: const Text("Lootably Core", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => setState(() => selectedNetwork = "LOOTABLY"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 🖼️ DYNAMIC RAW HTML IFRAME CONTAINER CONTEXT
                if (selectedNetwork == "NONE")
                  Container(
                    height: 400,
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Choose a provider network above to initialize your tasks matrix.", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Active Matrix: $selectedNetwork", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                      TextButton.icon(
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text("Close Tasks View", style: TextStyle(color: Colors.red, fontSize: 12)),
                        onPressed: () => setState(() => selectedNetwork = "NONE"),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  // The actual embedded HTML view frame box container
                  Container(
                    height: 700, // Allocates a tall sandbox inside your layout for the scrolling offers
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber.shade300, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: HtmlElementView.fromTagName(
                      tagName: 'iframe',
                      onElementCreated: (Object element) {
                        // Casts the generated web element dynamically to tweak browser properties
                        final iframe = element as dynamic;
                        iframe.src = getOfferwallUrl(selectedNetwork, user.uid);
                        iframe.style.border = 'none';
                        iframe.style.width = '100%';
                        iframe.style.height = '100%';
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}