import os
import re

# Fix main.dart
main_file = "lib/main.dart"
with open(main_file, "r", encoding="utf-8") as f:
    main_content = f.read()

main_content = main_content.replace("part 'src/app_widgets.dart';", "import 'src/app_widgets.dart';")
with open(main_file, "w", encoding="utf-8") as f:
    f.write(main_content)

# Fix app_widgets.dart
app_widgets_file = "lib/src/app_widgets.dart"
with open(app_widgets_file, "r", encoding="utf-8") as f:
    app_content = f.read()

app_content = app_content.replace("import 'src/theme_provider.dart';", "import 'theme_provider.dart';")
app_content = app_content.replace("import 'src/firebase_service.dart';", "import 'firebase_service.dart';")
app_content = app_content.replace("import 'create_ad_page.dart';", "import '../create_ad_page.dart';")
app_content = app_content.replace("import 'screens/", "import '../screens/")
app_content = app_content.replace("import 'widgets/", "import '../widgets/")

with open(app_widgets_file, "w", encoding="utf-8") as f:
    f.write(app_content)

print("Imports fixed in main.dart and app_widgets.dart")
