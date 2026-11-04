import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Production App ID & Native Ad Unit ID
  static const String appId = 'ca-app-pub-2047805482197197~3796279278';
  static const String nativeAdUnitId = 'ca-app-pub-2047805482197197/5553223239';

  // Google's official test ad unit ID for development (prevents policy violations during testing)
  static const String testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get activeNativeAdUnitId {
    if (kDebugMode) {
      return testNativeAdUnitId;
    }
    return nativeAdUnitId;
  }

  static Future<void> initialize() async {
    if (!isSupported) return;
    try {
      await MobileAds.instance.initialize();
      debugPrint('AdMob initialized successfully');
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  }
}
