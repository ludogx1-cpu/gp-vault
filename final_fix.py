import os
import glob
import re

# 1. Restore theme constants to theme_provider.dart
theme_consts = """
const kAppBarColor = Colors.black87;
const kAppBarIconColor = Colors.amber;
const kAppBarLogoColor = Colors.white;
const kTextColorOnBlack = Colors.white;

Color gpBrownText(BuildContext context, {Color darkColor = Colors.white70}) {
  return themeProvider.isDarkMode ? darkColor : Colors.brown;
}
"""
with open('lib/src/theme_provider.dart', 'r', encoding='utf-8') as f:
    tp_content = f.read()
if "kAppBarColor" not in tp_content:
    tp_content += "\n" + theme_consts
with open('lib/src/theme_provider.dart', 'w', encoding='utf-8') as f:
    f.write(tp_content)

# 2. Restore _authHeaders to firebase_service.dart
auth_headers_code = """
Future<Map<String, String>> _authHeaders() async {
  final headers = {'Content-Type': 'application/json'};
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final token = await user.getIdToken(true);
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}
"""
with open('lib/src/firebase_service.dart', 'r', encoding='utf-8') as f:
    fs_content = f.read()
if "_authHeaders" not in fs_content:
    fs_content += "\n" + auth_headers_code
    # make sure firebase_auth is imported
    if "import 'package:firebase_auth/firebase_auth.dart';" not in fs_content:
        fs_content = "import 'package:firebase_auth/firebase_auth.dart';\n" + fs_content
with open('lib/src/firebase_service.dart', 'w', encoding='utf-8') as f:
    f.write(fs_content)

# Make _authHeaders public -> getAuthHeaders
with open('lib/src/firebase_service.dart', 'r', encoding='utf-8') as f:
    fs_content = f.read()
fs_content = fs_content.replace("_authHeaders", "getAuthHeaders")
with open('lib/src/firebase_service.dart', 'w', encoding='utf-8') as f:
    f.write(fs_content)

# Replace all calls to _authHeaders() with getAuthHeaders() in all files
for f in glob.glob('lib/**/*.dart', recursive=True):
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    if "_authHeaders" in content:
        content = content.replace("_authHeaders()", "getAuthHeaders()")
        content = content.replace("_authHeaders", "getAuthHeaders")
        
        # Add import if missing
        if "getAuthHeaders" in content and "import '../src/firebase_service.dart';" not in content and "import 'src/firebase_service.dart';" not in content and f != "lib/src/firebase_service.dart":
            if f.startswith("lib/screens/") or f.startswith("lib/widgets/"):
                content = "import '../src/firebase_service.dart';\n" + content
            elif f == "lib/main.dart":
                content = "import 'src/firebase_service.dart';\n" + content
                
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)

# 3. Create lib/src/js_bindings.dart
js_bindings = """import 'dart:js_interop';

@JS('renderHCaptcha')
external void renderHCaptcha();

@JS('renderTurnstile')
external void renderTurnstile();
"""
with open('lib/src/js_bindings.dart', 'w', encoding='utf-8') as f:
    f.write(js_bindings)

# 4. Remove JS bindings from all other files
for f in glob.glob('lib/**/*.dart', recursive=True):
    if f.endswith("js_bindings.dart"): continue
    
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
        
    original = content
    content = re.sub(r"@JS\('renderHCaptcha'\)\s*external void renderHCaptcha\(\);", "", content)
    content = re.sub(r"@JS\('renderTurnstile'\)\s*external void renderTurnstile\(\);", "", content)
    
    if content != original:
        if f.startswith("lib/screens/") or f.startswith("lib/widgets/"):
            content = "import '../src/js_bindings.dart';\n" + content
        elif f == "lib/main.dart":
            content = "import 'src/js_bindings.dart';\n" + content
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)

# 5. Fix import '../src/app_widgets.dart' in bonus_timer_dialog, live_interest, ptc_timer
for f in glob.glob('lib/widgets/*.dart'):
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    content = content.replace("import '../src/app_widgets.dart';", "import 'widgets.dart';")
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)

# 6. Delete unused imports of app_widgets.dart from everywhere
for f in glob.glob('lib/**/*.dart', recursive=True):
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    content = content.replace("import '../src/app_widgets.dart';", "import '../widgets/widgets.dart';")
    content = content.replace("import 'src/app_widgets.dart';", "import 'widgets/widgets.dart';")
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)

print("Final fixes complete!")
