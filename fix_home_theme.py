import os
import re

file_path = r'd:\HERALD\FYP\smart_kisan\lib\home_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace hardcoded colors with Theme colors
replacements = {
    # Text colors
    r'color:\s*_darkGray': 'color: Theme.of(context).textTheme.bodyLarge?.color',
    r'color:\s*_gray': 'color: Theme.of(context).textTheme.bodyMedium?.color',
    r'color:\s*_black': 'color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black',
    
    # Backgrounds and borders
    r'color:\s*_white': 'color: Theme.of(context).cardColor',
    
    # Theme colors
    r'color:\s*_primaryGreen': 'color: Theme.of(context).colorScheme.primary',
    r'color:\s*_accentGreen': 'color: Theme.of(context).colorScheme.primary',
    r'color:\s*_darkGreen': 'color: Theme.of(context).colorScheme.primary',
    r'color:\s*_lightGreen': 'color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)',
    r'color:\s*_lightText': 'color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)',
    
    # Strip const where Theme.of is injected inside const Text/BoxDecoration etc.
    r'const\s+TextStyle\(\s*color:\s*Theme\.of\(context\)': 'TextStyle(color: Theme.of(context)',
    r'const\s+BoxDecoration\(\s*color:\s*Theme\.of\(context\)': 'BoxDecoration(color: Theme.of(context)',
    r'const\s+BorderSide\(\s*color:\s*Theme\.of\(context\)': 'BorderSide(color: Theme.of(context)',
    r'const\s+Icon\([^,]+,\s*color:\s*Theme\.of\(context\)': lambda m: m.group(0).replace('const ', ''),
    r'const\s+Icon\([^,]+,\s*size:[^,]+,\s*color:\s*Theme\.of\(context\)': lambda m: m.group(0).replace('const ', ''),
    
    # In Home Page there is a gradient card for weather:
    # "decoration: BoxDecoration( gradient: LinearGradient( colors: [_primaryGreen, _darkGreen] ) )"
    r'\[_primaryGreen,\s*_darkGreen\]': '[Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary]',
}

for pattern, replacement in replacements.items():
    if callable(replacement):
        content = re.sub(pattern, replacement, content)
    else:
        content = re.sub(pattern, replacement, content)

# Try to remove 'const ' keyword globally on same line as Theme.of(context)
lines = content.split('\n')
new_lines = []
for line in lines:
    if 'Theme.of(context)' in line and 'const ' in line:
        line = line.replace('const ', '')
    new_lines.append(line)

content = '\n'.join(new_lines)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Home page updated!')
