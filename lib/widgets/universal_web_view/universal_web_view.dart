import 'package:flutter/material.dart';
import 'universal_web_view_stub.dart'
  if (dart.library.html) 'universal_web_view_web.dart'
  if (dart.library.io) 'universal_web_view_native.dart';

abstract class UniversalWebView extends StatefulWidget {
  final String viewType;
  final String? initialUrl;
  final Function(String)? onMessageReceived;
  final double? width;
  final double? height;

  const UniversalWebView({
    super.key,
    required this.viewType,
    this.initialUrl,
    this.onMessageReceived,
    this.width,
    this.height,
  });

  factory UniversalWebView.create({
    Key? key,
    required String viewType,
    String? initialUrl,
    Function(String)? onMessageReceived,
    double? width,
    double? height,
  }) {
    return createUniversalWebView(
      key: key,
      viewType: viewType,
      initialUrl: initialUrl,
      onMessageReceived: onMessageReceived,
      width: width,
      height: height,
    );
  }
}
