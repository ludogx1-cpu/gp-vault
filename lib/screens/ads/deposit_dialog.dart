import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api_constants.dart';

class DepositDialog extends StatefulWidget {
  const DepositDialog({super.key});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final TextEditingController _depositAmountController = TextEditingController();

  @override
  void dispose() {
    _depositAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            String amount = _depositAmountController.text.trim();

            if (user != null && amount.isNotEmpty) {
              final uri = Uri.parse(
                'https://faucetpay.io/merchant/webscr'
                '?merchant_username=ludogx1'
                '&item_description=Golden+Paw+Ad+Balance'
                '&amount1=$amount'
                '&currency1=USDT'
                '&custom=${user.uid}'
                '&callback_url=${Uri.encodeComponent('${ApiConstants.baseUrl}/ipn')}'
              );
              launchUrl(uri, mode: LaunchMode.externalApplication);

              if (context.mounted) {
                Navigator.pop(context);
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
  }
}
