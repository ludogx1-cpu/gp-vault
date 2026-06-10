import 'package:flutter/foundation.dart';

class ApiConstants {
  // Use localhost when debugging, or your Render URL in production
  static const String baseUrl = kDebugMode
      ? 'https://golden-paw-vault.onrender.com' // You can change this to 'http://localhost:3000' for local testing
      : 'https://golden-paw-vault.onrender.com';
}
