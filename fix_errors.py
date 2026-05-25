import os
import re

file_home = r'd:\HERALD\FYP\smart_kisan\lib\home_page.dart'
with open(file_home, 'r', encoding='utf-8') as f:
    c_h = f.read()

c_h = re.sub(r'const\s+TextStyle\([^)]*Theme\.of\(context\)[^)]*\)', lambda m: m.group(0).replace('const ', ''), c_h)
c_h = re.sub(r'const\s+LinearGradient\([^)]*Theme\.of\(context\)[^)]*\)', lambda m: m.group(0).replace('const ', ''), c_h)
c_h = re.sub(r'const\s+Icon\([^)]*Theme\.of\(context\)[^)]*\)', lambda m: m.group(0).replace('const ', ''), c_h)

with open(file_home, 'w', encoding='utf-8') as f:
    f.write(c_h)


file_welcome = r'd:\HERALD\FYP\smart_kisan\lib\welcome_screen.dart'
with open(file_welcome, 'r', encoding='utf-8') as f:
    c_w = f.read()

# Fix default argument: {Color color = Theme.of(context).cardColor}
c_w = c_w.replace(
    'Widget _buildText(String text, double fontSize, FontWeight weight, {Color color = Theme.of(context).cardColor}) {',
    'Widget _buildText(String text, double fontSize, FontWeight weight, {Color? color}) {'
)
c_w = c_w.replace(
    'return Text(\n      text,\n      textAlign: TextAlign.center,\n      style: TextStyle(\n        color: color,',
    'return Text(\n      text,\n      textAlign: TextAlign.center,\n      style: TextStyle(\n        color: color ?? Theme.of(context).cardColor,'
)

# Fix color parameter expecting Color but got Color? in _buildText call
c_w = re.sub(
    r'color:\s*Theme\.of\(context\)\.textTheme\.bodyMedium\?\.color,',
    r'color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,',
    c_w
)

with open(file_welcome, 'w', encoding='utf-8') as f:
    f.write(c_w)

print("Applied const and type fixes!")
