import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../src/theme_provider.dart';
import '../src/user_provider.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';
import '../api_constants.dart';
import 'ads/deposit_dialog.dart';
import 'ads/buy_banner_dialog.dart';
import 'ads/buy_ptc_ad_dialog.dart';
import 'ads/widgets/ad_hub_cards.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class AdHubPage extends StatefulWidget {
  const AdHubPage({super.key});

  @override
  State<AdHubPage> createState() => _AdHubPageState();
}

class _AdHubPageState extends State<AdHubPage> {
  final TextEditingController _swapAmountController = TextEditingController();
  bool _isSwapping = false;

  Future<void> _swapDogeToUsdt() async {
    double? amount = double.tryParse(_swapAmountController.text);
    if (amount == null || amount <= 0) {
      return;
    }

    setState(() => _isSwapping = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/swap-doge'),
        headers: await getAuthHeaders(),
        body: jsonEncode({'amount': amount}),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Swap Successful! 💸",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _swapAmountController.clear();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${error['error']}")));
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Swap failed. Server busy!")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSwapping = false);
      }
    }
  }

  void _showDepositDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dContext) => const DepositDialog(),
    );
  }

  void _buyAd(
    double currentAdsBalance,
    String docId,
    String title,
    double defaultCost,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dContext) => BuyBannerDialog(
        currentAdsBalance: currentAdsBalance,
        docId: docId,
        title: title,
        defaultCost: defaultCost,
      ),
    );
  }

  void _buyPtcAd(double currentAdsBalance) {
    showDialog(
      context: context,
      builder: (BuildContext dContext) => BuyPtcAdDialog(
        currentAdsBalance: currentAdsBalance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    "Log in to buy Ads!",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: const Text(
                      "Go Back",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
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
          double adsBalance = (userData['ads_balance'] ?? 0.0).toDouble();
          double dogeBalance = (userData['doge_balance'] ?? 0.0).toDouble();

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
                      CampaignCard(
                        isDark: isDark,
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 20),
                      VaultSwapCard(
                        isDark: isDark,
                        themeProvider: themeProvider,
                        dogeBalance: dogeBalance,
                        swapAmountController: _swapAmountController,
                        isSwapping: _isSwapping,
                        onSwap: _swapDogeToUsdt,
                      ),
                      const SizedBox(height: 20),
                      DepositWarningCard(
                        isDark: isDark,
                        themeProvider: themeProvider,
                      ),
                      const SizedBox(height: 20),
                      AdBalanceCard(
                        isDark: isDark,
                        themeProvider: themeProvider,
                        adsBalance: adsBalance,
                        onDeposit: _showDepositDialog,
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Ad Store",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      AdStoreList(
                        isDark: isDark,
                        themeProvider: themeProvider,
                        adsBalance: adsBalance,
                        onBuyAd: _buyAd,
                        onBuyPtcAd: _buyPtcAd,
                      ),
                      const SizedBox(height: 40),
                      const Bitcotasks300x250AdWidget(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// ✨ MULTI-TIER PTC EARN PAGE
// ==========================================


