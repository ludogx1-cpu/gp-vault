import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DogePriceProvider extends ChangeNotifier {
  double _currentDogePrice = 0.15;
  DateTime? _lastPriceUpdate;
  Timer? _priceTimer;

  double get currentDogePrice => _currentDogePrice;
  DateTime? get lastPriceUpdate => _lastPriceUpdate;

  bool get isPriceStale {
    if (_lastPriceUpdate == null) return true;
    return DateTime.now().difference(_lastPriceUpdate!).inMinutes >= 10;
  }

  DogePriceProvider() {
    _fetchDogePrice();
    _priceTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchDogePrice();
    });
  }

  Future<void> _fetchDogePrice() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=DOGEUSDT',
        ),
      );
      if (res.statusCode == 200) {
        _currentDogePrice = double.parse(jsonDecode(res.body)['price']);
        _lastPriceUpdate = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    super.dispose();
  }
}
