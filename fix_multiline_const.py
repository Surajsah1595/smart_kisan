import re
path = r'd:\HERALD\FYP\smart_kisan\lib\user_registration.dart'
with open(path, 'r', encoding='utf-8') as f:
    src = f.read()

# Fix multi-line const BoxDecoration
src = src.replace('decoration: const BoxDecoration(\n                          border: Border(\n                            bottom: BorderSide(\n                              width: 1,\n                              color: Theme.of(context).dividerColor,',
                  'decoration: BoxDecoration(\n                          border: Border(\n                            bottom: BorderSide(\n                              width: 1,\n                              color: Theme.of(context).dividerColor,')

with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
print("Multi-line const fixes applied.")
