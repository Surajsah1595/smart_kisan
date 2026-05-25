import os
import re

# 1. FIX WELCOME SCREEN
file_welcome = r'd:\HERALD\FYP\smart_kisan\lib\welcome_screen.dart'
with open(file_welcome, 'r', encoding='utf-8') as f:
    c_w = f.read()

# Make it theme-aware
replacements_w = {
    r'backgroundColor:\s*Colors\.white': 'backgroundColor: Theme.of(context).scaffoldBackgroundColor',
    r'const Color\(0xFFF3F3F3\)': 'Theme.of(context).dividerColor.withOpacity(0.1)',
    r'const Color\(0xFFA1A1A1\)': 'Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey',
    r'const Color\(0xFF2C7C48\)': 'Theme.of(context).colorScheme.primary',
    r'Colors\.white': 'Theme.of(context).cardColor',
    r'const Color\(0xFF1E1E1E\)': 'Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black',
    r'const Color\(0xFF9C9C9C\)': 'Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey',
    r'Colors\.black\.withValues\(alpha:\s*0\.4\)': 'Theme.of(context).shadowColor.withOpacity(0.4)',
    r'Colors\.black\.withValues\(alpha:\s*0\.3\)': 'Theme.of(context).shadowColor.withOpacity(0.3)',
    r'const Color\(0xFFE8F5E9\)': 'Theme.of(context).colorScheme.primary.withOpacity(0.1)',
    r'const Color\(0xFFFBFBFB\)': 'Theme.of(context).cardColor',
    r'const Color\(0xFFAFA5A5\)': 'Theme.of(context).dividerColor',
    r'const Color\(0xFF697282\)': 'Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey',
    r'const Color\(0x19000000\)': 'Theme.of(context).shadowColor.withOpacity(0.1)',
    r'const Color\(0x33FFFEFE\)': 'Theme.of(context).dividerColor.withOpacity(0.2)',
    r'const Color\(0xCCFFFEFE\)': 'Theme.of(context).textTheme.bodyMedium?.color',
}

for p, r in replacements_w.items():
    c_w = re.sub(p, r, c_w)

# Fix const issues created by substitutions
c_w = re.sub(r'const\s+TextStyle\(\s*color:\s*Theme\.of\(context\)', r'TextStyle(color: Theme.of(context)', c_w)
c_w = re.sub(r'const\s+BoxShadow\(\s*color:\s*Theme\.of\(context\)', r'BoxShadow(color: Theme.of(context)', c_w)
c_w = re.sub(r'const\s+BorderSide\(\s*width:[^,]+,\s*color:\s*Theme\.of\(context\)', lambda m: m.group(0).replace('const ', ''), c_w)
c_w = re.sub(r'color:\s*_selectedLanguage\s*!=\s*null\s*\?\s*Theme\.of\(context\)\.cardColor\s*:\s*Theme\.of\(context\)\.textTheme\.bodyMedium\?\.color\s*\?\?\s*Colors\.grey', r'color: _selectedLanguage != null ? Theme.of(context).cardColor : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)', c_w)

with open(file_welcome, 'w', encoding='utf-8') as f:
    f.write(c_w)


# 2. FIX HOME PAGE
file_home = r'd:\HERALD\FYP\smart_kisan\lib\home_page.dart'
with open(file_home, 'r', encoding='utf-8') as f:
    c_h = f.read()

replacements_h = {
    # Remove the hardcoded color declarations if they are there, or at least replace their usages.
    r'Colors\.black\.withValues\(alpha:\s*0\.1\)': 'Theme.of(context).shadowColor.withOpacity(0.1)',
    r'Colors\.black\.withValues\(alpha:\s*0\.6\)': 'Theme.of(context).shadowColor.withOpacity(0.6)',
    r'Color\(0xFF733E0A\)': 'Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black',
    r'const Color\(0xFFEFF6FF\)': 'Theme.of(context).dividerColor.withOpacity(0.1)',
    r'const Color\(0xFFFEF3F2\)': 'Theme.of(context).dividerColor.withOpacity(0.1)',
    r'const Color\(0xFFFEF9C2\)': 'Theme.of(context).dividerColor.withOpacity(0.1)',
    r'Color\(0xFF884A00\)': 'Theme.of(context).colorScheme.primary',
    r'Color\(0xFFD08700\)': 'Theme.of(context).colorScheme.primary',
    r'const Color\(0xFFFEEF85\)': 'Theme.of(context).dividerColor.withOpacity(0.1)',
    r'Color\(0xFFB8F7CF\)': 'Theme.of(context).dividerColor.withOpacity(0.1)',
    r'\[Color\(0xFFFDFBE8\),\s*Color\(0xFFFFF7EC\)\]': '[Theme.of(context).cardColor, Theme.of(context).cardColor]',
    r'\[Color\(0xFFF0B000\),\s*Color\(0xFFFF6800\)\]': '[Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary]',
    r'\?\?\s*Colors\.black\b': '?? Colors.transparent',
}

for p, r in replacements_h.items():
    c_h = re.sub(p, r, c_h)

c_h = re.sub(r'const\s+Border\(\s*top:\s*BorderSide\(\s*color:\s*Theme\.of\(context\)', r'Border(top: BorderSide(color: Theme.of(context)', c_h)
c_h = re.sub(r'const\s+Icon\([^,]+,\s*color:\s*Theme\.of\(context\)', lambda m: m.group(0).replace('const ', ''), c_h)

with open(file_home, 'w', encoding='utf-8') as f:
    f.write(c_h)


# 3. FIX PEST DISEASE HELP
file_pest = r'd:\HERALD\FYP\smart_kisan\lib\pest_disease_help.dart'
with open(file_pest, 'r', encoding='utf-8') as f:
    c_p = f.read()

replacements_p = {
    r'Colors\.black\.withValues\(alpha:\s*0\.1\)': 'Theme.of(context).shadowColor.withOpacity(0.1)',
    r'Colors\.black12': 'Theme.of(context).shadowColor.withOpacity(0.1)',
    r'Color\(0xFFFFF3E0\)': 'Theme.of(context).cardColor',
    r'Colors\.orange\.shade200': 'Theme.of(context).dividerColor.withOpacity(0.1)',
    r'const Color\(0xFFFFE2E2\)': 'Theme.of(context).colorScheme.error.withOpacity(0.1)',
    r'const Color\(0xFFC10007\)': 'Theme.of(context).colorScheme.error',
    r'const Color\(0xFFFEF9C2\)': 'Theme.of(context).colorScheme.secondary.withOpacity(0.1)',
    r'const Color\(0xFFA65F00\)': 'Theme.of(context).colorScheme.secondary',
    r'const Color\(0xFFE2FFFB\)': 'Theme.of(context).colorScheme.primary.withOpacity(0.1)',
    r'const Color\(0xFFFB2C36\)': 'Theme.of(context).colorScheme.error',
    r'const Color\(0xFFDCFCE7\)': 'Theme.of(context).colorScheme.primary.withOpacity(0.1)',
    r'Colors\.red\.withValues\(alpha:\s*0\.2\)': 'Theme.of(context).colorScheme.error.withOpacity(0.2)',
    r'Colors\.orange\.withValues\(alpha:\s*0\.2\)': 'Theme.of(context).colorScheme.secondary.withOpacity(0.2)',
    r'Colors\.yellow\.withValues\(alpha:\s*0\.2\)': 'Theme.of(context).colorScheme.secondary.withOpacity(0.1)',
    r'Colors\.red\[700\]': 'Theme.of(context).colorScheme.error',
    r'Colors\.orange\[700\]': 'Theme.of(context).colorScheme.secondary',
    r'Colors\.yellow\[700\]': 'Theme.of(context).colorScheme.secondary',
    r'const Color\(0xFFE0E0E0\)': 'Theme.of(context).dividerColor.withOpacity(0.1)',
    r'Colors\.amber\[700\]': 'Theme.of(context).colorScheme.primary',
}

for p, r in replacements_p.items():
    c_p = re.sub(p, r, c_p)

with open(file_pest, 'w', encoding='utf-8') as f:
    f.write(c_p)

print("Applied theme fixes to all 3 files!")
