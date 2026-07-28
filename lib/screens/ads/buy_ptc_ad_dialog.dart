import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_constants.dart';
import '../../src/firebase_service.dart';

class BuyPtcAdDialog extends StatefulWidget {
  final double currentAdsBalance;

  const BuyPtcAdDialog({
    super.key,
    required this.currentAdsBalance,
  });

  @override
  State<BuyPtcAdDialog> createState() => _BuyPtcAdDialogState();
}

class _BuyPtcAdDialogState extends State<BuyPtcAdDialog> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();
  bool _loading = false;
  int _selectedTier = 1;
  int _selectedClicks = 100;

  final Map<int, double> _costs = {1: 0.25, 2: 0.50, 3: 0.75, 4: 1.50};
  final Map<int, String> _labels = {
    1: "10 Seconds",
    2: "20 Seconds",
    3: "30 Seconds",
    4: "60 Seconds",
  };
  final List<int> _clickOptions = [100, 200, 300, 500, 1000];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalCost = _costs[_selectedTier]! * (_selectedClicks / 100);

    return AlertDialog(
      title: const Text(
        "Buy Guaranteed PTC Clicks",
        style: TextStyle(
          color: Colors.black87,
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
            initialValue: _selectedTier,
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
                      "${_labels[t]} (+\$${_costs[t]!.toStringAsFixed(2)} per 100)",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedTier = val);
            },
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<int>(
            initialValue: _selectedClicks,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Number of Clicks",
            ),
            items: _clickOptions
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
              if (val != null) setState(() => _selectedClicks = val);
            },
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: "Ad Title",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _targetCtrl,
            decoration: const InputDecoration(
              labelText: "Target Link (URL)",
              border: OutlineInputBorder(),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: _loading
              ? null
              : () async {
                  if (widget.currentAdsBalance < totalCost) {
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
                  if (_titleCtrl.text.isEmpty || _targetCtrl.text.isEmpty) {
                    return;
                  }

                  setState(() => _loading = true);

                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    final response = await http.post(
                      Uri.parse(
                        '${ApiConstants.baseUrl}/buy-ptc',
                      ),
                      headers: await getAuthHeaders(),
                      body: jsonEncode({
                        'title': _titleCtrl.text.trim(),
                        'target_url': _targetCtrl.text.trim(),
                        'tier': _selectedTier,
                        'clicks': _selectedClicks,
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
                          content: Text("PTC Ad added to pool! 🚀"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      final err = jsonDecode(response.body);
                      throw err['error'];
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
            _loading
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
  }
}
