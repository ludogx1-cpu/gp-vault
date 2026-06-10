import os
import glob

widget_files = glob.glob('lib/widgets/*.dart')
for wf in widget_files:
    if wf.endswith("widgets.dart"): continue
    with open(wf, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("import '../theme_provider.dart';", "import '../src/theme_provider.dart';")
    content = content.replace("import '../firebase_service.dart';", "import '../src/firebase_service.dart';")
    
    with open(wf, 'w', encoding='utf-8') as f:
        f.write(content)

print("Widget imports fixed!")
