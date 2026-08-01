import '../src/js_bindings.dart';
import 'universal_web_view/universal_web_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../src/theme_provider.dart';

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



  @override
  void initState() {
    super.initState();
    _loadPrefs();
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
            });
          }
        }
      }
    } catch (e) {
      /* ignore */
    }
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
                              : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCaptcha,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: isDark ? Colors.grey.shade400 : Colors.black87,
                            size: 16,
                          ),
                          elevation: 16,
                          dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.black87,
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_captchaToken == null &&
                            _selectedCaptcha == 'hCaptcha')
                          UniversalWebView.create(
                            viewType: 'hcaptcha-widget',
                            width: 320,
                            height: 90,
                            onMessageReceived: _onCaptchaMessage,
                          )
                        else if (_captchaToken == null &&
                            _selectedCaptcha == 'Turnstile')
                          UniversalWebView.create(
                            viewType: 'turnstile-widget',
                            width: 320,
                            height: 90,
                            onMessageReceived: _onCaptchaMessage,
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
                            UserCredential userCred = await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                  email: emailCtrl.text.trim(),
                                  password: passCtrl.text.trim(),
                                );
                                
                            // Send verification email automatically to existing unverified users
                            if (userCred.user != null && !userCred.user!.emailVerified) {
                              await userCred.user!.sendEmailVerification();
                            }
                          } else {
                            UserCredential userCred = await FirebaseAuth
                                .instance
                                .createUserWithEmailAndPassword(
                                  email: emailCtrl.text.trim(),
                                  password: passCtrl.text.trim(),
                                );
                                
                            // Send verification email automatically
                            if (userCred.user != null && !userCred.user!.emailVerified) {
                              await userCred.user!.sendEmailVerification();
                            }

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userCred.user!.uid)
                                .set({
                                  'email': userCred.user!.email,
                                  'doge_balance': 0.0,
                                  'staked_balance': 0.0,
                                  'bank_balance': 0.0,
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
                          context.go('/faucet');
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
                          UserCredential userCred;
                          if (kIsWeb) {
                            // Web: use popup
                            final authProvider = GoogleAuthProvider();
                            userCred = await FirebaseAuth.instance
                                .signInWithPopup(authProvider);
                          } else {
                            // Android/iOS: use google_sign_in package
                            final GoogleSignIn googleSignIn = GoogleSignIn();
                            final GoogleSignInAccount? googleUser =
                                await googleSignIn.signIn();
                            if (googleUser == null) {
                              // User cancelled
                              setState(() => isLoading = false);
                              return;
                            }
                            final GoogleSignInAuthentication googleAuth =
                                await googleUser.authentication;
                            final credential = GoogleAuthProvider.credential(
                              accessToken: googleAuth.accessToken,
                              idToken: googleAuth.idToken,
                            );
                            userCred = await FirebaseAuth.instance
                                .signInWithCredential(credential);
                          }

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
                                  'bank_balance': 0.0,
                                  'ads_balance': 0.0,
                                  'offerwall_balance': 0.0,
                                  'xp': 0,
                                  'streak_count': 0,
                                  'joined_date': DateTime.now()
                                      .toIso8601String(),
                                });
                          }
                          if (!context.mounted) return;
                          context.go('/faucet');
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
