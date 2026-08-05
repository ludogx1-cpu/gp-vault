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
    // webview_flutter only supports Android and iOS natively.
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
      ..setBackgroundColor(Colors.transparent);
      
    if (widget.onMessageReceived != null) {
      _controller!.addJavaScriptChannel(
        'Print',
        onMessageReceived: (JavaScriptMessage message) {
          widget.onMessageReceived!(message.message);
        },
      );
    }

    if (widget.initialUrl != null) {
      _controller!.loadRequest(Uri.parse(widget.initialUrl!));
    } else {
      _controller!.loadHtmlString(
        _getHtmlForViewType(widget.viewType), 
        baseUrl: 'https://goldenpaw.dog/'
      );
    }
  }

  String _getHtmlForViewType(String viewType) {
    if (viewType == 'hcaptcha-widget') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=0.85, maximum-scale=0.85, user-scalable=no">
          <script src="https://js.hcaptcha.com/1/api.js" async defer></script>
        </head>
        <body style="display:flex; justify-content:center; align-items:center; height:100vh; margin:0; background: transparent;">
          <div class="h-captcha" data-sitekey="1d5b3c3b-252d-4d7a-8f43-7f2a1b9b12a8" data-callback="onSuccess"></div>
          <script>
            function onSuccess(token) {
              Print.postMessage(JSON.stringify({"captcha_token": token}));
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
          <meta name="viewport" content="width=device-width, initial-scale=0.85, maximum-scale=0.85, user-scalable=no">
          <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
        </head>
        <body style="display:flex; justify-content:center; align-items:center; height:100vh; margin:0; background: transparent;">
          <div class="cf-turnstile" data-sitekey="0x4AAAAAAAcj2U6Z7j1z3QWq" data-callback="onSuccess"></div>
          <script>
            function onSuccess(token) {
              Print.postMessage(JSON.stringify({"turnstile_token": token}));
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
    } else if (viewType.startsWith('adsterra-')) {
       return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin:0; display:flex; justify-content:center; align-items:center; height:100vh;">
          <p>Ad Placeholder for \$viewType</p>
        </body>
        </html>
       ''';
    } else if (viewType == 'ccnsad-300x250') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>body { margin:0; overflow:hidden; background:transparent; display:flex; justify-content:center; align-items:center; }</style>
        </head>
        <body>
          <div class="cc-c5665d1f63554fb5" style="display:inline-block;width:300px;height:250px;"></div>
          <script>!function e(n,o,t,c,r,d,s,a){(a=o.createElement(t)).async=!0,a.src="https://"+r[d]+"/js/"+c+".js?v="+s,a.onerror=function(){a.remove(),(d+=1)>=r.length||e(n,o,t,c,r,d,s)},o.head.appendChild(a)}(window,document,"script","c5665d1f63554fb5",["cdn.ccnsad.com"],0,Math.floor(Date.now()/3600000));</script>
        </body>
        </html>
      ''';
    } else if (viewType == 'ccnsad-728x90') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>body { margin:0; overflow:hidden; background:transparent; display:flex; justify-content:center; align-items:center; }</style>
        </head>
        <body>
          <div class="cc-05f6fe5b0116e524" style="display:inline-block;width:728px;height:90px;"></div>
          <script>!function e(n,o,t,c,r,d,s,a){(a=o.createElement(t)).async=!0,a.src="https://"+r[d]+"/js/"+c+".js?v="+s,a.onerror=function(){a.remove(),(d+=1)>=r.length||e(n,o,t,c,r,d,s)},o.head.appendChild(a)}(window,document,"script","05f6fe5b0116e524",["cdn.ccnsad.com"],0,Math.floor(Date.now()/3600000));</script>
        </body>
        </html>
      ''';
    }
    return '<html><body>Not found</body></html>';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) {
      // Return a blank box for unsupported desktop platforms
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
