import os
import re

def process_file(filepath, replacements):
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    for p, r in replacements.items():
        if callable(r):
            content = re.sub(p, r, content)
        else:
            content = re.sub(p, r, content)
            
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)


# 1. WELCOME SCREEN
replacements_welcome = {
    # Fix the missing onPrimary in _buildButton and _buildOutlineButton text
    r"Center\(child:\s*_buildText\(text,\s*16,\s*FontWeight\.w700\)\)": lambda m: "Center(child: _buildText(text, 16, FontWeight.w700, color: Theme.of(context).colorScheme.onPrimary))" if 'gradient' in m.string[max(0, m.start()-150):m.end()] else "Center(child: _buildText(text, 16, FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color))",
    
    # Fix Skip button
    r"const TextStyle\(color:\s*Color\(0xFF1E1E1E\)": r"TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color",
    
    # Language Selection buttons text contrast
    r"color:\s*_selectedLanguage\s*!=\s*null\s*\?\s*Theme\.of\(context\)\.cardColor\s*:\s*\(Theme\.of\(context\)\.textTheme\.bodyMedium\?\.color\s*\?\?\s*Colors\.grey\)": r"color: _selectedLanguage != null ? Theme.of(context).colorScheme.onPrimary : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)",
}

# Apply some logic to distinguish _buildButton vs _buildOutlineButton
with open(r'd:\HERALD\FYP\smart_kisan\lib\welcome_screen.dart', 'r', encoding='utf-8') as f:
    cw = f.read()

cw = cw.replace(
    'Widget _buildButton(String text, VoidCallback onTap) {\n    return Container(\n      height: 56,\n      decoration: BoxDecoration(\n        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary]),\n        borderRadius: BorderRadius.circular(16),\n        boxShadow: const [\n          BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4)),\n          BoxShadow(color: Color(0x19000000), blurRadius: 15, offset: Offset(0, 10)),\n        ],\n      ),\n      child: Material(\n        color: Colors.transparent,\n        child: InkWell(\n          borderRadius: BorderRadius.circular(16),\n          onTap: onTap,\n          child: Center(child: _buildText(text, 16, FontWeight.w700)),',
    'Widget _buildButton(String text, VoidCallback onTap) {\n    return Container(\n      height: 56,\n      decoration: BoxDecoration(\n        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary]),\n        borderRadius: BorderRadius.circular(16),\n        boxShadow: [\n          BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 4)),\n          BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10)),\n        ],\n      ),\n      child: Material(\n        color: Colors.transparent,\n        child: InkWell(\n          borderRadius: BorderRadius.circular(16),\n          onTap: onTap,\n          child: Center(child: _buildText(text, 16, FontWeight.w700, color: Theme.of(context).colorScheme.onPrimary)),'
)
cw = cw.replace(
    'Widget _buildOutlineButton(String text, VoidCallback onTap) {\n    return Container(\n      height: 56,\n      decoration: BoxDecoration(\n        color: Theme.of(context).cardColor.withValues(alpha: 0.1),\n        borderRadius: BorderRadius.circular(16),\n        border: Border.all(width: 1.5, color: Theme.of(context).dividerColor.withOpacity(0.2)),\n      ),\n      child: Material(\n        color: Colors.transparent,\n        child: InkWell(\n          borderRadius: BorderRadius.circular(16),\n          onTap: onTap,\n          child: Center(child: _buildText(text, 16, FontWeight.w700)),',
    'Widget _buildOutlineButton(String text, VoidCallback onTap) {\n    return Container(\n      height: 56,\n      decoration: BoxDecoration(\n        color: Theme.of(context).cardColor.withValues(alpha: 0.1),\n        borderRadius: BorderRadius.circular(16),\n        border: Border.all(width: 1.5, color: Theme.of(context).dividerColor.withOpacity(0.2)),\n      ),\n      child: Material(\n        color: Colors.transparent,\n        child: InkWell(\n          borderRadius: BorderRadius.circular(16),\n          onTap: onTap,\n          child: Center(child: _buildText(text, 16, FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),'
)
for p, r in replacements_welcome.items():
    cw = re.sub(p, r, cw)

with open(r'd:\HERALD\FYP\smart_kisan\lib\welcome_screen.dart', 'w', encoding='utf-8') as f:
    f.write(cw)


# 2. USER REGISTRATION
replacements_user = {
    r'backgroundColor:\s*Colors\.white': 'backgroundColor: Theme.of(context).scaffoldBackgroundColor',
    r'const Color\(0xFFB0ABAB\)': 'Theme.of(context).dividerColor',
    r'const Color\(0xFF1E1E1E\)': 'Theme.of(context).textTheme.bodyLarge?.color',
    r'const Color\(0xFF9C9C9C\)': 'Theme.of(context).textTheme.bodyMedium?.color',
    r'Color\(0xFF1E1E1E\)': 'Theme.of(context).textTheme.bodyLarge?.color',
    r'Color\(0xFF9C9C9C\)': 'Theme.of(context).textTheme.bodyMedium?.color',
    r'const Color\(0xFF2C7C48\)': 'Theme.of(context).colorScheme.primary',
    r'Color\(0xFF2C7C48\)': 'Theme.of(context).colorScheme.primary',
    r'style:\s*const TextStyle\(color:\s*Colors\.black': 'style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color',
    r'const TextStyle\(\s*color:\s*Theme\.of\(context\)': 'TextStyle(color: Theme.of(context)',
    r'const BoxDecoration\(\s*border:\s*Border\(\s*bottom:\s*BorderSide\(\s*width:\s*1,\s*color:\s*Theme\.of\(context\)': 'BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Theme.of(context)',
    r'const BoxDecoration\(\s*shape:\s*BoxShape\.circle,\s*color:\s*Theme\.of\(context\)': 'BoxDecoration(shape: BoxShape.circle, color: Theme.of(context)',
}
process_file(r'd:\HERALD\FYP\smart_kisan\lib\user_registration.dart', replacements_user)


# 3. HOME PAGE
replacements_home = {
    # Settings Icon Contrast
    r'Icon\(Icons\.settings,\s*color:\s*Theme\.of\(context\)\.cardColor,\s*size:\s*24\)': 'Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface, size: 24)',
    
    # Bottom Nav Bar Fix
    r'color:\s*isSelected\s*\?\s*_lightGreen\s*:\s*Colors\.transparent,': 'color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,',
    r'color:\s*isSelected\s*\?\s*_darkGreen\s*:\s*_gray,': 'color: isSelected ? Theme.of(context).colorScheme.primary : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),',
}
process_file(r'd:\HERALD\FYP\smart_kisan\lib\home_page.dart', replacements_home)


# 4. NOTIFICATION
replacements_notification = {
    r'const Color\(0xFF2C7C48\)': 'Theme.of(context).colorScheme.primary',
    r'Color\(0xFF2C7C48\)': 'Theme.of(context).colorScheme.primary',
    r'const Color\(0xFF354152\)': 'Theme.of(context).textTheme.bodyLarge?.color',
    r'Color\(0xFF354152\)': 'Theme.of(context).textTheme.bodyLarge?.color',
    r'const Color\(0xFFE7000B\)': 'Theme.of(context).colorScheme.error',
    r'Color\(0xFFE7000B\)': 'Theme.of(context).colorScheme.error',
    r'const Color\(0xFFE5E7EB\)': 'Theme.of(context).dividerColor.withOpacity(0.2)',
    r'Color\(0xFFE5E7EB\)': 'Theme.of(context).dividerColor.withOpacity(0.2)',
    r'const Color\(0xFF6B7280\)': 'Theme.of(context).textTheme.bodyMedium?.color',
    r'Color\(0xFF6B7280\)': 'Theme.of(context).textTheme.bodyMedium?.color',
    r'const Color\(0xFFF3F4F6\)': 'Theme.of(context).cardColor',
    r'Color\(0xFFF3F4F6\)': 'Theme.of(context).cardColor',
    r'Colors\.black\.withValues\(alpha:\s*0\.1\)': 'Theme.of(context).shadowColor.withOpacity(0.1)',
    r'Colors\.white': 'Theme.of(context).colorScheme.onPrimary',
    r'color:\s*Colors\.red': 'color: Theme.of(context).colorScheme.error',
    
    # Hex codes for specific notification types -> map to Theme
    r'const Color\(0xFFE8F5E9\)': 'Theme.of(context).colorScheme.primary.withOpacity(0.1)',
    r'const Color\(0xFF1B4D2C\)': 'Theme.of(context).colorScheme.primary',
    r'const Color\(0xFFFFF7ED\)': 'Theme.of(context).colorScheme.secondary.withOpacity(0.1)',
    r'const Color\(0xFFF44900\)': 'Theme.of(context).colorScheme.secondary',
    r'const Color\(0xFF7E2A0B\)': 'Theme.of(context).colorScheme.secondary',
    r'const Color\(0xFFFEF2F2\)': 'Theme.of(context).colorScheme.error.withOpacity(0.1)',
    r'const Color\(0xFF82181A\)': 'Theme.of(context).colorScheme.error',
    r'const Color\(0xFFEFF6FF\)': 'Theme.of(context).colorScheme.tertiary.withOpacity(0.1)',
    r'const Color\(0xFF155CFB\)': 'Theme.of(context).colorScheme.tertiary',
    r'const Color\(0xFF1B388E\)': 'Theme.of(context).colorScheme.tertiary',
    r'const Color\(0xFFBDDAFF\)': 'Theme.of(context).dividerColor.withOpacity(0.2)',
    r'const Color\(0xFFFEEF85\)': 'Theme.of(context).dividerColor.withOpacity(0.2)',
    r'const Color\(0xFFFEFCE8\)': 'Theme.of(context).colorScheme.secondary.withOpacity(0.05)',
    r'const Color\(0xFFFFF085\)': 'Theme.of(context).colorScheme.secondary',
    r'const Color\(0xFF723D0A\)': 'Theme.of(context).colorScheme.secondary',
    r'const Color\(0xFFB8F7CF\)': 'Theme.of(context).dividerColor.withOpacity(0.2)',
    r'const Color\(0xFFF0FDF4\)': 'Theme.of(context).colorScheme.primary.withOpacity(0.05)',
    r'const Color\(0xFFB9F8CF\)': 'Theme.of(context).colorScheme.primary',
    r'const Color\(0xFF0D532B\)': 'Theme.of(context).colorScheme.primary',
    r'const Color\(0xFFD1D5DB\)': 'Theme.of(context).dividerColor.withOpacity(0.3)',
    r'const Color\(0xFFF9FAFB\)': 'Theme.of(context).cardColor',
    r'const Color\(0xFF374151\)': 'Theme.of(context).textTheme.bodyLarge?.color',
    r'const Color\(0xFFFFC9C9\)': 'Theme.of(context).colorScheme.error.withOpacity(0.4)',
    
    r'const\s+BoxDecoration\(\s*color:\s*Theme\.of\(context\)': 'BoxDecoration(color: Theme.of(context)',
    r'const\s+TextStyle\(\s*color:\s*Theme\.of\(context\)': 'TextStyle(color: Theme.of(context)',
    r'const\s+Icon\([^,]+,\s*color:\s*Theme\.of\(context\)': lambda m: m.group(0).replace('const ', ''),
    r'const\s+Icon\([^,]+,\s*size:\s*[0-9]+,\s*color:\s*Theme\.of\(context\)': lambda m: m.group(0).replace('const ', ''),
}
process_file(r'd:\HERALD\FYP\smart_kisan\lib\notification.dart', replacements_notification)


# 5. PEST DISEASE HELP
replacements_pest = {
    # Fix the button text colors
    r'child:\s*Text\(LocalizationService\.translate\(\'Scan Now\'\),\s*style:\s*TextStyle\(\s*color:\s*Theme\.of\(context\)\.colorScheme\.onPrimary,\s*fontSize:\s*16,': 'child: Text(LocalizationService.translate(\'Scan Now\'),\n                  style: TextStyle(\n                    color: Theme.of(context).colorScheme.onPrimary,\n                    fontSize: 16,',
}
process_file(r'd:\HERALD\FYP\smart_kisan\lib\pest_disease_help.dart', replacements_pest)

print("Massive UI/UX Refactor Complete!")
