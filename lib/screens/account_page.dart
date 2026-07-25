import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../src/user_provider.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';
import '../api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/universal_web_view/universal_web_view.dart';

// --- GLOBAL THEME CONSTANTS 🚀 ---

// --- CAPTCHA JS BINDINGS ---

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
  final TextEditingController _bankDepositAmountController =
      TextEditingController();
  final TextEditingController _bankWithdrawAmountController =
      TextEditingController();
  final TextEditingController _bankTransferAmountController =
      TextEditingController();
  final TextEditingController _usernameController =
      TextEditingController();
      
  bool _isWithdrawing = false;
  bool _isBankWithdrawing = false;
  bool _isTransferring = false;
  
  String _withdrawMessage = "";
  String _bankMessage = "";
  String _usernameMessage = "";
  bool _isSettingUsername = false;
  
  String _transferSource = 'Vault';
  
  final bool _twoFactorEnabled = false;
  int _historyPage = 0;

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
    if (amountToWithdraw < 1.0) {
      setState(() => _withdrawMessage = "Minimum withdrawal is 1 DOGE.");
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
          Uri.parse('${ApiConstants.baseUrl}/withdraw'),
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

  void _depositToBank() {
    final user = FirebaseAuth.instance.currentUser;
    String amount = _bankDepositAmountController.text.trim();

    if (user != null && amount.isNotEmpty) {
      final uri = Uri.parse(
        'https://faucetpay.io/merchant/webscr'
        '?merchant_username=ludogx1'
        '&item_description=Golden+Paw+Bank+Balance'
        '&amount1=$amount'
        '&currency1=DOGE'
        '&custom=${user.uid}'
        '&callback_url=${Uri.encodeComponent('${ApiConstants.baseUrl}/ipn')}'
      );
      launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _bankDepositAmountController.clear());
    }
  }

  Future<void> _processBankWithdrawal(double maxBalance) async {
    double? amountToWithdraw = double.tryParse(
      _bankWithdrawAmountController.text.trim(),
    );
    if (amountToWithdraw == null) {
      setState(() => _bankMessage = "Please enter a valid number.");
      return;
    }
    if (amountToWithdraw < 1.0) {
      setState(() => _bankMessage = "Minimum withdrawal is 1 DOGE.");
      return;
    }
    if (amountToWithdraw > maxBalance) {
      setState(() => _bankMessage = "Insufficient Bank Balance.");
      return;
    }
    if (_withdrawAddressController.text.trim().isEmpty) {
      setState(
        () => _bankMessage = "Please enter a FaucetPay Dogecoin address above.",
      );
      return;
    }

    setState(() {
      _isBankWithdrawing = true;
      _bankMessage = "Processing bank withdrawal...";
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/bank/withdraw'),
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
            _bankMessage = "Success! $amountToWithdraw DOGE sent to FaucetPay.";
            _bankWithdrawAmountController.clear();
          });
        } else {
          try {
            final errorData = jsonDecode(response.body);
            setState(() {
              _bankMessage = "Declined: ${errorData['error'] ?? 'Unknown error'}";
            });
          } catch (_) {
            setState(() {
              _bankMessage = "Server Error. Try again in a few mins!";
            });
          }
        }
      }
    } catch (e) {
      setState(() => _bankMessage = "Bug: $e");
    } finally {
      setState(() => _isBankWithdrawing = false);
    }
  }

  Future<void> _processInternalTransfer(double vaultBal, double offerwallBal) async {
    double? amountToTransfer = double.tryParse(
      _bankTransferAmountController.text.trim(),
    );
    if (amountToTransfer == null) {
      setState(() => _bankMessage = "Please enter a valid transfer amount.");
      return;
    }
    if (amountToTransfer <= 0.0) {
      setState(() => _bankMessage = "Transfer amount must be greater than 0.");
      return;
    }
    
    if (_transferSource == 'Vault' && amountToTransfer > vaultBal) {
      setState(() => _bankMessage = "Insufficient Vault Balance.");
      return;
    }
    
    if (_transferSource == 'Offerwall' && amountToTransfer > offerwallBal) {
      setState(() => _bankMessage = "Insufficient Offerwall Balance.");
      return;
    }

    setState(() {
      _isTransferring = true;
      _bankMessage = "Processing transfer...";
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/bank/transfer'),
          headers: await getAuthHeaders(),
          body: jsonEncode({
            "source": _transferSource.toLowerCase(),
            "amount": amountToTransfer,
          }),
        );

        if (!mounted) {
          return;
        }

        if (response.statusCode == 200) {
          setState(() {
            _bankMessage = "Success! $amountToTransfer DOGE transferred to Bank.";
            _bankTransferAmountController.clear();
          });
        } else {
          try {
            final errorData = jsonDecode(response.body);
            setState(() {
              _bankMessage = "Failed: ${errorData['error'] ?? 'Unknown error'}";
            });
          } catch (_) {
            setState(() {
              _bankMessage = "Server Error. Try again later.";
            });
          }
        }
      }
    } catch (e) {
      setState(() => _bankMessage = "Bug: $e");
    } finally {
      setState(() => _isTransferring = false);
    }
  }



  Widget _buildHistoryBox(
    BuildContext context,
    Map<String, dynamic>? userData,
    bool isDark,
  ) {
    List<dynamic> history = userData?['reward_history'] ?? [];

    return AnimatedHoverCard(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: isDark ? Colors.grey.shade700 : Colors.amber.shade300,
        width: 1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: isDark ? Colors.amber : Colors.black87,
                ),
                const SizedBox(width: 10),
                Text(
                  "Latest Rewards History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Divider(
              height: 20,
              color: isDark
                  ? Colors.amber.withValues(alpha: 0.3)
                  : Colors.amber.shade100,
            ),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "No rewards yet. Start earning!",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              )
            else ...[
              Builder(
                builder: (context) {
                  final int itemsPerPage = 10;
                  final int totalPages = (history.length / itemsPerPage).ceil();

                  // Ensure page is within bounds
                  if (_historyPage >= totalPages) {
                    _historyPage = totalPages - 1;
                    if (_historyPage < 0) _historyPage = 0;
                  }

                  final int startIndex = _historyPage * itemsPerPage;
                  final int endIndex =
                      (startIndex + itemsPerPage > history.length)
                      ? history.length
                      : startIndex + itemsPerPage;
                  final List<dynamic> currentHistory = history.sublist(
                    startIndex,
                    endIndex,
                  );

                  return Column(
                    children: [
                      ...currentHistory.map((item) {
                        final sectorRaw = item['sector']?.toString() ?? 'Unknown';
                        final sector = sectorRaw.replaceAll('\n', ' ');
                        
                        String amountStr = '0.0';
                        final amt = item['amount'];
                        if (amt != null) {
                          final doubleVal = double.tryParse(amt.toString());
                          if (doubleVal != null) {
                            amountStr = doubleVal.toStringAsFixed(8).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
                          } else {
                            amountStr = amt.toString();
                          }
                        }
                        final ts = item['timestamp'] as int?;
                        String timeStr = 'Unknown Date';
                        if (ts != null) {
                          final date = DateTime.fromMillisecondsSinceEpoch(ts);
                          final ampm = date.hour >= 12 ? 'PM' : 'AM';
                          final hour12 = date.hour % 12 == 0
                              ? 12
                              : date.hour % 12;
                          timeStr =
                              '${date.month}/${date.day}/${date.year} at $hour12:${date.minute.toString().padLeft(2, '0')} $ampm';
                        }

                        IconData icon;
                        if (sector.contains('Faucet')) {
                          icon = Icons.water_drop;
                        } else if (sector.contains('PTC')) {
                          icon = Icons.ads_click;
                        } else if (sector.contains('Pet')) {
                          icon = Icons.pets;
                        } else if (sector.contains('Offer')) {
                          icon = Icons.card_giftcard;
                        } else {
                          icon = Icons.monetization_on;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.amber.withValues(
                                  alpha: 0.2,
                                ),
                                child: Icon(icon, color: Colors.amber, size: 20),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sector,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: isDark ? Colors.white54 : Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+$amountStr DOGE',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
              if ((history.length / 10).ceil() > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _historyPage > 0
                            ? () => setState(() => _historyPage--)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Prev'),
                      ),
                      Text(
                        'Page ${_historyPage + 1} of ${(history.length / 10).ceil()}',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _historyPage < (history.length / 10).ceil() - 1
                            ? () => setState(() => _historyPage++)
                            : null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Next'),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _processSetUsername() async {
    final name = _usernameController.text.trim();
    if (name.length < 3 || name.length > 15) {
      setState(() => _usernameMessage = "Username must be 3-15 chars.");
      return;
    }

    setState(() {
      _isSettingUsername = true;
      _usernameMessage = "Saving...";
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/set-username'),
        headers: await getAuthHeaders(),
        body: jsonEncode({"username": name}),
      );

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() => _usernameMessage = "Username saved successfully!");
      } else {
        setState(() => _usernameMessage = resData['error'] ?? "Failed to save username.");
      }
    } catch (e) {
      setState(() => _usernameMessage = "Connection error.");
    } finally {
      setState(() => _isSettingUsername = false);
    }
  }

  Widget _buildProfileCard(BuildContext context, bool isDark, String currentUsername) {
    if (currentUsername != "Anonymous" && _usernameController.text.isEmpty) {
      _usernameController.text = currentUsername;
    }
    
    return AnimatedHoverCard(
      backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: gpBrownText(context), size: 30),
                const SizedBox(width: 15),
                Text(
                  "Profile Username",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: gpBrownText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              "Set a global username for the Leaderboard and Community Chat. You can only change this once every 3 months.",
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              maxLength: 15,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                counterText: "",
                labelText: "Username",
                hintText: currentUsername == "Anonymous" ? "Enter a username" : currentUsername,
                labelStyle: TextStyle(color: Colors.amber.shade700),
                prefixIcon: const Icon(Icons.badge, color: Colors.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 15),
            if (_usernameMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  _usernameMessage,
                  style: TextStyle(
                    color: _usernameMessage.contains("success")
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isSettingUsername ? null : _processSetUsername,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              icon: _isSettingUsername
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSettingUsername ? "Saving..." : "Update Username",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = themeProvider.isDarkMode;

    return AppScaffold(
      appBar: const GlobalAppBar(),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = FirebaseAuth.instance.currentUser;
          return Stack(
            children: [
              PageWithFooter(
                child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
              padding: const EdgeInsets.all(20.0),
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
                  const SizedBox(height: 10),
                  const BitcotasksAdWidget(),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/Goldenpawicon.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
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
                                          : Colors.black87,
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
                                          : Colors.black87,
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
                        child: Text(
                          "LOG IN",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
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
                          currentBalance = (userData['doge_balance'] ?? 0.0)
                              .toDouble();
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
                            _buildProfileCard(context, isDark, userData?['username'] ?? userData?['chat_username'] ?? 'Anonymous'),
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
                                                  : Colors.black87,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "Withdraw to FaucetPay",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
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
                                          "Minimum Withdrawal: 1 DOGE",
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
                                                : Text(
                                                    "WITHDRAW NOW",
                                                    style: TextStyle(
                                                      color: Colors.white,
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
                            ListenableBuilder(
                              listenable: themeProvider,
                              builder: (context, _) {
                                final isDark = themeProvider.isDarkMode;
                                final double bankBalance = (userData?['bank_balance'] ?? 0.0).toDouble();
                                return AnimatedHoverCard(
                                  backgroundColor: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isDark ? Colors.blue.shade700 : Colors.blue.shade300,
                                    width: 1,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.account_balance,
                                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "Doge Bank Wallet",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.black26 : Colors.white60,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  "This balance is for storage only. It cannot be used for staking or ads.",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? Colors.white70 : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          height: 20,
                                          color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Stored Balance:",
                                              style: TextStyle(
                                                color: isDark ? Colors.white70 : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "${bankBalance.toStringAsFixed(6)} DOGE",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _bankDepositAmountController,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                                decoration: InputDecoration(
                                                  hintText: "Min 1 DOGE",
                                                  hintStyle: const TextStyle(color: Colors.grey),
                                                  labelText: "Deposit Amount",
                                                  labelStyle: TextStyle(color: isDark ? Colors.blue.shade200 : Colors.blue.shade800),
                                                  prefixIcon: const Icon(Icons.arrow_downward, color: Colors.green),
                                                  filled: true,
                                                  fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.5)),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              height: 55,
                                              child: ElevatedButton(
                                                onPressed: _depositToBank,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                child: const Text(
                                                  "DEPOSIT",
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _bankWithdrawAmountController,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                                decoration: InputDecoration(
                                                  hintText: "Min 1 DOGE",
                                                  hintStyle: const TextStyle(color: Colors.grey),
                                                  labelText: "Withdraw Amount",
                                                  labelStyle: TextStyle(color: isDark ? Colors.amber.shade200 : Colors.amber.shade800),
                                                  prefixIcon: const Icon(Icons.arrow_upward, color: Colors.orange),
                                                  filled: true,
                                                  fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              height: 55,
                                              child: ElevatedButton(
                                                onPressed: _isBankWithdrawing ? null : () => _processBankWithdrawal(bankBalance),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                child: _isBankWithdrawing
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                      )
                                                    : const Text(
                                                        "WITHDRAW",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: _transferSource,
                                                  dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                                  items: <String>['Vault', 'Offerwall'].map((String value) {
                                                    return DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged: (String? newValue) {
                                                    if (newValue != null) {
                                                      setState(() {
                                                        _transferSource = newValue;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                controller: _bankTransferAmountController,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                                decoration: InputDecoration(
                                                  hintText: "Transfer Amount",
                                                  hintStyle: const TextStyle(color: Colors.grey),
                                                  filled: true,
                                                  fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: BorderSide(color: Colors.purple.withValues(alpha: 0.5)),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    borderSide: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              height: 55,
                                              child: ElevatedButton(
                                                onPressed: _isTransferring
                                                    ? null
                                                    : () => _processInternalTransfer(
                                                          (userData?['doge_balance'] ?? 0.0).toDouble(),
                                                          (userData?['offerwall_balance'] ?? 0.0).toDouble(),
                                                        ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.purple,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                child: _isTransferring
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                      )
                                                    : const Text(
                                                        "TRANSFER",
                                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Note: This transfers your available earnings FROM your Vault or Offerwall INTO your Bank Wallet.",
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        if (_bankMessage.isNotEmpty) ...[
                                          const SizedBox(height: 15),
                                          Center(
                                            child: Text(
                                              _bankMessage,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _bankMessage.contains("Success") ? Colors.green : Colors.red,
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
                            _buildHistoryBox(context, userData, isDark),
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
                  const SizedBox(height: 30),
                  const PwaInstallWidget(),
                  const SizedBox(height: 30),
                  const EnableNotificationsWidget(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
              ),
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

// ==========================================
// 🌟 THE AD HUB & DEPOSIT PAGE 🌟
// ==========================================

