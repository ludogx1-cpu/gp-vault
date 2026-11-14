// Golden Paw consent gate.
//
// The Cloudflare Zaraz cookie banner (IAB TCF purposes) is the single place
// visitors make choices. Until they agree:
//  - Google Consent Mode v2 is "denied", so Google tags set no cookies;
//  - Google Analytics hits are switched off with the ga-disable flags;
//  - Google Tag Manager, gtag.js and AdRoll are not loaded at all.
// Pages register loaders with gpConsent.onAnalytics / gpConsent.onPersonalisedAds.
(function (w, d) {
  var MEASUREMENT_IDS = ['G-H0R68LWSK6', 'G-HKKG25EDQW'];

  w.dataLayer = w.dataLayer || [];
  if (typeof w.gtag !== 'function') {
    w.gtag = function () { w.dataLayer.push(arguments); };
  }
  var gtag = w.gtag;

  gtag('consent', 'default', {
    ad_storage: 'denied',
    ad_user_data: 'denied',
    ad_personalization: 'denied',
    analytics_storage: 'denied',
    functionality_storage: 'granted',
    personalization_storage: 'denied',
    security_storage: 'granted',
    wait_for_update: 500
  });
  gtag('set', 'ads_data_redaction', true);
  gtag('set', 'url_passthrough', false);
  setAnalyticsDisabled(true);

  var queues = { analytics: [], personalisedAds: [] };
  var started = { analytics: false, personalisedAds: false };

  function setAnalyticsDisabled(disabled) {
    MEASUREMENT_IDS.forEach(function (id) { w['ga-disable-' + id] = disabled; });
  }

  function run(fn) {
    try { fn(); } catch (e) { console.error('Consent loader failed:', e); }
  }

  function start(kind) {
    if (started[kind]) return;
    started[kind] = true;
    queues[kind].forEach(run);
  }

  function clearCookies(prefixes) {
    var host = w.location.hostname;
    var domains = ['', host, '.' + host, '.' + host.split('.').slice(-2).join('.')];
    d.cookie.split(';').forEach(function (entry) {
      var name = entry.split('=')[0].trim();
      var match = prefixes.some(function (prefix) { return name.indexOf(prefix) === 0; });
      if (!match) return;
      domains.forEach(function (domain) {
        d.cookie = name + '=; Max-Age=0; path=/' + (domain ? '; domain=' + domain : '');
      });
    });
  }

  function readChoices() {
    var api = w.zaraz && w.zaraz.consent;
    if (!api || typeof api.getAll !== 'function') return null;
    return api.getAll() || {};
  }

  function apply() {
    var c = readChoices();
    if (!c) return;
    var device = !!c['tcf-purposes-1'];
    var analytics = device && !!(c['tcf-purposes-9'] || c['tcf-purposes-10']);
    var ads = device && !!(c['tcf-purposes-2'] || c['tcf-purposes-7']);
    var personalised = ads && !!(c['tcf-purposes-3'] && c['tcf-purposes-4']);

    gtag('consent', 'update', {
      analytics_storage: analytics ? 'granted' : 'denied',
      ad_storage: ads ? 'granted' : 'denied',
      ad_user_data: ads ? 'granted' : 'denied',
      ad_personalization: personalised ? 'granted' : 'denied',
      personalization_storage: personalised ? 'granted' : 'denied'
    });
    setAnalyticsDisabled(!analytics);

    if (analytics) start('analytics');
    else clearCookies(['_ga', '_gid']);

    if (personalised) start('personalisedAds');
    if (!ads) clearCookies(['_gcl', '__adroll', '__ar_v4']);
  }

  w.gpConsent = {
    onAnalytics: function (fn) {
      queues.analytics.push(fn);
      if (started.analytics) run(fn);
    },
    onPersonalisedAds: function (fn) {
      queues.personalisedAds.push(fn);
      if (started.personalisedAds) run(fn);
    },
    openSettings: function () {
      if (w.zaraz && typeof w.zaraz.showConsentModal === 'function') {
        w.zaraz.showConsentModal();
        return true;
      }
      return false;
    },
    apply: apply
  };

  d.addEventListener('zarazConsentAPIReady', apply);
  d.addEventListener('zarazConsentChoicesUpdated', apply);
  function applyIfReady() {
    if (w.zaraz && w.zaraz.consent && w.zaraz.consent.APIReady) apply();
  }
  applyIfReady();
  d.addEventListener('DOMContentLoaded', applyIfReady);
  w.addEventListener('load', applyIfReady);
})(window, document);
