def add_import(filepath, imp):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    
    if imp not in content:
        lines = content.split("\n")
        last_import = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                last_import = i
        lines.insert(last_import + 1, imp)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))

add_import("lib/create_ad_page.dart", "import 'src/app_widgets.dart';")
add_import("lib/screens/faucet_page.dart", "import '../widgets/bonus_timer_dialog.dart';")

print("Fixed the final two imports!")
