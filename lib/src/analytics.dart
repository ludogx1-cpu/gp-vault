import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'js_bindings.dart';

/// On the website, Firebase Analytics (which loads Google's tag) must only run
/// after the visitor accepts analytics cookies in the cookie banner
/// (web/consent.js sets window.gpAnalyticsAllowed). The Firebase web plugin
/// only loads Google's tag on its first call, so skipping calls until consent
/// means nothing is loaded before then. Native apps are unaffected.
bool get analyticsAllowed => analyticsConsentGiven();

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
