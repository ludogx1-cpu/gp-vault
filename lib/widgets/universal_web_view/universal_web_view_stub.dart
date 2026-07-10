import 'package:flutter/material.dart';
import 'universal_web_view.dart';

UniversalWebView createUniversalWebView({
  Key? key,
  required String viewType,
  String? initialUrl,
  Function(String)? onMessageReceived,
  double? width,
  double? height,
}) {
  throw UnsupportedError('Cannot create a web view without dart:html or dart:io');
}
