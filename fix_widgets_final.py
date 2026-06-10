import glob
import re

# Add imports to specific files
def inject(filepath, imports):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    for imp in imports:
        if imp not in content:
            content = imp + "\n" + content
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

inject('lib/widgets/auth_dialog_widget.dart', [
    "import 'dart:convert';",
    "import 'dart:async';",
    "import 'package:shared_preferences/shared_preferences.dart';",
    "import 'package:pointer_interceptor/pointer_interceptor.dart';",
])

inject('lib/widgets/live_referral_tracker.dart', [
    "import 'dart:async';",
    "import 'package:http/http.dart' as http;",
    "import 'dart:convert';",
    "import 'package:web/web.dart' as web;"
])

inject('lib/widgets/global_app_bar.dart', [
    "import 'live_referral_tracker.dart';",
    "import 'wallet_dropdown_button.dart';"
])

inject('lib/widgets/banner_ad_placeholder.dart', [
    "import 'dart:math';",
    "import 'package:web/web.dart' as web;",
    "import 'smart_fallback_ad.dart';"
])

inject('lib/widgets/page_with_footer.dart', [
    "import 'app_footer.dart';"
])

inject('lib/widgets/interstitial_ad_dialog.dart', [
    "import 'dart:async';",
    "import 'package:web/web.dart' as web;",
    "import 'package:pointer_interceptor/pointer_interceptor.dart';",
    "import 'smart_fallback_ad.dart';"
])

inject('lib/widgets/bonus_timer_dialog.dart', [
    "import 'root_gatekeeper.dart';"
])

inject('lib/widgets/ptc_timer_dialog.dart', [
    "import 'root_gatekeeper.dart';"
])

inject('lib/widgets/smart_fallback_ad.dart', [
    "import '../screens/affiliate_links_page.dart';"
])

inject('lib/widgets/live_interest_display.dart', [
    "import 'root_gatekeeper.dart';"
])

# Purge `void main() async { ... }` from any file in widgets/
def purge_main_block(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Regex to find `void main() async { ... }` where it matches until the first line that is `// ==========================================`
    # Since main is huge, we can just split and remove it manually.
    if "void main() async {" in content:
        start_idx = content.find("void main() async {")
        end_idx = content.find("// ==========================================", start_idx)
        if end_idx != -1:
            content = content[:start_idx] + content[end_idx:]
        else:
            # If no separator, just remove the whole block roughly
            pass
            
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for f in glob.glob('lib/widgets/*.dart'):
    purge_main_block(f)

print("Widget fixes applied!")
