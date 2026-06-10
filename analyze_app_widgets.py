import os
import re

with open("lib/src/app_widgets.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Find all classes and top-level functions (basic heuristic)
matches = re.finditer(r'^(class|void|Future|Widget|String|bool|int|double) ([A-Za-z0-9_]+)\(', content, re.MULTILINE)
functions = [m.group(2) for m in matches]

matches_classes = re.finditer(r'^class ([A-Za-z0-9_]+)', content, re.MULTILINE)
classes = [m.group(1) for m in matches_classes]

print("Functions:", functions)
print("Classes:", classes)
