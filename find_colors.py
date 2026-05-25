import os
import re

files = [
    r'd:\HERALD\FYP\smart_kisan\lib\welcome_screen.dart',
    r'd:\HERALD\FYP\smart_kisan\lib\home_page.dart',
    r'd:\HERALD\FYP\smart_kisan\lib\pest_disease_help.dart'
]

for file in files:
    print(f"\n--- Colors in {os.path.basename(file)} ---")
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines):
        if re.search(r'Color\(|Colors\.[a-zA-Z]', line):
            print(f"L{i+1}: {line.strip()}")
