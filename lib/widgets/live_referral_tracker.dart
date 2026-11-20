import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/material.dart';
import '../src/theme_provider.dart';
import 'package:gp_faucet/src/brand_colors.dart';

class LiveReferralTracker extends StatefulWidget {
  const LiveReferralTracker({super.key});

  @override
  State<LiveReferralTracker> createState() => _LiveReferralTrackerState();
}

class _LiveReferralTrackerState extends State<LiveReferralTracker> {
  double _price = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchPrice();
    _timer = Timer.periodic(const Duration(seconds: 30), (t) => _fetchPrice());
  }

  Future<void> _fetchPrice() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=DOGEUSDT',
        ),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() => _price = double.parse(jsonDecode(res.body)['price']));
        }
      }
    } catch (e) {
      // ignore: empty_catches
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _explain(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('What is this price?'),
        content: const Text(
          'This is the current price of Dogecoin (DOGE) in US dollars, updated '
          'every 30 seconds.\n\n'
          'Golden Paw pays its small game rewards in DOGE, so the price shows '
          'roughly what those rewards are worth today. It goes up and down, '
          'and it is shown for information only. It is not advice to buy, '
          'sell or hold anything.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Price display only. No exchange link: promoting crypto trading to UK
    // users is a regulated financial promotion.
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final String priceText =
        _price > 0 ? "\$${_price.toStringAsFixed(4)}" : "…";

    final Color muted = gpChromeMuted(context);
    final Color gold = gpChromeGold(context);

    return Material(
      color: gpChromeColor(context),
      child: InkWell(
        onTap: () => _explain(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: kGold.shade700, width: 2),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMobile ? "Dogecoin (USD): " : "Dogecoin price (USD): ",
                  style: TextStyle(
                    color: gpChromeText(context),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  priceText,
                  style: TextStyle(
                    color: gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'What is this?',
                  child: Icon(Icons.info_outline, color: muted, size: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
