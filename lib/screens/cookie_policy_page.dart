import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../src/admob_service.dart';
import '../src/analytics.dart';
import 'privacy_policy_page.dart';

class CookiePolicyPage extends StatelessWidget {
  const CookiePolicyPage({super.key});

  static const String _webSummary =
      "Always on (needed for the site to work): your login session, app settings such as dark mode and your saved payout address, "
      "security and captcha cookies from Cloudflare, hCaptcha and Google, and a cookie that remembers your cookie choices.\n\n"
      "Only with your consent: Google Analytics, Google Tag Manager and Firebase Analytics (statistics), and AdRoll and the Facebook Pixel (personalised advertising). "
      "These are not loaded until you agree in the cookie banner.\n\n"
      "Some adverts (Google AdSense, Adsterra, BitcoTasks) may set their own cookies when they load. Google ads follow your choice and show "
      "non-personalised ads if you say no.\n\n"
      "You can change your choices at any time with the \"Change cookie settings\" button in our Privacy Policy.";

  static const String _appSummary =
      "Always on (needed for the app to work): your login session, app settings such as dark mode and your saved payout address, "
      "security checks (captchas and Google Play Integrity), and notifications if you allow them.\n\n"
      "Only with your consent: anonymous usage statistics (Google Analytics). Use the switch below to turn this on or off at any time.\n\n"
      "Adverts are shown by Google AdMob. If you are in the UK or EU, Google asks for your ad choices the first time you open the app, "
      "and you can change them with the button below.";

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return PolicySummaryPage(
        title: "Cookies",
        summary: _webSummary,
        buttonLabel: "Change cookie settings",
        url: '$fullPrivacyPolicyUrl#cookies',
      );
    }
    return const PolicySummaryPage(
      title: "Cookies & privacy",
      summary: _appSummary,
      extra: _AppPrivacyChoices(),
    );
  }
}

/// App-only privacy controls: analytics opt-in and Google's ad choices form.
class _AppPrivacyChoices extends StatefulWidget {
  const _AppPrivacyChoices();

  @override
  State<_AppPrivacyChoices> createState() => _AppPrivacyChoicesState();
}

class _AppPrivacyChoicesState extends State<_AppPrivacyChoices> {
  bool _analytics = appAnalyticsChoice == true;
  bool _adChoicesAvailable = false;

  @override
  void initState() {
    super.initState();
    AdMobService.privacyOptionsRequired().then((required) {
      if (mounted) setState(() => _adChoicesAvailable = required);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.amber,
          title: const Text("Anonymous usage statistics"),
          subtitle: const Text("Google Analytics. Helps us see which features are used."),
          value: _analytics,
          onChanged: (value) async {
            setState(() => _analytics = value);
            await setAppAnalyticsConsent(value);
          },
        ),
        if (_adChoicesAvailable)
          OutlinedButton.icon(
            onPressed: AdMobService.showPrivacyOptions,
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text("Ad privacy choices"),
          ),
      ],
    );
  }
}
