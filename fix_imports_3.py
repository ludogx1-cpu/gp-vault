import os

def inject(filepath, imports):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    for imp in imports:
        if imp not in content:
            content = imp + "\n" + content
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

inject('lib/screens/landing_page.dart', [
    "import '../src/theme_provider.dart';",
    "import '../widgets/feature_card.dart';"
])

inject('lib/widgets/app_drawer.dart', [
    "import 'dart:math';",
    "import 'platform_indicator_level_text.dart';",
    "import '../screens/ptc_earn_page.dart';",
    "import '../screens/referral_page.dart';",
    "import '../screens/ad_hub_page.dart';",
    "import '../screens/affiliate_links_page.dart';",
    "import '../screens/offerwall_hub_page.dart';",
    "import '../screens/admin_dashboard_page.dart';"
])

inject('lib/widgets/app_footer.dart', [
    "import 'package:web/web.dart' as web;",
    "import '../screens/terms_of_service_page.dart';",
    "import '../screens/privacy_policy_page.dart';",
    "import '../screens/cookie_policy_page.dart';",
    "import '../screens/faq_page.dart';",
    "import '../screens/contact_page.dart';"
])

inject('lib/widgets/auth_dialog.dart', [
    "import 'auth_dialog_widget.dart';"
])

inject('lib/widgets/auth_dialog_widget.dart', [
    "import 'package:web/web.dart' as web;",
    "import 'dart:js_interop';",
    "import '../src/js_bindings.dart';"
])

inject('lib/widgets/bonus_timer_dialog.dart', [
    "import '../src/js_bindings.dart';"
])

inject('lib/widgets/ptc_timer_dialog.dart', [
    "import '../src/js_bindings.dart';"
])

print("Third batch of widget fixes applied!")
