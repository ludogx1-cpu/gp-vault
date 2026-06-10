import 'package:web/web.dart' as web;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/material.dart';
import '../src/theme_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => web.window.open(
        'https://www.binance.com/activity/referral-entry/CPA?ref=CPA_00SAJGMUIA',
        '_blank',
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: kAppBarColor,
          border: Border(
            bottom: BorderSide(color: Colors.amber.shade700, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            const Text(
              "LIVE DOGE: ",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "\$${_price.toStringAsFixed(4)}",
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 15),
            const Text(
              "|  TRADE ON BINANCE 🚀",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
