import 'package:flutter/material.dart';
import 'privacy_policy_page.dart';

class CookiePolicyPage extends StatelessWidget {
  const CookiePolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicySummaryPage(
      title: "Cookies",
      summary:
          "Always on (needed for the site to work): your login session, app settings such as dark mode and your saved payout address, "
          "security and captcha cookies from Cloudflare, hCaptcha and Google, and a cookie that remembers your cookie choices.\n\n"
          "Only with your consent: Google Analytics, Google Tag Manager and Firebase Analytics (statistics), and AdRoll (personalised advertising). "
          "These are not loaded until you agree in the cookie banner.\n\n"
          "Some adverts (Google AdSense, Adsterra, BitcoTasks) may set their own cookies when they load. Google ads follow your choice and show "
          "non-personalised ads if you say no.\n\n"
          "You can change your choices at any time with the \"Change cookie settings\" button in our Privacy Policy.",
      buttonLabel: "Change cookie settings",
      url: '$fullPrivacyPolicyUrl#cookies',
    );
  }
}
