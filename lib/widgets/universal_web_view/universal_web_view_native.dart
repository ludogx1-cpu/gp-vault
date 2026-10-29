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
        defaultTargetPlatform == TargetPlatform.linux ||
        WebViewPlatform.instance == null) {
      _isSupported = false;
      _controller = null;
      return;
    }
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent('Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36')
        ..setBackgroundColor(Colors.transparent);
      _isSupported = true;
    } catch (_) {
      _isSupported = false;
      _controller = null;
      return;
    }

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
          <style>
            * { box-sizing: border-box; }
            html, body { margin:0; padding:0; width:100%; height:100%; display:flex; justify-content:center; align-items:center; background:transparent; overflow-y:auto; overflow-x:hidden; }
            #hcaptcha-container { display:flex; justify-content:center; align-items:center; width:100%; height:100%; }
            dialog, [id*="zaraz"], [class*="zaraz"] { display: none !important; }
          </style>
          <script>
            function notifyFlutter(token) {
              if (window.Print && window.Print.postMessage) {
                window.Print.postMessage(JSON.stringify({"token": token, "captcha_token": token, "hcaptcha_token": token, "provider": "hcaptcha"}));
              }
            }
            window.onHcaptchaLoaded = function() {
              try {
                const el = document.getElementById('hcaptcha-container');
                if (el && !el.hasChildNodes()) {
                  hcaptcha.render('hcaptcha-container', {
                    sitekey: 'e47877ca-d0f0-44d0-aa70-7e06f3a2848e',
                    callback: function(token) {
                      notifyFlutter(token);
                    }
                  });
                }
              } catch(e) {
                console.error('Error rendering hCaptcha:', e);
              }
            };
          </script>
          <script src="https://js.hcaptcha.com/1/api.js?onload=onHcaptchaLoaded&render=explicit" async defer></script>
        </head>
        <body>
          <div id="hcaptcha-container"></div>
        </body>
        </html>
      ''';
    } else if (viewType == 'turnstile-widget') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            * { box-sizing: border-box; }
            html, body { margin:0; padding:0; width:100%; height:100%; display:flex; justify-content:center; align-items:center; background:transparent; overflow-y:auto; overflow-x:hidden; }
            #cf-container { display:flex; justify-content:center; align-items:center; width:100%; height:100%; min-height:65px; }
            dialog, #zaraz-consent-modal, [id*="zaraz"], [class*="zaraz"] {
              display: none !important;
              visibility: hidden !important;
              opacity: 0 !important;
              pointer-events: none !important;
            }
          </style>
          <script>
            function notifyFlutter(token) {
              if (window.Print && window.Print.postMessage) {
                window.Print.postMessage(JSON.stringify({"token": token, "captcha_token": token, "turnstile_token": token, "provider": "turnstile"}));
              }
            }
            window.onTurnstileLoaded = function() {
              if (typeof turnstile !== 'undefined') {
                try {
                  const el = document.getElementById('cf-container');
                  if (el && !el.hasChildNodes()) {
                    turnstile.render('#cf-container', {
                      sitekey: '0x4AAAAAADN3brAhvXC8xH0X',
                      theme: 'auto',
                      callback: function(token) {
                        notifyFlutter(token);
                      },
                      'error-callback': function(code) {
                        console.warn('Turnstile error:', code);
                      }
                    });
                  }
                } catch(e) {
                  console.error('Turnstile render error:', e);
                }
              }
            };
          </script>
          <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onTurnstileLoaded&render=explicit" async defer></script>
        </head>
        <body>
          <div id="cf-container"></div>
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
    } else if (viewType == 'bitcotasks-ad') {
      return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>body { margin:0; padding:0; overflow:hidden; background:transparent; display:flex; justify-content:center; align-items:center; width:100vw; height:100vh; }</style>
        </head>
        <body>
          <script>
          (function() {
            var width = window.innerWidth || 320;
            var size = '300x250';
            if (width >= 728) size = '728x90';
            else if (width >= 468) size = '468x60';
            var adIframe = document.createElement('iframe');
            adIframe.src = 'https://bitcotasks.com/banner.php?key=0cd9422cecc4ffac20af8a7d&size=' + size;
            adIframe.frameBorder = 'no';
            adIframe.style.border = 'none';
            adIframe.style.width = size.split('x')[0] + 'px';
            adIframe.style.height = size.split('x')[1] + 'px';
            adIframe.style.overflow = 'hidden';
            document.body.appendChild(adIframe);
          })();
          </script>
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
    } else if (viewType == 'adsterra-728x90') {
      return _buildAdsterraHtml('a8b9e808bb4744321dfd441c0eff4a37');
    } else if (viewType == 'adsterra-468x60' || viewType.startsWith('adsterra-landing-')) {
      return _buildAdsterraHtml('81487b0cf69981d5b93588025428264e');
    } else if (viewType == 'adsterra-300x250') {
      return _buildAdsterraHtml('db55b2e461e7dcfb40070e78dd094ac9');
    } else if (viewType == 'adsterra-160x600') {
      return _buildAdsterraHtml('f230343a2411c75040c34f8eb7445074');
    } else if (viewType == 'adsterra-160x300') {
      return _buildAdsterraHtml('b83f17d822fee1ca201539b3b828110e');
    } else if (viewType == 'adsense-ptc-1') {
      return _buildAdSenseHtml('2038938184');
    } else if (viewType == 'adsense-ptc-2') {
      return _buildAdSenseHtml('1704542038');
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

  String _buildAdsterraHtml(String key) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { margin: 0; padding: 0; overflow: hidden; background: transparent; display: flex; justify-content: center; align-items: center; }
        </style>
      </head>
      <body>
        <script>
          if (typeof atAsyncOptions !== 'object') var atAsyncOptions = [];
          atAsyncOptions.push({
            key: '$key',
            format: 'js',
            async: true,
            container: 'atContainer-$key',
            params: {}
          });
          var script = document.createElement('script');
          script.type = 'text/javascript';
          script.async = true;
          script.src = 'https://landslidegraphsystems.com/$key/invoke.js';
          document.getElementsByTagName('head')[0].appendChild(script);
        </script>
        <div id="atContainer-$key"></div>
      </body>
      </html>
    ''';
  }

  String _buildAdSenseHtml(String slot) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: transparent; display: flex; justify-content: center; align-items: center; }
          .ad-block { display: block; width: 100%; min-width: 280px; min-height: 250px; }
        </style>
        <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-8242289438754471" crossorigin="anonymous"></script>
      </head>
      <body>
        <ins class="adsbygoogle ad-block"
             data-ad-client="ca-pub-8242289438754471"
             data-ad-slot="$slot"
             data-ad-format="auto"
             data-full-width-responsive="true"></ins>
        <script>(adsbygoogle = window.adsbygoogle || []).push({});</script>
      </body>
      </html>
    ''';
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
