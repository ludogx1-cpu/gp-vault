import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../src/firebase_service.dart';
import '../../api_constants.dart';
import '../../widgets/widgets.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AccountWithdrawCard extends StatefulWidget {
  final bool isDark;
  final double currentBalance;

  const AccountWithdrawCard({
    super.key,
    required this.isDark,
    required this.currentBalance,
  });

  @override
  State<AccountWithdrawCard> createState() => _AccountWithdrawCardState();
}

class _AccountWithdrawCardState extends State<AccountWithdrawCard> {
  final TextEditingController _withdrawAddressController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController();
  
  bool _isWithdrawing = false;
  String _withdrawMessage = "";

  @override
  void initState() {
    super.initState();
    _loadSavedInfo();
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedAddress = prefs.getString('doge_address');
    if (savedAddress != null && mounted) {
      setState(() {
        _withdrawAddressController.text = savedAddress;
      });
    }
  }

  Future<void> _processWithdrawal() async {
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
    if (amountToWithdraw > widget.currentBalance) {
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
          FirebaseAnalytics.instance.logEvent(
            name: 'withdrawal_success',
            parameters: {'amount': amountToWithdraw},
          );
          setState(() {
            _withdrawMessage = "Success! $amountToWithdraw DOGE sent to FaucetPay.";
            _withdrawAmountController.clear();
          });
        } else {
          try {
            final errorData = jsonDecode(response.body);
            setState(() {
              _withdrawMessage = "Declined: ${errorData['error'] ?? 'Unknown error'}";
            });
          } catch (_) {
            setState(() {
              _withdrawMessage = "Server Error ${response.statusCode}: The server is still updating. Try again in a few mins!";
            });
          }
        }
      }
    } catch (e) {
      setState(() => _withdrawMessage = "Bug: $e");
    } finally {
      if (mounted) {
        setState(() => _isWithdrawing = false);
      }
    }
  }

  @override
  void dispose() {
    _withdrawAddressController.dispose();
    _withdrawAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      backgroundColor: widget.isDark ? Colors.grey.shade900 : Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.amber,
        width: 0.5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.outbound,
                  color: widget.isDark ? Colors.amber : Colors.black87,
                ),
                const SizedBox(width: 10),
                Text(
                  "Withdraw to FaucetPay",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Divider(
              height: 20,
              color: widget.isDark ? Colors.amber.withValues(alpha: 0.3) : Colors.grey,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Available to Withdraw:",
                  style: TextStyle(
                    color: widget.isDark ? Colors.white70 : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${widget.currentBalance.toStringAsFixed(8)} DOGE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.amber : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              "Minimum Withdrawal: 1 DOGE",
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark ? Colors.white60 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _withdrawAddressController,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
              ),
              onChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                  'doge_address',
                  value.trim(),
                );
              },
              decoration: InputDecoration(
                labelText: "FaucetPay Dogecoin Address",
                labelStyle: TextStyle(
                  color: widget.isDark ? Colors.white70 : Colors.black87,
                ),
                prefixIcon: const Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _withdrawAmountController,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Amount (DOGE)",
                labelStyle: TextStyle(
                  color: widget.isDark ? Colors.white70 : Colors.black87,
                ),
                prefixIcon: const Icon(
                  Icons.monetization_on,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _isWithdrawing ? null : _processWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isWithdrawing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "WITHDRAW NOW",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                    color: _withdrawMessage.contains("Success") ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
