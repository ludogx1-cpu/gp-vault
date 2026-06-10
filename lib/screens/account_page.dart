import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../src/user_provider.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---




void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 REGISTER VIEWS (CAPTCHAS & TENOR GIF)
  try {
    // 1. hCaptcha
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('hcaptcha-widget', (
      int viewId,
    ) {
      final div = web.HTMLDivElement();
      div.id = 'hcaptcha-target';
      div.setAttribute(
        'style',
        'display: flex; justify-content: center; align-items: center; width: 100%; height: 100%; transform: scale(0.85); transform-origin: center center;',
      );
      return div;
    });

    // 2. Turnstile
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('turnstile-widget', (
      int viewId,
    ) {
      final div = web.HTMLDivElement();
      div.id = 'turnstile-target';
      div.setAttribute(
        'style',
        'display: flex; justify-content: center; align-items: center; width: 100%; height: 100%; transform: scale(0.85); transform-origin: center center;',
      );
      return div;
    });

    // 3. Tenor Dogecoin Animated GIF View (Original Embed + Hover Blocked!)
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('tenor-gif-view', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      // pointer-events: none completely blocks the Tenor hover menu
      iframe.setAttribute(
        'style',
        'border: none; width: 100%; height: 100%; pointer-events: none;',
      );

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
              <div class="tenor-gif-embed" data-postid="4351659229197618111" data-share-method="host" data-aspect-ratio="1" data-width="100%">
                <a href="https://tenor.com/view/dogecoin-logo-animation-dogecoin-logo-animation-crypto-gif-4351659229197618111">Dogecoin Logo GIF</a>
              </div>
              <script type="text/javascript" async src="https://tenor.com/embed.js"></script>
            </body>
          </html>
        ''');
      return iframe;
    });
  } catch (e) {
    // ignore: empty_catches
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

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _withdrawAddressController =
      TextEditingController();
  final TextEditingController _withdrawAmountController =
      TextEditingController();
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
      setState(() {
        _withdrawAddressController.text = savedAddress;
      });
    }
  }

  Future<void> _processWithdrawal(double maxBalance) async {
    double? amountToWithdraw = double.tryParse(
      _withdrawAmountController.text.trim(),
    );
    if (amountToWithdraw == null) {
      setState(() => _withdrawMessage = "Please enter a valid number.");
      return;
    }
    if (amountToWithdraw < 0.001) {
      setState(() => _withdrawMessage = "Minimum withdrawal is 0.001 DOGE.");
      return;
    }
    if (amountToWithdraw > maxBalance) {
      setState(() => _withdrawMessage = "Insufficient Vault Balance.");
      return;
    }
    if (_withdrawAddressController.text.trim().isEmpty) {
      setState(
        () => _withdrawMessage = "Please enter a FaucetPay Dogecoin address.",
      );
      return;
    }

    setState(() {
      _isWithdrawing = true;
      _withdrawMessage = "Processing withdrawal...";
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final response = await http.post(
          Uri.parse('https://golden-paw-vault.onrender.com/withdraw'),
          headers: await getAuthHeaders(),
          body: jsonEncode({
            "user_address": _withdrawAddressController.text.trim(),
            "amount": amountToWithdraw,
          }),
        );

        if (!mounted) {
          return;
        }

        if (response.statusCode == 200) {
          setState(() {
            _withdrawMessage =
                "Success! $amountToWithdraw DOGE sent to FaucetPay.";
            _withdrawAmountController.clear();
          });
        } else {
          try {
            final errorData = jsonDecode(response.body);
            setState(() {
              _withdrawMessage =
                  "Declined: ${errorData['error'] ?? 'Unknown error'}";
            });
          } catch (_) {
            setState(() {
              _withdrawMessage =
                  "Server Error ${response.statusCode}: The server is still updating. Try again in a few mins!";
            });
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
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GlobalAppBar(),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = FirebaseAuth.instance.currentUser;
          return PageWithFooter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: isDark
                        ? Colors.amber.shade700.withValues(alpha: 0.22)
                        : Colors.amber.shade100,
                    child: Icon(
                      Icons.pets,
                      size: 70,
                      color: isDark
                          ? Colors.amber.shade300
                          : Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (user == null) ...[
                    Text(
                      "Not Logged In",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: gpBrownText(context, darkColor: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Create a Golden Paw account to unlock the full ecosystem.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),
                    ListenableBuilder(
                      listenable: themeProvider,
                      builder: (context, _) {
                        final isDark = themeProvider.isDarkMode;
                        return AnimatedHoverCard(
                          backgroundColor: isDark
                              ? Colors.grey.shade900
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.amber.shade200,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.amber,
                                    size: 28,
                                  ),
                                  title: Text(
                                    "Save Your Doge",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.brown,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Store claims internally instead of instantly sending to FaucetPay.",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.bolt,
                                    color: Colors.amber,
                                    size: 28,
                                  ),
                                  title: Text(
                                    "Earn Staking Rewards",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.brown,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Lock your saved Doge in the Vault to earn daily interest.",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => showAuthDialogGlobal(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "LOG IN",
                          style: TextStyle(
                            color: Colors.brown,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => showAuthDialogGlobal(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.amber.shade700,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          "CREATE ACCOUNT",
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Builder(
                      builder: (context) {
                        double currentBalance = 0.0;
                        final userData = userProvider.userData;
                        if (userData != null) {
                          currentBalance = (userData['doge_balance'] ?? 0.0).toDouble();
                        }

                        return Column(
                          children: [
                            const Text(
                              "Welcome back!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              user.email ?? "Unknown Doge",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: gpBrownText(
                                  context,
                                  darkColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            ListenableBuilder(
                              listenable: themeProvider,
                              builder: (context, _) {
                                final isDark = themeProvider.isDarkMode;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade900
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.security,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      "Two-Factor Auth (2FA)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Protect your Vault balance",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                    trailing: Switch(
                                      value: _twoFactorEnabled,
                                      activeThumbColor: Colors.green,
                                      onChanged: (val) {
                                        if (!context.mounted) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "2FA Setup coming soon!",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 30),
                            ListenableBuilder(
                              listenable: themeProvider,
                              builder: (context, _) {
                                final isDark = themeProvider.isDarkMode;
                                return AnimatedHoverCard(
                                  backgroundColor: isDark
                                      ? Colors.grey.shade900
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.amber.shade300,
                                    width: 1,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.outbound,
                                              color: isDark
                                                  ? Colors.amber
                                                  : Colors.brown,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "Withdraw to FaucetPay",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.brown,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Divider(
                                          height: 20,
                                          color: isDark
                                              ? Colors.amber.withValues(
                                                  alpha: 0.3,
                                                )
                                              : Colors.grey,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Available to Withdraw:",
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "${currentBalance.toStringAsFixed(8)} DOGE",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.amber
                                                    : Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Minimum Withdrawal: 0.001 DOGE",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        TextField(
                                          controller:
                                              _withdrawAddressController,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          onChanged: (value) async {
                                            final prefs =
                                                await SharedPreferences.getInstance();
                                            await prefs.setString(
                                              'doge_address',
                                              value.trim(),
                                            );
                                          },
                                          decoration: InputDecoration(
                                            labelText:
                                                "FaucetPay Dogecoin Address",
                                            labelStyle: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.account_balance_wallet,
                                              size: 20,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 0,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        TextField(
                                          controller: _withdrawAmountController,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: InputDecoration(
                                            labelText: "Amount (DOGE)",
                                            labelStyle: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.monetization_on,
                                              size: 20,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 0,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 45,
                                          child: ElevatedButton(
                                            onPressed: _isWithdrawing
                                                ? null
                                                : () => _processWithdrawal(
                                                    currentBalance,
                                                  ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: _isWithdrawing
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Text(
                                                    "WITHDRAW NOW",
                                                    style: TextStyle(
                                                      color: Colors.brown,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        if (_withdrawMessage.isNotEmpty) ...[
                                          const SizedBox(height: 15),
                                          Center(
                                            child: Text(
                                              _withdrawMessage,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    _withdrawMessage.contains(
                                                      "Success",
                                                    )
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                },
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  "LOG OUT",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 🌟 THE AD HUB & DEPOSIT PAGE 🌟
// ==========================================

