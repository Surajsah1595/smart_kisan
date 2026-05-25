import os
import re

file_path = r'd:\HERALD\FYP\smart_kisan\lib\settings.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace hardcoded colors with Theme colors
replacements = {
    r'const Color _lightGreen = Color\(0xFFDCFCE7\);': '',
    r'Color _darkGreen = Color\(0xFF00C950\);': '',
    r'const Color _white = Colors\.white;': '',
    r'const Color _black = Colors\.black;': '',
    r'const Color _gray = Color\(0xFF4A5565\);': '',
    r'const Color _lightGray = Color\(0xFFF9FAFB\);': '',
    r'const Color _borderGray = Color\(0xFFE5E7EB\);': '',
    r'const Color _textDark = Color\(0xFF101727\);': '',
    r'const Color _textGray = Color\(0xFF495565\);': '',
    r'const Color _textLightGray = Color\(0xFF354152\);': '',
    r'const Color _red = Color\(0xFFE7000B\);': '',
    
    # Text colors
    r'color:\s*_textDark': 'color: Theme.of(context).textTheme.bodyLarge?.color',
    r'color:\s*_textGray': 'color: Theme.of(context).textTheme.bodyMedium?.color',
    r'color:\s*_textLightGray': 'color: Theme.of(context).textTheme.bodySmall?.color',
    
    # Backgrounds and borders
    r'color:\s*_white': 'color: Theme.of(context).cardColor',
    r'color:\s*_lightGray': 'color: Theme.of(context).scaffoldBackgroundColor',
    r'color:\s*_borderGray': 'color: Theme.of(context).dividerColor',
    
    # Greens to Primary
    r'color:\s*_darkGreen': 'color: Theme.of(context).colorScheme.primary',
    r'color:\s*_lightGreen': 'color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)',
    
    # Fix the remaining static colors in gradients/shadows
    r'_darkGreen': 'Theme.of(context).colorScheme.primary',
    r'_black': 'Colors.black',
    r'_red': 'Colors.red',
    
    r'Color\(0xFF00C950\)': 'Theme.of(context).colorScheme.primary',
    r'Color\(0xFFDCFCE7\)': 'Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)',
    
    # Strip const where Theme.of is injected inside const Text/BoxDecoration etc.
    r'const\s+TextStyle\(\s*color:\s*Theme\.of\(context\)': 'TextStyle(color: Theme.of(context)',
    r'const\s+BoxDecoration\(\s*color:\s*Theme\.of\(context\)': 'BoxDecoration(color: Theme.of(context)',
    r'const\s+BorderSide\(\s*color:\s*Theme\.of\(context\)': 'BorderSide(color: Theme.of(context)',
    r'const\s+Icon\([^,]+,\s*color:\s*Theme\.of\(context\)': lambda m: m.group(0).replace('const ', ''),
    
    # Fix gradients that might now be invalid const
    r'const\s+LinearGradient\(\s*begin': 'LinearGradient(begin',
    r'const\s+LinearGradient\(\s*colors': 'LinearGradient(colors',
}

for pattern, replacement in replacements.items():
    if callable(replacement):
        content = re.sub(pattern, replacement, content)
    else:
        content = re.sub(pattern, replacement, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Settings updated!')
