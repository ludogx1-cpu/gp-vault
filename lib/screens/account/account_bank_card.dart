import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../src/firebase_service.dart';
import '../../api_constants.dart';
import '../../widgets/widgets.dart';

class AccountBankCard extends StatefulWidget {
  final bool isDark;
  final double bankBalance;
  final double vaultBalance;
  final double offerwallBalance;

  const AccountBankCard({
    super.key,
    required this.isDark,
    required this.bankBalance,
    required this.vaultBalance,
    required this.offerwallBalance,
  });

  @override
  State<AccountBankCard> createState() => _AccountBankCardState();
}

class _AccountBankCardState extends State<AccountBankCard> {
  final TextEditingController _bankDepositAmountController = TextEditingController();
  final TextEditingController _bankWithdrawAmountController = TextEditingController();
  final TextEditingController _bankTransferAmountController = TextEditingController();
  
  bool _isBankWithdrawing = false;
  bool _isTransferring = false;
  String _bankMessage = "";
  String _transferSource = 'Vault';

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

  Future<void> _processBankWithdrawal() async {
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
    if (amountToWithdraw > widget.bankBalance) {
      setState(() => _bankMessage = "Insufficient Bank Balance.");
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    String savedAddress = prefs.getString('doge_address') ?? "";
    
    if (savedAddress.trim().isEmpty) {
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
            "user_address": savedAddress.trim(),
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
      if (mounted) {
        setState(() => _isBankWithdrawing = false);
      }
    }
  }

  Future<void> _processInternalTransfer() async {
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
    
    if (_transferSource == 'Vault' && amountToTransfer > widget.vaultBalance) {
      setState(() => _bankMessage = "Insufficient Vault Balance.");
      return;
    }
    
    if (_transferSource == 'Offerwall' && amountToTransfer > widget.offerwallBalance) {
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
      if (mounted) {
        setState(() => _isTransferring = false);
      }
    }
  }

  @override
  void dispose() {
    _bankDepositAmountController.dispose();
    _bankWithdrawAmountController.dispose();
    _bankTransferAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      backgroundColor: widget.isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
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
                  Icons.account_balance,
                  color: widget.isDark ? Colors.blue.shade300 : Colors.blue.shade800,
                ),
                const SizedBox(width: 10),
                Text(
                  "Doge Bank Wallet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.black26 : Colors.white60,
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
                        color: widget.isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 20,
              color: widget.isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Stored Balance:",
                  style: TextStyle(
                    color: widget.isDark ? Colors.white70 : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${widget.bankBalance.toStringAsFixed(6)} DOGE",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.blue.shade300 : Colors.blue.shade800,
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
                    style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Min 1 DOGE",
                      hintStyle: const TextStyle(color: Colors.grey),
                      labelText: "Deposit Amount",
                      labelStyle: TextStyle(color: widget.isDark ? Colors.blue.shade200 : Colors.blue.shade800),
                      prefixIcon: const Icon(Icons.arrow_downward, color: Colors.green),
                      filled: true,
                      fillColor: widget.isDark ? Colors.grey.shade800 : Colors.white,
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
                    style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Min 1 DOGE",
                      hintStyle: const TextStyle(color: Colors.grey),
                      labelText: "Withdraw Amount",
                      labelStyle: TextStyle(color: widget.isDark ? Colors.amber.shade200 : Colors.amber.shade800),
                      prefixIcon: const Icon(Icons.arrow_upward, color: Colors.orange),
                      filled: true,
                      fillColor: widget.isDark ? Colors.grey.shade800 : Colors.white,
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
                    onPressed: _isBankWithdrawing ? null : _processBankWithdrawal,
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
                    color: widget.isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _transferSource,
                      dropdownColor: widget.isDark ? Colors.grey.shade800 : Colors.white,
                      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
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
                    style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Transfer Amount",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: widget.isDark ? Colors.grey.shade800 : Colors.white,
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
                    onPressed: _isTransferring ? null : _processInternalTransfer,
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
  }
}
