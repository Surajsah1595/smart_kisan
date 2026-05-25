import os
import re

file_path = r'd:\HERALD\FYP\smart_kisan\lib\pest_disease_help.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace hardcoded colors with Theme colors
replacements = {
    # Texts
    r'color:\s*const Color\(0xFF354152\)': 'color: Theme.of(context).textTheme.bodyMedium?.color',
    r'color:\s*Color\(0xFF354152\)': 'color: Theme.of(context).textTheme.bodyMedium?.color',
    r'color:\s*const Color\(0xE5FFFEFE\)': 'color: Theme.of(context).textTheme.bodyMedium?.color',
    r'color:\s*Color\(0xE5FFFEFE\)': 'color: Theme.of(context).textTheme.bodyMedium?.color',
    
    # App Bar background
    r'color:\s*const Color\(0xFFFB2C36\)': 'color: Theme.of(context).colorScheme.surface',
    r'color:\s*Color\(0xFFFB2C36\)': 'color: Theme.of(context).colorScheme.primary',
    
    # Arrow icon
    r'icon:\s*const Icon\(Icons\.arrow_back,\s*color:\s*Colors\.white\)': 'icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary)',
    
    # Text colors that were set to white/cardColor due to dark background
    r'color:\s*Theme\.of\(context\)\.cardColor,\s*fontSize:\s*24,': 'color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 24,',
    r'color:\s*Theme\.of\(context\)\.cardColor,\s*fontSize:\s*20,': 'color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20,',
    r'color:\s*Theme\.of\(context\)\.colorScheme\.onPrimary\.withValues\(alpha:\s*0\.9\)': 'color: Theme.of(context).textTheme.bodyMedium?.color',
    
    # Gradients
    r'colors:\s*\[Color\(0xFFFB2C36\),\s*Color\(0xFFE7000B\)\]': 'colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface]',
    r'colors:\s*\[Color\(0xFFF2F4F6\),\s*Color\(0xFFE5E7EB\)\]': 'colors: [Theme.of(context).cardColor, Theme.of(context).cardColor]',
    
    # Buttons and accents
    r'backgroundColor:\s*Colors\.white': 'backgroundColor: Theme.of(context).colorScheme.primary',
    r'color:\s*Color\(0xFFFB2C36\),\s*fontSize:\s*16,': 'color: Theme.of(context).colorScheme.onPrimary, fontSize: 16,',
    r'Icon\(Icons\.camera_alt,\s*color:\s*Color\(0xFFFB2C36\)\)': 'Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onPrimary)',
    
    # General Containers
    r'color:\s*const Color\(0xFFF3F4F6\)': 'color: Theme.of(context).scaffoldBackgroundColor',
    r'color:\s*Color\(0xFFF3F4F6\)': 'color: Theme.of(context).scaffoldBackgroundColor',
    
    # Remove const from BoxDecorations/TextStyles that now have Theme.of(context)
    r'const\s+BoxDecoration\(\s*color:\s*Theme\.of\(context\)': 'BoxDecoration(color: Theme.of(context)',
    r'const\s+TextStyle\(\s*color:\s*Theme\.of\(context\)': 'TextStyle(color: Theme.of(context)',
    r'const\s+LinearGradient': 'LinearGradient',
    r'Icon\(Icons\.bug_report,\s*color:\s*Theme\.of\(context\)\.cardColor,\s*size:\s*20\)': 'Icon(Icons.bug_report, color: Theme.of(context).colorScheme.primary, size: 20)',
    r'Icon\(Icons\.arrow_back,\s*color:\s*Colors\.white\)': 'Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary)',
    
    # Scaffold
    r'return Scaffold\(\s*body:': 'return Scaffold(\n      backgroundColor: Theme.of(context).scaffoldBackgroundColor,\n      body:',
}

for pattern, replacement in replacements.items():
    if callable(replacement):
        content = re.sub(pattern, replacement, content)
    else:
        content = re.sub(pattern, replacement, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Pest disease help updated!')
