import re

def process_file(filepath, start_marker, end_marker):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    start_idx = content.find(start_marker)
    if start_idx == -1: return
    end_idx = content.find(end_marker, start_idx)
    if end_idx == -1: end_idx = len(content)
    
    appbar = content[start_idx:end_idx]
    
    # 1. Background color
    appbar = appbar.replace(
        'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Colors.white,',
        'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary,'
    )
    appbar = appbar.replace(
        'color: Theme.of(context).colorScheme.surface,',
        'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary,'
    )
    
    # 2. Text colors
    appbar = appbar.replace(
        'color: Theme.of(context).textTheme.bodyLarge?.color',
        'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyLarge?.color : Colors.white'
    )
    appbar = appbar.replace(
        'color: Theme.of(context).textTheme.bodyMedium?.color',
        'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyMedium?.color : Colors.white.withOpacity(0.9)'
    )
    appbar = appbar.replace(
        'color: Theme.of(context).textTheme.bodySmall?.color',
        'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodySmall?.color : Colors.white.withOpacity(0.8)'
    )
    
    # 3. Icon colors
    appbar = appbar.replace(
        'color: Theme.of(context).colorScheme.primary',
        'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.primary : Colors.white'
    )
    appbar = appbar.replace(
        'color: Theme.of(context).colorScheme.onSurface',
        'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.onSurface : Colors.white'
    )
    
    # 4. Profile/Icon background (dividerColor)
    appbar = appbar.replace(
        'color: Theme.of(context).dividerColor.withOpacity(0.1)',
        'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).dividerColor.withOpacity(0.1) : Colors.white.withOpacity(0.2)'
    )
    
    new_content = content[:start_idx] + appbar + content[end_idx:]
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

# Process home_page.dart
process_file(
    r'd:\HERALD\FYP\smart_kisan\lib\home_page.dart',
    'Widget _buildAppBar() {',
    'Widget _buildFarmOverview()'
)

# Process ai_chat_page.dart
process_file(
    r'd:\HERALD\FYP\smart_kisan\lib\ai_chat_page.dart',
    'Widget _buildAppBar(BuildContext context) {',
    'Widget _buildQuickQuestions()'
)

print("Header logic rewritten!")
