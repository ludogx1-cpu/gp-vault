import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Production App ID & Native Ad Unit ID
  static const String appId = 'ca-app-pub-2047805482197197~2114621817';
  static const String nativeAdUnitId = 'ca-app-pub-2047805482197197/1969930399';

  // Google's official test ad unit ID for development (prevents policy violations during testing)
  static const String testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// True once the user's ad consent has been gathered (or isn't required
  /// where they live) and the Mobile Ads SDK has started. Ads must not be
  /// requested before this.
  static final ValueNotifier<bool> adsReady = ValueNotifier<bool>(false);

  static String get activeNativeAdUnitId {
    if (kDebugMode) {
      return testNativeAdUnitId;
    }
    return nativeAdUnitId;
  }

  /// Starts consent gathering in the background so app start-up isn't held
  /// up by the network.
  static Future<void> initialize() async {
    if (!isSupported) return;
    unawaited(_gatherConsentThenStart());
  }

  /// Google's User Messaging Platform shows the AdMob consent form to users
  /// in the UK/EEA (set up in AdMob → Privacy & messaging). Elsewhere no form
  /// is needed.
  static Future<void> _gatherConsentThenStart() async {
    try {
      await _requestConsentInfo();
      await _showFormIfRequired();
    } catch (e) {
      debugPrint('AdMob consent error: $e');
    }
    await _startIfAllowed();
  }

  static Future<void> _requestConsentInfo() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => done.complete(),
      (FormError error) {
        debugPrint('Consent info update failed: ${error.message}');
        done.complete();
      },
    );
    return done.future;
  }

  static Future<void> _showFormIfRequired() {
    final done = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null) debugPrint('Consent form error: ${error.message}');
      done.complete();
    });
    return done.future;
  }

  static Future<void> _startIfAllowed() async {
    try {
      if (!await ConsentInformation.instance.canRequestAds()) return;
      if (!adsReady.value) {
        await MobileAds.instance.initialize();
        adsReady.value = true;
        debugPrint('AdMob initialized successfully');
      }
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  }

  /// Whether the user must be offered a way to change their ad choices.
  static Future<bool> privacyOptionsRequired() async {
    if (!isSupported) return false;
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  /// Re-opens the AdMob consent form so the user can change their choices.
  static Future<void> showPrivacyOptions() async {
    if (!isSupported) return;
    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) debugPrint('Privacy options error: ${error.message}');
      done.complete();
    });
    await done.future;
    await _startIfAllowed();
  }
}
