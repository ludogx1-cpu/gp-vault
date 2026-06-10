import os
import glob
import shutil

# 1. Create lib/widgets/widgets.dart barrel file
widget_files = [f for f in os.listdir('lib/widgets') if f.endswith('.dart') and f != 'widgets.dart']
exports = "\n".join([f"export '{f}';" for f in widget_files])
with open('lib/widgets/widgets.dart', 'w', encoding='utf-8') as f:
    f.write(exports + "\n")

# 2. Update imports in all screens
screen_files = glob.glob('lib/screens/*.dart')
for sf in screen_files:
    with open(sf, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("import '../src/app_widgets.dart';", "import '../widgets/widgets.dart';")
    with open(sf, 'w', encoding='utf-8') as f:
        f.write(content)

# 3. Update main.dart
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    main_content = f.read()
main_content = main_content.replace("import 'src/app_widgets.dart';", "import 'widgets/widgets.dart';")

# Extract theme constants from main.dart
theme_consts = """
// --- GLOBAL THEME CONSTANTS 🚀 ---
const kAppBarColor = Colors.black87;
const kAppBarIconColor = Colors.amber;
const kAppBarLogoColor = Colors.white;
const kTextColorOnBlack = Colors.white;

Color gpBrownText(BuildContext context, {Color darkColor = Colors.white70}) {
  return themeProvider.isDarkMode ? darkColor : Colors.brown;
}
"""
main_content = main_content.replace(theme_consts, "")
with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(main_content)

# 4. Add theme constants to theme_provider.dart
with open('lib/src/theme_provider.dart', 'r', encoding='utf-8') as f:
    theme_content = f.read()
if "kAppBarColor" not in theme_content:
    theme_content += "\n" + theme_consts
with open('lib/src/theme_provider.dart', 'w', encoding='utf-8') as f:
    f.write(theme_content)

# 5. Move create_ad_page.dart
if os.path.exists('lib/create_ad_page.dart'):
    with open('lib/create_ad_page.dart', 'r', encoding='utf-8') as f:
        cad_content = f.read()
    cad_content = cad_content.replace("import 'src/app_widgets.dart';", "import '../widgets/widgets.dart';")
    with open('lib/screens/create_ad_page.dart', 'w', encoding='utf-8') as f:
        f.write(cad_content)
    os.remove('lib/create_ad_page.dart')

# 6. Delete app_widgets.dart
if os.path.exists('lib/src/app_widgets.dart'):
    os.remove('lib/src/app_widgets.dart')

print("Refactoring step 2 complete!")
