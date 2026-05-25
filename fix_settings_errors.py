import os
import re

file_path = r'd:\HERALD\FYP\smart_kisan\lib\settings.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace undefined identifiers
replacements = {
    r'_white': 'Theme.of(context).cardColor',
    r'_black': 'Colors.black',
    r'_red': 'Colors.red',
    r'_gray': 'Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey',
    r'_borderGray': 'Theme.of(context).dividerColor.withOpacity(0.1)',
    r'_textDark': 'Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black',
    r'_textGray': 'Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey',
    r'_textLightGray': 'Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey',
    r'_darkGreen': 'Theme.of(context).colorScheme.primary',
    r'_lightGreen': 'Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)',
    r'_lightGray': 'Theme.of(context).scaffoldBackgroundColor',
    
    r'const\s+BoxDecoration\(\s*color:\s*Theme\.of\(context\)': 'BoxDecoration(color: Theme.of(context)',
    r'const\s+TextStyle\(\s*color:\s*Theme\.of\(context\)': 'TextStyle(color: Theme.of(context)',
    r'const\s+BorderSide\(\s*color:\s*Theme\.of\(context\)': 'BorderSide(color: Theme.of(context)',
    r'const\s+LinearGradient': 'LinearGradient',
    
    # And there was a const_eval_method_invocation: Methods can't be invoked in constant expressions
    # This means something like `const Icon(..., color: Theme.of(context)...)`
    r'const\s+Icon\([^,]+,\s*color:\s*Theme\.of\(context\)': lambda m: m.group(0).replace('const ', ''),
    r'const\s+Icon\([^,]+,\s*size:[^,]+,\s*color:\s*Theme\.of\(context\)': lambda m: m.group(0).replace('const ', ''),
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

print('Fixed errors!')
