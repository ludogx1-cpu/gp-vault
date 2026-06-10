import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../src/theme_provider.dart';
import '../src/user_provider.dart';
import 'create_ad_page.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';
import '../api_constants.dart';




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
  final TextEditingController _depositAmountController =
      TextEditingController();
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
    double? amount = double.tryParse(_swapAmountController.text);
    if (amount == null || amount <= 0) {
      return;
    }

    setState(() => _isSwapping = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + '/swap-doge'),
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
      builder: (BuildContext dContext) {
        return AlertDialog(
          title: const Text(
            "Deposit USDT",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter the amount of Tether (USDT) you want to deposit.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _depositAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Amount (USDT)",
                  prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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

                  htmlForm.append(
                    _createHiddenInput('merchant_username', 'ludogx1'),
                  );
                  htmlForm.append(
                    _createHiddenInput(
                      'item_description',
                      'Golden Paw Ad Balance',
                    ),
                  );
                  htmlForm.append(_createHiddenInput('amount1', amount));
                  htmlForm.append(_createHiddenInput('currency1', 'USDT'));
                  htmlForm.append(_createHiddenInput('custom', user.uid));
                  htmlForm.append(
                    _createHiddenInput(
                      'callback_url',
                      ApiConstants.baseUrl + '/ipn',
                    ),
                  );

                  web.document.body!.append(htmlForm);
                  htmlForm.submit();
                  htmlForm.remove();

                  if (dContext.mounted) {
                    Navigator.pop(dContext);
                  }
                }
              },
              child: const Text(
                "PAY WITH FAUCETPAY",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _buyAd(
    double currentAdsBalance,
    String docId,
    String title,
    double defaultCost,
  ) {
    final imgCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (BuildContext dContext) => StatefulBuilder(
        builder: (dContext, setDialogState) => AlertDialog(
          title: Text(
            "Buy $title",
            style: const TextStyle(
              color: Colors.brown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Cost: \$${defaultCost.toStringAsFixed(2)} USDT",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imgCtrl,
                decoration: const InputDecoration(labelText: "Image URL"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: targetCtrl,
                decoration: const InputDecoration(
                  labelText: "Target Link (URL)",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: loading
                  ? null
                  : () async {
                      if (currentAdsBalance < defaultCost) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Insufficient Ad Balance! Need \$${defaultCost.toStringAsFixed(2)}",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                      if (targetCtrl.text.isEmpty || imgCtrl.text.isEmpty) {
                        return;
                      }

                      setDialogState(() => loading = true);

                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final response = await http.post(
                          Uri.parse(
                            ApiConstants.baseUrl + '/buy-banner',
                          ),
                          headers: await getAuthHeaders(),
                          body: jsonEncode({
                            'doc_id': docId,
                            'image_url': imgCtrl.text.trim(),
                            'target_url': targetCtrl.text.trim(),
                          }),
                        );

                        if (!context.mounted) {
                          return;
                        }

                        if (response.statusCode == 200) {
                          if (dContext.mounted) {
                            Navigator.pop(dContext);
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Ad Campaign Successfully Launched! 🚀",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          throw "Server returned error";
                        }
                      } catch (e) {
                        setDialogState(() => loading = false);
                        if (context.mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      }
                    },
              child: Text(
                loading ? "Processing..." : "PURCHASE",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _buyPtcAd(double currentAdsBalance) {
    final targetCtrl = TextEditingController();
    bool loading = false;
    int selectedTier = 1;
    int selectedClicks = 100;

    Map<int, double> costs = {1: 0.25, 2: 0.50, 3: 0.75, 4: 1.50};
    Map<int, String> labels = {
      1: "10 Seconds",
      2: "20 Seconds",
      3: "30 Seconds",
      4: "60 Seconds",
    };
    List<int> clickOptions = [100, 200, 300, 500, 1000];

    showDialog(
      context: context,
      builder: (BuildContext dContext) => StatefulBuilder(
        builder: (dContext, setDialogState) {
          double totalCost = costs[selectedTier]! * (selectedClicks / 100);

          return AlertDialog(
            title: const Text(
              "Buy Guaranteed PTC Clicks",
              style: TextStyle(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Total Cost: \$${totalCost.toStringAsFixed(2)} USDT",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  initialValue: selectedTier,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Select View Duration",
                  ),
                  items: [1, 2, 3, 4]
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            "${labels[t]} (+\$${costs[t]!.toStringAsFixed(2)} per 100)",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedTier = val);
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  initialValue: selectedClicks,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Number of Clicks",
                  ),
                  items: clickOptions
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            "$c Guaranteed Views",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedClicks = val);
                  },
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: targetCtrl,
                  decoration: const InputDecoration(
                    labelText: "Target Link (URL)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: loading
                    ? null
                    : () async {
                        if (currentAdsBalance < totalCost) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Insufficient Balance! Need \$${totalCost.toStringAsFixed(2)}",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                        if (targetCtrl.text.isEmpty) {
                          return;
                        }

                        setDialogState(() => loading = true);

                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          final response = await http.post(
                            Uri.parse(
                              ApiConstants.baseUrl + '/buy-ptc',
                            ),
                            headers: await getAuthHeaders(),
                            body: jsonEncode({
                              'target_url': targetCtrl.text.trim(),
                              'tier': selectedTier,
                              'clicks': selectedClicks,
                            }),
                          );

                          if (!context.mounted) {
                            return;
                          }

                          if (response.statusCode == 200) {
                            if (dContext.mounted) {
                              Navigator.pop(dContext);
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("PTC Ad added to pool! 🚀"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            final err = jsonDecode(response.body);
                            throw err['error'];
                          }
                        } catch (e) {
                          setDialogState(() => loading = false);
                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      },
                child: Text(
                  loading
                      ? "Processing..."
                      : "PAY \$${totalCost.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      color: Colors.brown,
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
                        color: Colors.brown,
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? themeProvider.darkGreyBoxColor
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isDark
                                ? themeProvider.darkGreyBorder
                                : Colors.orange.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Ready to Promote?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CreateAdPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.rocket_launch,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "LAUNCH NEW CAMPAIGN",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? themeProvider.darkGreyBoxColor
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isDark
                                ? themeProvider.darkGreyBorder
                                : Colors.amber.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swap_horizontal_circle,
                                  color: isDark
                                      ? Colors.amber
                                      : Colors.brown,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Instant Vault Swap",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.brown,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Balance: ${dogeBalance.toStringAsFixed(4)} DOGE",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.amber.shade200
                                    : Colors.brown,
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _swapAmountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: "DOGE to Convert",
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white70 : null,
                                ),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                enabledBorder: isDark
                                    ? const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white24,
                                        ),
                                      )
                                    : null,
                                hintText: "1.0",
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white30 : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "⚠️ Includes a tiny 1% exchange fee",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSwapping
                                    ? null
                                    : _swapDogeToUsdt,
                                icon: const Icon(Icons.bolt),
                                label: Text(
                                  _isSwapping
                                      ? "Converting..."
                                      : "SWAP FOR AD CREDIT",
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.amber
                                      : Colors.brown,
                                  foregroundColor: isDark
                                      ? Colors.white
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? themeProvider.darkGreyBoxColor
                              : Colors.red.shade50,
                          border: Border.all(
                            color: isDark
                                ? Colors.red.shade900
                                : Colors.red.shade200,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 30,
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                "IMPORTANT: Funds deposited here are strictly for purchasing advertising. They CANNOT be staked, transferred, or withdrawn back to FaucetPay.",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? themeProvider.darkGreyBoxColor
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isDark
                                ? themeProvider.darkGreyBorder
                                : Colors.green.shade200,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Advertising Balance",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "\$${adsBalance.toStringAsFixed(2)} USDT",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.green.shade300
                                    : Colors.green.shade900,
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showDepositDialog,
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "DEPOSIT USDT",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Ad Store",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.brown,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      AnimatedHoverCard(
                        backgroundColor: isDark
                            ? themeProvider.darkGreyBoxColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: isDark
                            ? Border.all(color: themeProvider.darkGreyBorder)
                            : null,
                        child: ListTile(
                          leading: const Icon(
                            Icons.image,
                            color: Colors.purple,
                            size: 30,
                          ),
                          title: Text(
                            "Global Top Banner",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                          subtitle: Text(
                            "Top of Faucet page (7 Days).",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : null,
                            ),
                          ),
                          trailing: const Text(
                            "\$3.50",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () => _buyAd(
                            adsBalance,
                            'global_banner',
                            'Global Banner',
                            3.5,
                          ),
                        ),
                      ),
                      AnimatedHoverCard(
                        backgroundColor: isDark
                            ? themeProvider.darkGreyBoxColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: isDark
                            ? Border.all(color: themeProvider.darkGreyBorder)
                            : null,
                        child: ListTile(
                          leading: const Icon(
                            Icons.check_box_outline_blank,
                            color: Colors.blue,
                            size: 30,
                          ),
                          title: Text(
                            "Square Ad (Left)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                          subtitle: Text(
                            "Next to Claim Button (7 Days).",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : null,
                            ),
                          ),
                          trailing: const Text(
                            "\$1.75",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () => _buyAd(
                            adsBalance,
                            'square_left',
                            'Left Square Ad',
                            1.75,
                          ),
                        ),
                      ),
                      AnimatedHoverCard(
                        backgroundColor: isDark
                            ? themeProvider.darkGreyBoxColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: isDark
                            ? Border.all(color: themeProvider.darkGreyBorder)
                            : null,
                        child: ListTile(
                          leading: const Icon(
                            Icons.check_box_outline_blank,
                            color: Colors.blue,
                            size: 30,
                          ),
                          title: Text(
                            "Square Ad (Right)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                          subtitle: Text(
                            "Next to Claim Button (7 Days).",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : null,
                            ),
                          ),
                          trailing: const Text(
                            "\$1.75",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () => _buyAd(
                            adsBalance,
                            'square_right',
                            'Right Square Ad',
                            1.75,
                          ),
                        ),
                      ),
                      AnimatedHoverCard(
                        backgroundColor: isDark
                            ? themeProvider.darkGreyBoxColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: isDark
                            ? Border.all(color: themeProvider.darkGreyBorder)
                            : null,
                        child: ListTile(
                          leading: const Icon(
                            Icons.ad_units,
                            color: Colors.red,
                            size: 30,
                          ),
                          title: Text(
                            "Interstitial Pop-up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                          subtitle: Text(
                            "Shows during claim loading (7 Days).",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : null,
                            ),
                          ),
                          trailing: const Text(
                            "\$7.00",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () => _buyAd(
                            adsBalance,
                            'interstitial',
                            'Interstitial Pop-up',
                            7.0,
                          ),
                        ),
                      ),
                      AnimatedHoverCard(
                        backgroundColor: isDark
                            ? themeProvider.darkGreyBoxColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: isDark
                            ? Border.all(color: themeProvider.darkGreyBorder)
                            : null,
                        child: ListTile(
                          leading: const Icon(
                            Icons.ads_click,
                            color: Colors.orange,
                            size: 30,
                          ),
                          title: Text(
                            "Buy PTC Clicks",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                          subtitle: Text(
                            "Select your duration & volume.",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : null,
                            ),
                          ),
                          trailing: const Text(
                            "Custom",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () => _buyPtcAd(adsBalance),
                        ),
                      ),
                      const SizedBox(height: 40),
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

