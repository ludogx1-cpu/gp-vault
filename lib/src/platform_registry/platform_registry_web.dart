import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'dart:js_interop' as js_interop;
import 'dart:js_interop_unsafe' as js_interop;
import 'dart:async';

void registerWebViews() {
  // 🚀 REGISTER VIEWS (CAPTCHAS & TENOR GIF & ADS)
  try {
    // 1. hCaptcha
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('empty-view', (int viewId) {
      return web.HTMLDivElement();
    });

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('hcaptcha-widget', (
      int viewId,
    ) {
      final div = web.HTMLDivElement();
      div.id = 'hcaptcha-target';
      div.setAttribute(
        'style',
        'display: flex; justify-content: center; align-items: center; width: 100%; height: 100%; transform: scale(0.85); transform-origin: center center;',
      );
      return div;
    });

    // 2. Turnstile
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('turnstile-widget', (
      int viewId,
    ) {
      final div = web.HTMLDivElement();
      div.id = 'turnstile-target';
      div.setAttribute(
        'style',
        'display: flex; justify-content: center; align-items: center; width: 100%; height: 100%; transform: scale(0.85); transform-origin: center center;',
      );
      return div;
    });

    // 3. Tenor Dogecoin Animated GIF View (Original Embed + Hover Blocked!)
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('tenor-gif-view', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      // pointer-events: none completely blocks the Tenor hover menu
      iframe.setAttribute(
        'style',
        'border: none; width: 100%; height: 100%; pointer-events: none;',
      );

      iframe.setAttribute('srcdoc', '''
          <!DOCTYPE html>
          <html>
            <head>
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
        ''');
      return iframe;
    });

    // 4. YouTube Embed
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('youtube-promo', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://www.youtube.com/embed/_P9YSHwbcC0?autoplay=0&loop=1');
      iframe.setAttribute('style', 'border:none; width:100%; height:100%; border-radius: 15px;');
      iframe.setAttribute('allow', 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share');
      iframe.setAttribute('allowfullscreen', 'true');
      return iframe;
    });

    // 5. Substack Embed
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('substack-embed', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://goldenpawcrypto.substack.com/embed');
      iframe.setAttribute('width', '100%');
      iframe.setAttribute('height', '320');
      iframe.setAttribute('style', 'border: 1px solid #EEE; background: white; border-radius: 8px;');
      iframe.setAttribute('frameborder', '0');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 6. Adsterra 160x600 Skyscraper
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('adsterra-160x600', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', '/adsterra_160x600.html');
      iframe.setAttribute('style', 'border:none; width:160px; height:600px; overflow:hidden;');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 8. Adsterra 300x250
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('adsterra-300x250', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', '/adsterra_300x250.html');
      iframe.setAttribute('style', 'border:none; width:300px; height:250px; overflow:hidden;');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 9. Adsterra 160x300
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('adsterra-160x300', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', '/adsterra_160x300.html');
      iframe.setAttribute('style', 'border:none; width:160px; height:300px; overflow:hidden;');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 10. Adsterra 728x90
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('adsterra-728x90', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', '/adsterra_728x90.html');
      iframe.setAttribute('style', 'border:none; width:728px; height:90px; overflow:hidden;');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 10b. CCNSAD 300x250
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('ccnsad-300x250', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', '/ccnsad_300x250.html');
      iframe.setAttribute('style', 'border:none; width:300px; height:250px; overflow:hidden; background:transparent;');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 10c. CCNSAD 728x90
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('ccnsad-728x90', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', '/ccnsad_728x90.html');
      iframe.setAttribute('style', 'border:none; width:728px; height:90px; overflow:hidden; background:transparent;');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 11. Trustpilot
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('trustpilot-widget', (int viewId) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.className = 'trustpilot-widget';
      div.setAttribute('data-locale', 'en-US');
      div.setAttribute('data-template-id', '56278e9abfbbba0bdcd568bc');
      div.setAttribute('data-businessunit-id', '6a1dccd0a3d62f26192ecf20');
      div.setAttribute('data-style-height', '52px');
      div.setAttribute('data-style-width', '100%');
      div.setAttribute('data-token', 'c72b1282-1e67-4cde-a10e-59a91bf3216f');
      
      final a = web.document.createElement('a') as web.HTMLAnchorElement;
      a.href = 'https://www.trustpilot.com/review/goldenpaw.dog';
      a.target = '_blank';
      a.rel = 'noopener';
      a.text = 'Trustpilot';
      
      div.appendChild(a);
      
      // Wait for the DOM to insert it, then ask Trustpilot to load
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
           final windowObj = web.window as js_interop.JSObject;
           if (windowObj.has('Trustpilot')) {
             final tp = windowObj.getProperty('Trustpilot'.toJS) as js_interop.JSObject;
             tp.callMethod('loadFromElement'.toJS, div);
           }
        } catch (e) {
           // ignore
        }
      });
      
      return div;
    });

    // 12. GitHub Sponsors Iframe
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('github-sponsors-iframe', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://github.com/sponsors/ludogx1-cpu/button');
      iframe.setAttribute('title', 'Sponsor ludogx1-cpu');
      iframe.setAttribute('height', '32');
      iframe.setAttribute('width', '114');
      iframe.setAttribute('style', 'border: 0; border-radius: 6px;');
      return iframe;
    });
    // 13. Bitcotasks Responsive Ad
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('bitcotasks-ad', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('style', 'border:none; width:100%; height:100%; overflow:hidden;');
      iframe.setAttribute('scrolling', 'no');
      iframe.setAttribute('srcdoc', '''
        <!DOCTYPE html>
        <html>
          <body style="margin:0;padding:0; display:flex; justify-content:center; align-items:center;">
            <script>
            (function() {
              function insertAd() {
                var width = window.parent.innerWidth || window.innerWidth;
                var size = '300x250';
                if(width >= 1200) size = '728x90';
                else if(width >= 992) size = '468x60';
                else if(width >= 768) size = '300x100';
                var adIframe = document.createElement('iframe');
                adIframe.src = 'https://bitcotasks.com/banner.php?key=0cd9422cecc4ffac20af8a7d&size=' + size;
                adIframe.frameBorder = 'no';
                adIframe.style.width = size.split('x')[0] + 'px';
                adIframe.style.height = size.split('x')[1] + 'px';
                adIframe.style.overflow = 'hidden';
                var s = document.currentScript;
                s.parentNode.insertBefore(adIframe, s);
                s.parentNode.removeChild(s);
              }
              insertAd();
            })();
            </script>
          </body>
        </html>
      ''');
      return iframe;
    });

    // 14. Bitcotasks 468x60 Ad
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('bitcotasks-468x60', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://bitcotasks.com/banner.php?key=0cd9422cecc4ffac20af8a7d&size=468x60');
      iframe.setAttribute('style', 'border:none; width:468px; height:60px; overflow:hidden;');
      iframe.setAttribute('frameborder', 'no');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 15. Bitcotasks 728x90 Ad
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('bitcotasks-728x90', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://bitcotasks.com/banner.php?key=0cd9422cecc4ffac20af8a7d&size=728x90');
      iframe.setAttribute('style', 'border:none; width:728px; height:90px; overflow:hidden;');
      iframe.setAttribute('frameborder', 'no');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 16. Bitcotasks 300x250 Ad
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('bitcotasks-300x250', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://bitcotasks.com/banner.php?key=0cd9422cecc4ffac20af8a7d&size=300x250');
      iframe.setAttribute('style', 'border:none; width:300px; height:250px; overflow:hidden;');
      iframe.setAttribute('frameborder', 'no');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 17. Bitcotasks 300x100 Ad
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('bitcotasks-300x100', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://bitcotasks.com/banner.php?key=0cd9422cecc4ffac20af8a7d&size=300x100');
      iframe.setAttribute('style', 'border:none; width:300px; height:100px; overflow:hidden;');
      iframe.setAttribute('frameborder', 'no');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 18. Bitcotasks 160x600 Ad
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('bitcotasks-160x600', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://bitcotasks.com/banner.php?key=0cd9422cecc4ffac20af8a7d&size=160x600');
      iframe.setAttribute('style', 'border:none; width:160px; height:600px; overflow:hidden;');
      iframe.setAttribute('frameborder', 'no');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

    // 19. Bitcotasks 300x600 Ad
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('bitcotasks-300x600', (int viewId) {
      final iframe = web.HTMLIFrameElement();
      iframe.setAttribute('src', 'https://bitcotasks.com/banner.php?key=0cd9422cecc4ffac20af8a7d&size=300x600');
      iframe.setAttribute('style', 'border:none; width:300px; height:600px; overflow:hidden;');
      iframe.setAttribute('frameborder', 'no');
      iframe.setAttribute('scrolling', 'no');
      return iframe;
    });

  } catch (e) {
    // ignore: empty_catches
  }
}
