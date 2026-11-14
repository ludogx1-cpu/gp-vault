import 'dart:js_interop';

@JS('renderHCaptcha')
external void renderHCaptcha();

@JS('renderTurnstile')
external void renderTurnstile();

@JS('showAadsOverlay')
external void showAadsOverlay(String id, double x, double y);

@JS('hideAadsOverlay')
external void hideAadsOverlay(String id);

@JS('hideAllAads')
external void hideAllAads();

@JS('gpAnalyticsAllowed')
external JSBoolean? get _gpAnalyticsAllowed;

/// True once the visitor has accepted analytics cookies (set by web/consent.js).
bool analyticsConsentGiven() {
  try {
    return _gpAnalyticsAllowed?.toDart ?? false;
  } catch (_) {
    return false;
  }
}
