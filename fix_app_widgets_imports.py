import re

with open("lib/src/app_widgets.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

imports = ["import '../main.dart';\n"]
code = []

for line in lines:
    if line.startswith("import ") and "'" in line:
        imports.append(line)
    else:
        code.append(line)

final_content = "".join(imports) + "\n" + "".join(code)

with open("lib/src/app_widgets.dart", "w", encoding="utf-8") as f:
    f.write(final_content)

print("Fixed app_widgets.dart imports")
