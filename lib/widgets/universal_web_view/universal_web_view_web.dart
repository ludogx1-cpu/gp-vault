import 'package:flutter/material.dart';
import 'universal_web_view.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:async';

class UniversalWebViewWeb extends UniversalWebView {
  const UniversalWebViewWeb({
    super.key,
    required super.viewType,
    super.initialUrl,
    super.onMessageReceived,
    super.width,
    super.height,
  });

  @override
  State<UniversalWebViewWeb> createState() => _UniversalWebViewWebState();
}

class _UniversalWebViewWebState extends State<UniversalWebViewWeb> {
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.onMessageReceived != null) {
      _messageSubscription = web.EventStreamProviders.messageEvent
          .forTarget(web.window)
          .listen((web.Event event) {
        try {
          final msgEvent = event as web.MessageEvent;
          final dartData = msgEvent.data?.dartify();
          String? dataStr;
          if (dartData is String) {
            dataStr = dartData;
          } else if (dartData != null) {
            dataStr = dartData.toString();
          }
          if (dataStr != null) {
            widget.onMessageReceived!(dataStr);
          }
        } catch (e) {
          // ignore
        }
      });
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = HtmlElementView(viewType: widget.viewType);
    if (widget.width != null || widget.height != null) {
      child = SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      );
    }
    return child;
  }
}

UniversalWebView createUniversalWebView({
  Key? key,
  required String viewType,
  String? initialUrl,
  Function(String)? onMessageReceived,
  double? width,
  double? height,
}) {
  return UniversalWebViewWeb(
    key: key,
    viewType: viewType,
    initialUrl: initialUrl,
    onMessageReceived: onMessageReceived,
    width: width,
    height: height,
  );
}
