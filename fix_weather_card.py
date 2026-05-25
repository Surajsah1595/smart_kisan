import re

path_home = r'd:\HERALD\FYP\smart_kisan\lib\home_page.dart'
with open(path_home, 'r', encoding='utf-8') as f:
    content = f.read()

start_idx = content.find('Widget _buildWeatherCard() {')
end_idx = content.find('Widget _buildFeatureGrid() {', start_idx)

weather_card = content[start_idx:end_idx]

# Fix the background color of the weather card to ALWAYS be primary green
weather_card = weather_card.replace(
    'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.primary : Colors.white,',
    'color: Theme.of(context).colorScheme.primary,'
)

# And fix text/icon colors to always be white (or onPrimary) rather than ternary
weather_card = weather_card.replace(
    'color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white',
    'color: Colors.white'
)

new_content = content[:start_idx] + weather_card + content[end_idx:]
with open(path_home, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Weather Card fixed!")
