import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../src/user_provider.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';
import '../api_constants.dart';
import '../widgets/universal_web_view/universal_web_view.dart';
import 'staking/widgets/staking_header.dart';
import 'staking/widgets/harvest_card.dart';
import 'staking/widgets/staking_form.dart';


// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






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
  bool _isProcessing = false;

  Future<void> _harvestInterest() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/harvest'),
        headers: await getAuthHeaders(),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? "Successfully Harvested Interest! 🌾",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Server error');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _stakeDoge(double amountToStake) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/stake'),
        headers: await getAuthHeaders(),
        body: jsonEncode({'amount': amountToStake}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? "Successfully staked $amountToStake DOGE! 🐾",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _amountController.clear();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Server error');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vault Error: ${e.toString().replaceAll("Exception: ", "")}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _unstakeDoge(double amountToUnstake) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/unstake'),
        headers: await getAuthHeaders(),
        body: jsonEncode({'amount': amountToUnstake}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? "Successfully unstaked $amountToUnstake DOGE! 🔓",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue,
          ),
        );
        _amountController.clear();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Server error');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vault Error: ${e.toString().replaceAll("Exception: ", "")}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
                      color: Colors.black87,
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

          return Stack(
            children: [
              PageWithFooter(
                // 👑 Wrapped the main padding layout in ListenableBuilder
            child: ListenableBuilder(
              listenable: themeProvider,
              builder: (context, _) {
                final isDark = themeProvider.isDarkMode;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 40.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (kIsWeb)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 728,
                            height: 90,
                            child: UniversalWebView.create(viewType: 'adsterra-728x90', width: 728, height: 90),
                          ),
                        ),
                      if (kIsWeb) const SizedBox(height: 20),
                      if (kIsWeb) const BitcotasksAdWidget(),
                      if (kIsWeb) const SizedBox(height: 20),
                      StakingHeader(
                        isDark: isDark,
                        themeProvider: themeProvider,
                        dogeBalance: dogeBalance,
                      ),
                      const SizedBox(height: 25),
                      HarvestCard(
                        stakedBalance: stakedBalance,
                        stakeTimestamp: stakeTimestamp,
                        isDark: isDark,
                        themeProvider: themeProvider,
                        onHarvest: _harvestInterest,
                      ),
                      const SizedBox(height: 40),
                      StakingForm(
                        amountController: _amountController,
                        isProcessing: _isProcessing,
                        isDark: isDark,
                        onStake: _stakeDoge,
                        onUnstake: _unstakeDoge,
                        context: context,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
            ),
          ),
          if (MediaQuery.of(context).size.width >= 1000) ...[
            Positioned(
              left: ((MediaQuery.of(context).size.width - 800) / 2 - 160) / 2,
              top: 100,
              width: 160,
              height: 600,
              child: UniversalWebView.create(viewType: 'adsterra-160x600', width: 160, height: 600),
            ),
            Positioned(
              right: ((MediaQuery.of(context).size.width - 800) / 2 - 160) / 2,
              top: 100,
              width: 160,
              height: 300,
              child: UniversalWebView.create(viewType: 'adsterra-160x300', width: 160, height: 300),
            ),
          ],
        ],
      );
        },
      ),
    );
  }
}



