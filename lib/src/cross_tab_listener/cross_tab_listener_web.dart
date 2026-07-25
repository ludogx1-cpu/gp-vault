import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'cross_tab_listener_stub.dart';
export 'cross_tab_listener_stub.dart';

class CrossTabListenerWeb implements CrossTabListener {
  StreamSubscription? _storageSubscription;
  StreamSubscription? _messageSubscription;

  @override
  void setup(Function(String) onMessage) {
    debugPrint("CrossTabListenerWeb: Setting up listeners!");
    
    _storageSubscription = web.EventStreamProviders.storageEvent
        .forTarget(web.window)
        .listen((web.Event event) {
      debugPrint("CrossTabListenerWeb: Received storage event!");
      try {
        final storageEvent = event as web.StorageEvent;
        if (storageEvent.key != null && storageEvent.key!.contains('bonus_timer_trigger')) {
          onMessage('{"type":"start_bonus_timer"}');
        }
      } catch (e) {
        debugPrint("CrossTabListenerWeb error: $e");
      }
    });

    _messageSubscription = web.EventStreamProviders.messageEvent
        .forTarget(web.window)
        .listen((web.Event event) {
      try {
        final msgEvent = event as web.MessageEvent;
        final dartData = msgEvent.data?.dartify();
        if (dartData is String) {
          onMessage(dartData);
        } else if (dartData != null && dartData.toString().contains('start_bonus_timer')) {
          onMessage('{"type":"start_bonus_timer"}');
        }
      } catch (e) {
        // ignore
      }
    });
  }

  @override
  void cancel() {
    _storageSubscription?.cancel();
    _messageSubscription?.cancel();
  }

  @override
  void setBrowserTitle(String title) {
    try {
      web.document.title = title;
    } catch (e) {
      // ignore
    }
  }

  @override
  bool hasFocus() {
    try {
      return web.document.hasFocus();
    } catch (e) {
      return false;
    }
  }

  @override
  void renderHCaptcha() {
    try {
      _renderHCaptcha();
    } catch (e) {
      debugPrint("Error renderHCaptcha: $e");
    }
  }

  @override
  void renderTurnstile() {
    try {
      _renderTurnstile();
    } catch (e) {
      debugPrint("Error renderTurnstile: $e");
    }
  }

  @override
  void injectAdsterraPopunder(String scriptUrl) {
    try {
      final script = web.HTMLScriptElement()
        ..src = scriptUrl
        ..type = 'text/javascript'
        ..id = 'injected-popunder';
      web.document.head!.append(script);
    } catch (e) {
      debugPrint("Error injecting popunder: $e");
    }
  }

  @override
  void removeAdsterraPopunder(String scriptUrl) {
    try {
      final script = web.document.getElementById('injected-popunder');
      if (script != null) {
        script.remove();
      }
    } catch (e) {
      debugPrint("Error removing popunder: $e");
    }
  }
}

CrossTabListener getCrossTabListener() => CrossTabListenerWeb();

@JS('renderHCaptcha')
external void _renderHCaptcha();

@JS('renderTurnstile')
external void _renderTurnstile();
