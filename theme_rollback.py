import re
import os

# 1. WELCOME SCREEN
path_welcome = r'd:\HERALD\FYP\smart_kisan\lib\welcome_screen.dart'
with open(path_welcome, 'r', encoding='utf-8') as f:
    src = f.read()

# Fix background
src = src.replace('backgroundColor: Theme.of(context).scaffoldBackgroundColor,', 
                  'backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,')

# Fix text body colors
src = src.replace('color: Theme.of(context).textTheme.bodyLarge?.color', 
                  'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyLarge?.color : const Color(0xFF1E1E1E)')

# Fix hint colors
src = src.replace('Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey', 
                  '(Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyMedium?.color : const Color(0xFF9C9C9C)) ?? Colors.grey')

# Fix outline button
src = src.replace('color: Theme.of(context).cardColor.withValues(alpha: 0.1)', 
                  'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor.withValues(alpha: 0.1) : Colors.white')

with open(path_welcome, 'w', encoding='utf-8') as f:
    f.write(src)

# 2. HOME PAGE
path_home = r'd:\HERALD\FYP\smart_kisan\lib\home_page.dart'
with open(path_home, 'r', encoding='utf-8') as f:
    src = f.read()

src = src.replace('backgroundColor: Theme.of(context).scaffoldBackgroundColor,', 
                  'backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,')
src = src.replace('color: Theme.of(context).colorScheme.surface,', 
                  'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Colors.white,')
src = src.replace('color: Theme.of(context).cardColor,', 
                  'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,')

with open(path_home, 'w', encoding='utf-8') as f:
    f.write(src)

# 3. AI CHAT PAGE
path_ai = r'd:\HERALD\FYP\smart_kisan\lib\ai_chat_page.dart'
if os.path.exists(path_ai):
    with open(path_ai, 'r', encoding='utf-8') as f:
        src = f.read()
    
    src = src.replace('backgroundColor: Theme.of(context).scaffoldBackgroundColor,', 
                      'backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF0FDF4),')
    src = src.replace('color: Theme.of(context).cardColor,', 
                      'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,')
    
    with open(path_ai, 'w', encoding='utf-8') as f:
        f.write(src)

# 4. PEST DISEASE HELP (Headers and Buttons)
path_pest = r'd:\HERALD\FYP\smart_kisan\lib\pest_disease_help.dart'
with open(path_pest, 'r', encoding='utf-8') as f:
    src = f.read()

# Fix Header Text visibility
src = re.sub(
    r"Text\(LocalizationService\.translate\('Pest & Disease Help'\),\s*style:\s*TextStyle\(\s*color:\s*Theme\.of\(context\)\.textTheme\.bodyLarge\?\.color,",
    r"Text(LocalizationService.translate('Pest & Disease Help'),\n                        style: TextStyle(\n                          color: Theme.of(context).colorScheme.onPrimary,",
    src
)
src = re.sub(
    r"Text\(LocalizationService\.translate\('Early detection and treatment guidance'\),\s*style:\s*TextStyle\(\s*color:\s*Theme\.of\(context\)\.textTheme\.bodyMedium\?\.color,",
    r"Text(LocalizationService.translate('Early detection and treatment guidance'),\n                        style: TextStyle(\n                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),",
    src
)
src = re.sub(
    r"icon: Icon\(Icons\.arrow_back, color: Theme\.of\(context\)\.colorScheme\.primary\),",
    r"icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),",
    src
)
src = re.sub(
    r"Icon\(Icons\.bug_report, color: Theme\.of\(context\)\.colorScheme\.primary, size: 20\),",
    r"Icon(Icons.bug_report, color: Theme.of(context).colorScheme.onPrimary, size: 20),",
    src
)

# Fix Scan Now Button Text inside the Bottom Sheet / dialog
src = re.sub(
    r"child: Text\(LocalizationService\.translate\('Scan Your Crop'\)\),",
    r"child: Text(LocalizationService.translate('Scan Your Crop'), style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),",
    src
)

with open(path_pest, 'w', encoding='utf-8') as f:
    f.write(src)

print("Theme Rollback & Polish Applied!")
