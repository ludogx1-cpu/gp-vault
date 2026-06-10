import os

def inject(filepath, imports):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    for imp in imports:
        if imp not in content:
            content = imp + "\n" + content
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# 1. Fix ad_hub_page.dart
with open('lib/screens/ad_hub_page.dart', 'r', encoding='utf-8') as f:
    adhub = f.read()
adhub = adhub.replace("import '../create_ad_page.dart';", "import 'create_ad_page.dart';")
with open('lib/screens/ad_hub_page.dart', 'w', encoding='utf-8') as f:
    f.write(adhub)

# 2. Fix faucet_page.dart
inject('lib/screens/faucet_page.dart', [
    "import '../src/js_bindings.dart';"
])

# 3. Fix landing_page.dart
with open('lib/screens/landing_page.dart', 'r', encoding='utf-8') as f:
    landing = f.read()
landing = landing.replace("import '../theme_provider.dart';", "import '../src/theme_provider.dart';")
landing = landing.replace("import '../firebase_service.dart';", "import '../src/firebase_service.dart';")
with open('lib/screens/landing_page.dart', 'w', encoding='utf-8') as f:
    f.write(landing)

inject('lib/screens/landing_page.dart', [
    "import '../widgets/global_app_bar.dart';",
    "import '../widgets/page_with_footer.dart';"
])

print("Final round of fixes applied!")
