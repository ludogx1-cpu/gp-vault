import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_constants.dart';
import '../../src/firebase_service.dart';

class BuyBannerDialog extends StatefulWidget {
  final double currentAdsBalance;
  final String docId;
  final String title;
  final double defaultCost;

  const BuyBannerDialog({
    super.key,
    required this.currentAdsBalance,
    required this.docId,
    required this.title,
    required this.defaultCost,
  });

  @override
  State<BuyBannerDialog> createState() => _BuyBannerDialogState();
}

class _BuyBannerDialogState extends State<BuyBannerDialog> {
  final TextEditingController _imgCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _imgCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Buy ${widget.title}",
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Cost: \$${widget.defaultCost.toStringAsFixed(2)} USDT",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _imgCtrl,
            decoration: const InputDecoration(labelText: "Image URL"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _targetCtrl,
            decoration: const InputDecoration(
              labelText: "Target Link (URL)",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: _loading
              ? null
              : () async {
                  if (widget.currentAdsBalance < widget.defaultCost) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Insufficient Ad Balance! Need \$${widget.defaultCost.toStringAsFixed(2)}",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  if (_targetCtrl.text.isEmpty || _imgCtrl.text.isEmpty) {
                    return;
                  }

                  setState(() => _loading = true);

                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    final response = await http.post(
                      Uri.parse(
                        '${ApiConstants.baseUrl}/buy-banner',
                      ),
                      headers: await getAuthHeaders(),
                      body: jsonEncode({
                        'doc_id': widget.docId,
                        'image_url': _imgCtrl.text.trim(),
                        'target_url': _targetCtrl.text.trim(),
                      }),
                    );

                    if (!context.mounted) {
                      return;
                    }

                    if (response.statusCode == 200) {
                      if (context.mounted) {
                        Navigator.pop(context);
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
                    setState(() => _loading = false);
                    if (context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  }
                },
          child: Text(
            _loading ? "Processing..." : "PURCHASE",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
