import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'universal_web_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UniversalWebViewNative extends UniversalWebView {
  const UniversalWebViewNative({
    super.key,
    required super.viewType,
    super.initialUrl,
    super.onMessageReceived,
    super.width,
    super.height,
  });

  @override
  State<UniversalWebViewNative> createState() => _UniversalWebViewNativeState();
}

class _UniversalWebViewNativeState extends State<UniversalWebViewNative> {
  late final WebViewController? _controller;
  late final bool _isSupported;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      _isSupported = false;
      _controller = null;
      return;
    }
    _isSupported = true;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36')
      ..setBackgroundColor(Colors.transparent);

    if (widget.onMessageReceived != null) {
      _controller!.addJavaScriptChannel(
        'Print',
        onMessageReceived: (JavaScriptMessage message) {
          widget.onMessageReceived!(message.message);
        },
      );
    }

    _loadContent();
  }

  @override
  void didUpdateWidget(covariant UniversalWebViewNative oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewType != widget.viewType || oldWidget.initialUrl != widget.initialUrl) {
      _loadContent();
    }
  }

  void _loadContent() {
    final controller = _controller;
    if (controller == null) return;
    if (widget.initialUrl != null) {
      controller.loadRequest(Uri.parse(widget.initialUrl!));
    } else if (widget.viewType == 'turnstile-widget') {
      controller.loadRequest(Uri.parse('https://goldenpaw.dog/captcha.html?provider=turnstile'));
    } else if (widget.viewType == 'hcaptcha-widget') {
      controller.loadRequest(Uri.parse('https://goldenpaw.dog/captcha.html?provider=hcaptcha'));
    } else {
      controller.loadHtmlString(
        _getHtmlForViewType(widget.viewType),
        baseUrl: 'https://goldenpaw.dog',
      );
    }
  }

  String _getHtmlForViewType(String viewType) {
    if (viewType == 'hcaptcha-widget') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>html, body { margin:0; padding:0; width:100%; height:100%; display:flex; justify-content:center; align-items:center; background:transparent; overflow:hidden; }</style>
          <script src="https://js.hcaptcha.com/1/api.js?onload=onHcaptchaLoaded&render=explicit" async defer></script>
        </head>
        <body>
          <div id="hcaptcha-container"></div>
          <script>
            function onHcaptchaLoaded() {
              try {
                hcaptcha.render('hcaptcha-container', {
                  sitekey: 'e47877ca-d0f0-44d0-aa70-7e06f3a2848e',
                  callback: function(token) {
                    Print.postMessage(JSON.stringify({"token": token, "captcha_token": token, "turnstile_token": token}));
                  }
                });
              } catch(e) {
                console.error('Error rendering hCaptcha:', e);
              }
            }
          </script>
        </body>
        </html>
      ''';
    } else if (viewType == 'turnstile-widget') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>html, body { margin:0; padding:0; width:100%; height:100%; display:flex; justify-content:center; align-items:center; background:transparent; overflow:hidden; }</style>
          <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onTurnstileLoaded" async defer></script>
        </head>
        <body>
          <div id="cf-container"></div>
          <script>
            function onTurnstileLoaded() {
              try {
                turnstile.render('#cf-container', {
                  sitekey: '0x4AAAAAADN3brAhvXC8xH0X',
                  callback: function(token) {
                    Print.postMessage(JSON.stringify({"token": token, "captcha_token": token, "turnstile_token": token}));
                  }
                });
              } catch(e) {
                console.error('Error rendering Turnstile:', e);
              }
            }
          </script>
        </body>
        </html>
      ''';
    } else if (viewType == 'tenor-gif-view') {
      return '''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body { margin: 0; display: flex; justify-content: center; align-items: center; overflow: hidden; background: transparent; }
              .tenor-gif-embed { width: 100% !important; max-width: 120px; pointer-events: none; }
            </style>
          </head>
          <body>
            <div class="tenor-gif-embed" data-postid="4351659229197618111" data-share-method="host" data-aspect-ratio="1" data-width="100%">
              <a href="https://tenor.com/view/dogecoin-logo-animation-dogecoin-logo-animation-crypto-gif-4351659229197618111">Dogecoin Logo GIF</a>
            </div>
            <script type="text/javascript" async src="https://tenor.com/embed.js"></script>
          </body>
        </html>
      ''';
    } else if (viewType == 'youtube-promo') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin:0; background: black;">
          <iframe src="https://www.youtube.com/embed/_P9YSHwbcC0?autoplay=0&loop=1" style="border:none; width:100vw; height:100vh;" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen="true"></iframe>
        </body>
        </html>
      ''';
    } else if (viewType == 'substack-embed') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin:0;">
          <iframe src="https://goldenpawcrypto.substack.com/embed" width="100%" height="320" style="border: 1px solid #EEE; background: white; border-radius: 8px;" frameborder="0" scrolling="no"></iframe>
        </body>
        </html>
      ''';
    } else if (viewType == 'trustpilot-widget') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <script type="text/javascript" src="//widget.trustpilot.com/bootstrap/v5/tp.widget.bootstrap.min.js" async></script>
        </head>
        <body style="margin:0; background: transparent; display:flex; justify-content:center; align-items:center;">
          <div class="trustpilot-widget" data-locale="en-US" data-template-id="56278e9abfbbba0bdcd568bc" data-businessunit-id="6a1dccd0a3d62f26192ecf20" data-style-height="52px" data-style-width="100%" data-token="c72b1282-1e67-4cde-a10e-59a91bf3216f">
            <a href="https://www.trustpilot.com/review/goldenpaw.dog" target="_blank" rel="noopener">Trustpilot</a>
          </div>
        </body>
        </html>
      ''';
    } else if (viewType.startsWith('bitcotasks-')) {
      final sizeStr = viewType.replaceFirst('bitcotasks-', '');
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>body { margin:0; overflow:hidden; background:transparent; display:flex; justify-content:center; align-items:center; height:100vh; width: 100vw; }</style>
        </head>
        <body>
          <iframe src="https://bitcotasks.com/banner.php?key=0cd9422cecc4ffac20af8a7d&size=$sizeStr" width="100%" height="100%" style="border:none;" scrolling="no"></iframe>
        </body>
        </html>
      ''';
    } else if (viewType == 'github-sponsors-iframe') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>body { margin:0; padding:0; display:flex; justify-content:center; align-items:center; background: transparent; overflow:hidden; }</style>
        </head>
        <body>
          <iframe src="https://github.com/sponsors/ludogx1-cpu/button" title="Sponsor ludogx1-cpu" height="32" width="114" style="border: 0; border-radius: 6px;"></iframe>
        </body>
        </html>
      ''';
    }

    return '<html><body>Not found</body></html>';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }
    Widget child = WebViewWidget(controller: _controller!);
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
  return UniversalWebViewNative(
    key: key,
    viewType: viewType,
    initialUrl: initialUrl,
    onMessageReceived: onMessageReceived,
    width: width,
    height: height,
  );
}