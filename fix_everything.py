import os
import glob
import re

files_to_check = glob.glob('lib/**/*.dart', recursive=True)

theme_consts1 = """const kAppBarColor = Colors.black87;
const kAppBarIconColor = Colors.amber;
const kAppBarLogoColor = Colors.white;
const kTextColorOnBlack = Colors.white;

Color gpBrownText(BuildContext context, {Color darkColor = Colors.white70}) {
  return themeProvider.isDarkMode ? darkColor : Colors.brown;
}"""

theme_consts2 = """const kAppBarColor = Colors.black87;
const kAppBarIconColor = Colors.amber;
const kAppBarLogoColor = Colors.white;
const kTextColorOnBlack = Colors.white;

Color gpBrownText(BuildContext context, {Color darkColor = Colors.white70}) {
  return themeProvider.isDarkMode ? darkColor : Colors.brown;
}
"""

auth_headers_regex = r"Future<Map<String, String>> _authHeaders\(\) async \{.*?\n\}"

for f in files_to_check:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    modified = False
    if theme_consts1 in content:
        content = content.replace(theme_consts1, "")
        modified = True
    if theme_consts2 in content:
        content = content.replace(theme_consts2, "")
        modified = True
    
    # Remove _authHeaders
    new_content = re.sub(r"Future<Map<String, String>> _authHeaders\(\) async \{[\s\S]*?return headers;\n\}", "", content)
    if new_content != content:
        content = new_content
        modified = True
        
    if modified:
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)

# Add missing imports
def add_imports(filepath, imports):
    with open(filepath, 'r', encoding='utf-8') as file:
        lines = file.readlines()
    
    for imp in imports:
        if imp not in "".join(lines):
            lines.insert(0, imp + "\n")
            
    with open(filepath, 'w', encoding='utf-8') as file:
        file.writelines(lines)

add_imports('lib/widgets/root_gatekeeper.dart', [
    "import '../screens/landing_page.dart';",
    "import 'auth_dialog.dart';"
])

add_imports('lib/widgets/smart_fallback_ad.dart', [
    "import 'dart:math';",
    "import '../screens/ad_hub_page.dart';",
    "import 'package:web/web.dart' as web;"
])

add_imports('lib/widgets/square_ad_placeholder.dart', [
    "import 'dart:math';",
    "import 'smart_fallback_ad.dart';",
    "import 'package:web/web.dart' as web;"
])

add_imports('lib/widgets/wallet_dropdown_button.dart', [
    "import 'dart:async';"
])

add_imports('lib/widgets/interstitial_ad_dialog.dart', [
    "import 'dart:math';"
])

print("Fixed duplicate constants and missing imports!")
