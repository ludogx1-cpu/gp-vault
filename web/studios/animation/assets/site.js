/*
 * Site-wide config + monetisation loader.
 *
 * EDIT THE CONFIG BLOCK BELOW (or run scripts/configure.sh, which fills the
 * domain and AdSense publisher ID for you). Everything stays switched off
 * until you paste real IDs in, so the site looks clean while AdSense reviews it.
 */
window.SITE_CONFIG = {
    // Google AdSense publisher ID, e.g. "ca-pub-1234567890123456".
    // Leave as the placeholder until AdSense gives you one.
    adsenseClient: 'ca-pub-2047805482197197',

    // Ad unit slot IDs from AdSense > Ads > By ad unit > Display ads.
    // Any slot left empty is hidden. If you prefer Google "Auto ads",
    // leave these empty and turn Auto ads on inside AdSense instead.
    adSlots: {
        top: '',      // under the "How to use" box
        results: '',  // under the Results panel
        content: ''   // inside the guides / FAQ content
    },

    // Google Analytics 4 measurement ID, e.g. "G-ABC123XYZ9". Empty = off.
    ga4: '',

    // Optional tip jar (Ko-fi, Buy Me a Coffee, Stripe Payment Link...). Empty = hidden.
    supportUrl: '',

    // Pro (one-off purchase, sold through Lemon Squeezy, which also handles VAT).
    // checkoutUrl: the product's "Buy" link, e.g. https://goldenpawstudios.lemonsqueezy.com/buy/xxxx
    // productId:   the number shown on the product page in Lemon Squeezy (stops keys
    //              for other products unlocking Pro). Leave empty while testing.
    pro: {
        price: '£11.99',
        checkoutUrl: '',
        productId: ''
    },

    // Shown on the Contact page. Use a dedicated address, not your personal one.
    contactEmail: 'goldenpaw.dogeadmin@gmail.com'
};

(function () {
    var cfg = window.SITE_CONFIG;
    // Inside the browser extension: no remote scripts are allowed (and ads are not
    // permitted in extension pages), so ads, analytics and the service worker are off.
    var isExtension = /^(chrome|moz|safari-web)-extension:$/.test(location.protocol);
    window.GP_IS_EXTENSION = isExtension;
    // Pro customers never see ads (same check as pro.js, done early so no ad script loads).
    var isPro = false;
    try {
        var pro = JSON.parse(localStorage.getItem('gp-pro') || 'null');
        isPro = !!(pro && pro.key && pro.instanceId && (Date.now() - (pro.checkedAt || 0)) / 864e5 <= 30);
    } catch (e) { /* storage blocked: treat as free */ }
    var hasAds = !isExtension && !isPro && /^ca-pub-\d{16}$/.test(cfg.adsenseClient || '');

    // Theme: share the tool's saved preference across every page.
    try {
        var t = localStorage.getItem('acv7-theme');
        if (t === 'dark') document.documentElement.setAttribute('data-theme', 'dark');
    } catch (e) { /* storage blocked: default theme */ }

    // ---- Google Consent Mode v2 -------------------------------------------
    // Denied by default in the EEA, UK and Switzerland until the visitor answers
    // the consent message. Turn on AdSense > Privacy & messaging > "European
    // regulations" message: it is a Google-certified CMP and updates these flags.
    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || function () { window.dataLayer.push(arguments); };
    var EEA = ['AT','BE','BG','HR','CY','CZ','DK','EE','FI','FR','DE','GR','HU','IS','IE','IT','LV','LI','LT','LU','MT','NL','NO','PL','PT','RO','SK','SI','ES','SE','GB','CH'];
    gtag('consent', 'default', {
        ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied',
        analytics_storage: 'denied', wait_for_update: 500, region: EEA
    });
    gtag('consent', 'default', {
        ad_storage: 'granted', ad_user_data: 'granted', ad_personalization: 'granted',
        analytics_storage: 'granted'
    });

    function addScript(src, attrs) {
        var s = document.createElement('script');
        s.async = true; s.src = src;
        if (attrs) for (var k in attrs) s.setAttribute(k, attrs[k]);
        document.head.appendChild(s);
    }

    // ---- Google Analytics 4 -------------------------------------------------
    if (cfg.ga4 && !isExtension) {
        addScript('https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(cfg.ga4));
        gtag('js', new Date());
        gtag('config', cfg.ga4);
    }

    // ---- Google AdSense -----------------------------------------------------
    if (hasAds) {
        addScript('https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' +
            encodeURIComponent(cfg.adsenseClient), { crossorigin: 'anonymous' });
    }

    // Installable app: offline support via the service worker (website only).
    if (!isExtension && 'serviceWorker' in navigator && (location.protocol === 'https:' || location.hostname === 'localhost')) {
        window.addEventListener('load', function () { navigator.serviceWorker.register('/studios/animation/sw.js').catch(function () {}); });
    }

    // "Install app" button: shown when the browser offers installation.
    var deferredInstall = null;
    window.addEventListener('beforeinstallprompt', function (e) {
        e.preventDefault(); deferredInstall = e;
        document.querySelectorAll('[data-install]').forEach(function (b) { b.hidden = false; });
    });
    window.addEventListener('appinstalled', function () {
        deferredInstall = null;
        document.querySelectorAll('[data-install]').forEach(function (b) { b.hidden = true; });
    });

    document.addEventListener('DOMContentLoaded', function () {
        // Ad slots: <div class="ad-slot" data-ad="top"></div>
        document.querySelectorAll('.ad-slot').forEach(function (box) {
            var slot = cfg.adSlots[box.getAttribute('data-ad')];
            if (!hasAds || !slot) { box.remove(); return; }
            var ins = document.createElement('ins');
            ins.className = 'adsbygoogle';
            ins.style.display = 'block';
            ins.setAttribute('data-ad-client', cfg.adsenseClient);
            ins.setAttribute('data-ad-slot', slot);
            ins.setAttribute('data-ad-format', 'auto');
            ins.setAttribute('data-full-width-responsive', 'true');
            box.appendChild(ins);
            try { (window.adsbygoogle = window.adsbygoogle || []).push({}); } catch (e) { /* blocked */ }
        });

        // Tip-jar links
        document.querySelectorAll('[data-support]').forEach(function (el) {
            if (cfg.supportUrl) { el.href = cfg.supportUrl; el.hidden = false; }
            else el.remove();
        });

        // Contact email
        document.querySelectorAll('[data-contact]').forEach(function (el) {
            el.href = 'mailto:' + cfg.contactEmail;
            el.textContent = cfg.contactEmail;
        });

        document.querySelectorAll('[data-install]').forEach(function (b) {
            b.addEventListener('click', function () {
                if (!deferredInstall) { location.href = '/studios/animation/get-the-app.html'; return; }
                deferredInstall.prompt();
                deferredInstall.userChoice.finally(function () { deferredInstall = null; b.hidden = true; });
            });
        });

        // Extension: pages that aren't bundled open on the website instead.
        if (isExtension) {
            var bundled = /^\/(index\.html|editor\.html|how-to-use\.html)?$/;
            document.querySelectorAll('a[href^="/studios/animation/"]').forEach(function (a) {
                var u = new URL(a.getAttribute('href'), 'https://goldenpaw.dog/studios/animation');
                if (!bundled.test(u.pathname)) { a.href = 'https://goldenpaw.dog/studios/animation' + u.pathname + u.search + u.hash; a.target = '_blank'; a.rel = 'noopener'; }
            });
            document.querySelectorAll('[data-install]').forEach(function (b) { b.remove(); });
            // The extension is the free, ad-free edition: Pro and its AI live on the website and desktop app.
            var ai = document.getElementById('aiGroup'); if (ai) ai.remove();
            ['batchBox', 'presetSave', 'presetName'].forEach(function (id) { var el = document.getElementById(id); if (el) el.remove(); });
            document.querySelectorAll('a.nav-pro').forEach(function (a) { a.closest('li').remove(); });
        }

        // Footer year
        document.querySelectorAll('[data-year]').forEach(function (el) { el.textContent = new Date().getFullYear(); });

        // Theme toggle on content pages (the tool page has its own).
        var tt = document.getElementById('siteThemeToggle');
        if (tt) {
            var sync = function () { tt.textContent = document.documentElement.getAttribute('data-theme') === 'dark' ? '☀️' : '🌙'; };
            sync();
            tt.addEventListener('click', function () {
                var dark = document.documentElement.getAttribute('data-theme') === 'dark';
                if (dark) document.documentElement.removeAttribute('data-theme');
                else document.documentElement.setAttribute('data-theme', 'dark');
                try { localStorage.setItem('acv7-theme', dark ? 'light' : 'dark'); } catch (e) {}
                sync();
            });
        }

        // Track successful exports as GA4 events (if analytics is on).
        if (cfg.ga4 && !isExtension) {
            document.addEventListener('click', function (e) {
                var a = e.target.closest && e.target.closest('a.download-btn');
                if (a) gtag('event', 'file_download', { file_name: a.getAttribute('download') || '', kind: a.getAttribute('data-kind') || '' });
            });
        }
    });
})();
