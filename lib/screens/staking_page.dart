import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class StakingPage extends StatefulWidget {
  const StakingPage({super.key});
  @override
  State<StakingPage> createState() => _StakingPageState();
}

class _StakingPageState extends State<StakingPage> {
  final TextEditingController _amountController = TextEditingController();

  Future<void> _harvestInterest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
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
          int secondsPassed = DateTime.now()
              .difference(stakeTime.toDate())
              .inSeconds;
          if (secondsPassed > 0) {
            pendingInterest =
                currentStaked * (0.085 / 31536000) * secondsPassed;
          }
        }

        if (pendingInterest <= 0) {
          throw Exception("No interest to harvest yet!");
        }

        transaction.update(docRef, {
          'doge_balance': currentBalance + pendingInterest,
          'stake_timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Successfully Harvested Interest! 🌾",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _stakeDoge(double amountToStake) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
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
          int secondsPassed = DateTime.now()
              .difference(stakeTime.toDate())
              .inSeconds;
          if (secondsPassed > 0) {
            pendingInterest =
                currentStaked * (0.085 / 31536000) * secondsPassed;
          }
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

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Successfully staked $amountToStake DOGE! 🐾",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _amountController.clear();
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Vault Error: ${e.toString().replaceAll("Exception: ", "")}",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unstakeDoge(double amountToUnstake) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
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
          int secondsPassed = DateTime.now()
              .difference(stakeTime.toDate())
              .inSeconds;
          if (secondsPassed > 0) {
            pendingInterest =
                currentStaked * (0.085 / 31536000) * secondsPassed;
          }
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

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Successfully unstaked $amountToUnstake DOGE! 🔓",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue,
        ),
      );
      _amountController.clear();
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Vault Error: ${e.toString().replaceAll("Exception: ", "")}",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GlobalAppBar(),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "You must log in to access The Vault.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final userData = userProvider.userData;
          if (userData == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          double dogeBalance = (userData['doge_balance'] ?? 0.0).toDouble();
          double stakedBalance = (userData['staked_balance'] ?? 0.0).toDouble();
          Timestamp? stakeTimestamp = userData['stake_timestamp'] as Timestamp?;

          return PageWithFooter(
            // 👑 Wrapped the main padding layout in ListenableBuilder
            child: ListenableBuilder(
              listenable: themeProvider,
              builder: (context, _) {
                final isDark = themeProvider.isDarkMode;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 40.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏦', style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 15),
                      Text(
                        "Earn 8.5% APY on your DOGE",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? themeProvider.darkGreyBoxColor
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: isDark
                              ? Border.all(
                                  color: themeProvider.darkGreyBorder,
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.update,
                              size: 20,
                              color: isDark
                                  ? Colors.amber
                                  : Colors.green.shade800,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Interest paid every second",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.amber
                                    : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 4.0,
                            bottom: 8.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.amber.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Available Stakable Balance",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.brown,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 👑 THEMED BALANCE BOX
                      AnimatedHoverCard(
                        backgroundColor: isDark
                            ? themeProvider.darkGreyBoxColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isDark
                              ? themeProvider.darkGreyBorder
                              : Colors.amber.shade300,
                          width: 2,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 20,
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${dogeBalance.toStringAsFixed(8)} DOGE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: isDark ? Colors.amber : Colors.brown,
                                  ),
                                ),
                              ),
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
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 👑 THEMED HARVEST BOX
                      AnimatedHoverCard(
                        backgroundColor: isDark
                            ? themeProvider.darkGreyBoxColor
                            : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: isDark
                            ? Border.all(
                                color: themeProvider.darkGreyBorder,
                                width: 2,
                              )
                            : null,
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(25),
                            child: Column(
                          children: [
                            Text(
                              "Total Staked (Principal)",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.brown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            LiveInterestDisplay(
                              stakedBalance: stakedBalance,
                              stakeTimestamp: stakeTimestamp,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "💡 The more you stake, the faster your yield ticks up!",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.brown,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 35,
                              child: ElevatedButton.icon(
                                onPressed: stakedBalance > 0
                                    ? _harvestInterest
                                    : null,
                                icon: const Icon(
                                  Icons.agriculture,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: const Text(
                                  "HARVEST REWARDS",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                      ),

                      const SizedBox(height: 30),

                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Principal Amount to Stake / Unstake',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : null,
                          ),
                          prefixIcon: const Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: isDark
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white24,
                                  ),
                                )
                              : null,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.amber,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  double amount =
                                      double.tryParse(
                                        _amountController.text.trim(),
                                      ) ??
                                      0.0;
                                  if (amount > 0) {
                                    _stakeDoge(amount);
                                  } else {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please enter a valid amount to stake.",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  "STAKE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  double amount =
                                      double.tryParse(
                                        _amountController.text.trim(),
                                      ) ??
                                      0.0;
                                  if (amount > 0) {
                                    _unstakeDoge(amount);
                                  } else {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please enter a valid amount to unstake.",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.lock_open,
                                  color: isDark
                                      ? Colors.brown.shade900
                                      : Colors.brown,
                                  size: 18,
                                ),
                                label: Text(
                                  "UNSTAKE",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.brown.shade900
                                        : Colors.brown,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.amber
                                      : Colors.amber.shade100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}


