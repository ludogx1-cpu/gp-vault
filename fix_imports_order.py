import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

imports = []
code = []

for line in lines:
    if line.startswith("import ") and "'" in line:
        imports.append(line)
    else:
        code.append(line)

# Also remove any empty lines that might have been left behind from the imports, but keep the rest
final_content = "".join(imports) + "\n" + "".join(code)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(final_content)

print("Imports moved to top of main.dart")
