import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'js_bindings.dart';

/// Analytics only runs with the user's consent.
///
/// - Website: the visitor accepts analytics cookies in the cookie banner
///   (web/consent.js sets window.gpAnalyticsAllowed). The Firebase web plugin
///   only loads Google's tag on its first call, so skipping calls until
///   consent means nothing is loaded before then.
/// - App: collection is off by default (AndroidManifest.xml) and only turned
///   on if the user ticks the analytics box (age gate or Cookies page).
bool get analyticsAllowed =>
    kIsWeb ? analyticsConsentGiven() : _appAnalyticsConsent == true;

const String _appConsentKey = 'analytics_consent';
bool? _appAnalyticsConsent;

/// The user's saved choice in the app: null if they haven't chosen yet.
bool? get appAnalyticsChoice => _appAnalyticsConsent;

/// Loads the saved choice at start-up and applies it (app only).
Future<void> loadAppAnalyticsConsent() async {
  if (kIsWeb) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    _appAnalyticsConsent = prefs.getBool(_appConsentKey);
  } catch (_) {}
  await _applyAppConsent();
}

/// Saves and applies the user's choice (app only).
Future<void> setAppAnalyticsConsent(bool allowed) async {
  if (kIsWeb) return;
  _appAnalyticsConsent = allowed;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appConsentKey, allowed);
  } catch (_) {}
  await _applyAppConsent();
}

Future<void> _applyAppConsent() async {
  final allowed = _appAnalyticsConsent == true;
  try {
    await FirebaseAnalytics.instance.setConsent(
      analyticsStorageConsentGranted: allowed,
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
    );
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(allowed);
  } catch (_) {}
}

/// Logs an analytics event if the visitor has allowed analytics.
void logAnalyticsEvent(String name, {Map<String, Object>? parameters}) {
  if (!analyticsAllowed) return;
  FirebaseAnalytics.instance
      .logEvent(name: name, parameters: parameters)
      .catchError((Object _) {});
}

/// Sends screen views only when analytics is allowed.
class ConsentAwareAnalyticsObserver extends NavigatorObserver {
  final FirebaseAnalyticsObserver _inner = FirebaseAnalyticsObserver(
    analytics: FirebaseAnalytics.instance,
  );

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (analyticsAllowed) _inner.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (analyticsAllowed) _inner.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (analyticsAllowed) _inner.didPop(route, previousRoute);
  }
}
