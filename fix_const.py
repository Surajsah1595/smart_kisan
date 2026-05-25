import re
path = r'd:\HERALD\FYP\smart_kisan\lib\user_registration.dart'
with open(path, 'r', encoding='utf-8') as f:
    src = f.read()

# Fix "const Theme.of(context)"
src = re.sub(r'const\s+Theme\.of\(context\)', 'Theme.of(context)', src)

# Fix "const Divider(color: Theme.of(context)"
src = re.sub(r'const\s+Divider\(\s*color:\s*Theme\.of\(context\)', r'Divider(color: Theme.of(context)', src)

with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
print("Const fixes applied.")
