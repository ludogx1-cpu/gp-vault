import os

with open("lib/src/app_widgets.dart", "r", encoding="utf-8") as f:
    content = f.read()

# We will extract blocks starting with "class " or "void showAuthDialogGlobal"
# and we will match curly braces to find the end of the block.

def extract_blocks(text):
    blocks = []
    i = 0
    while i < len(text):
        # Look for class or showAuthDialogGlobal
        if text.startswith("class ", i) or text.startswith("void showAuthDialogGlobal", i):
            start = i
            # Find the opening brace
            brace_idx = text.find("{", start)
            if brace_idx == -1:
                break
            
            # Match braces
            brace_count = 1
            curr = brace_idx + 1
            while curr < len(text) and brace_count > 0:
                if text[curr] == "{":
                    brace_count += 1
                elif text[curr] == "}":
                    brace_count -= 1
                curr += 1
            
            blocks.append(text[start:curr])
            i = curr
        else:
            i += 1
    return blocks

blocks = extract_blocks(content)
print(f"Found {len(blocks)} blocks.")

# We will group related classes.
# Map of primary class -> related state classes
# Or simply create a file for each class if it doesn't start with '_'
# If it starts with '_', we append it to the previous file.

files = {}
current_file = None

for block in blocks:
    # Get the name of the block
    if block.startswith("class "):
        name = block[6:].split(" ")[0].split("{")[0].split("extends")[0].split("implements")[0].strip()
    elif block.startswith("void showAuthDialogGlobal"):
        name = "showAuthDialogGlobal"
    
    if name.startswith("_") and current_file:
        files[current_file] += "\n\n" + block
    else:
        # Determine filename
        # Convert CamelCase to snake_case
        import re
        if name == "showAuthDialogGlobal":
            filename = "auth_dialog"
        else:
            s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
            filename = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()
        
        current_file = filename
        files[current_file] = block

os.makedirs("lib/widgets", exist_ok=True)
os.makedirs("lib/screens", exist_ok=True)

# Common imports for the new files
common_imports = """import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../theme_provider.dart';
import '../main.dart';
import '../firebase_service.dart';
"""

for filename, code in files.items():
    if filename == "landing_page":
        filepath = f"lib/screens/{filename}.dart"
    else:
        filepath = f"lib/widgets/{filename}.dart"
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(common_imports + "\n" + code + "\n")
    
    print(f"Created {filepath}")

