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
