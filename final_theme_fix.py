import re

# ═══════════════════════════════════════════════════════
# 1. USER_REGISTRATION.DART — Full sweep
# ═══════════════════════════════════════════════════════
path_reg = r'd:\HERALD\FYP\smart_kisan\lib\user_registration.dart'
with open(path_reg, 'r', encoding='utf-8') as f:
    src = f.read()

# Map all remaining hardcoded colors -> theme tokens
# Note: Colors.white on a GREEN/primary background (fingerprint/passcode screens) must STAY white
# because the background is primary green — those are onPrimary usage and correct.
replacements = [
    # Back button circle & icon (grey.shade100 + black)
    (r"color: Colors\.grey\.shade100,", "color: Theme.of(context).colorScheme.surfaceContainerHighest,"),
    (r"const Icon\(Icons\.arrow_back, color: Colors\.black\)", "Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface)"),

    # "Login" header — black on surface
    (r"color: Colors\.black,\s*\n\s*fontSize: 32,", "color: Theme.of(context).colorScheme.onSurface,\n                      fontSize: 32,"),
    # generic remaining Colors.black for text (line 695 area)
    (r"const TextStyle\(\s*color: Colors\.black,\s*fontSize: 32,", "TextStyle(\n                      color: Theme.of(context).colorScheme.onSurface,\n                      fontSize: 32,"),

    # Subtitle / hint grey (#9A9595)
    (r"const TextStyle\(color: Color\(0xFF9A9595\)", "TextStyle(color: Theme.of(context).hintColor"),
    (r"Color\(0xFF9A9595\)", "Theme.of(context).hintColor"),
    
    # Section label (#333333)
    (r"const TextStyle\(color: Color\(0xFF333333\)", "TextStyle(color: Theme.of(context).colorScheme.onSurface"),
    (r"Color\(0xFF333333\)", "Theme.of(context).colorScheme.onSurface"),

    # Field label (#8C8686)
    (r"const TextStyle\(color: Color\(0xFF8C8686\)", "TextStyle(color: Theme.of(context).hintColor"),
    (r"Color\(0xFF8C8686\)", "Theme.of(context).hintColor"),

    # Underline border (#B0ABAB)
    (r"const BoxDecoration\(border: Border\(bottom: BorderSide\(width: 1, color: Color\(0xFFB0ABAB\)\)\)\)", "BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Theme.of(context).dividerColor)))"),
    (r"Color\(0xFFB0ABAB\)", "Theme.of(context).dividerColor"),

    # "Having a Problem?" (#696666)
    (r"const TextStyle\(color: Color\(0xFF696666\)", "TextStyle(color: Theme.of(context).hintColor"),
    (r"Color\(0xFF696666\)", "Theme.of(context).hintColor"),

    # "Send Again" / link green (#4BA26A)
    (r"const TextStyle\(color: Color\(0xFF4BA26A\)", "TextStyle(color: Theme.of(context).colorScheme.primary"),
    (r"Color\(0xFF4BA26A\)", "Theme.of(context).colorScheme.primary"),

    # OTP box border green (#34843C)
    (r"const Color\(0xFF34843C\)", "Theme.of(context).colorScheme.primary"),
    (r"Color\(0xFF34843C\)", "Theme.of(context).colorScheme.primary"),

    # Signup button green (#2B7B48)
    (r"const Color\(0xFF2B7B48\)", "Theme.of(context).colorScheme.primary"),
    (r"Color\(0xFF2B7B48\)", "Theme.of(context).colorScheme.primary"),

    # "or sign up with" dark text (#262626)
    (r"const Color\(0xFF262626\)", "Theme.of(context).colorScheme.onSurface"),
    (r"Color\(0xFF262626\)", "Theme.of(context).colorScheme.onSurface"),

    # Overlay (black alpha 0.37) — keep as shadow, but use theme
    (r"Colors\.black\.withValues\(alpha: 0\.37\)", "Theme.of(context).shadowColor.withOpacity(0.37)"),
    (r"Colors\.black\.withValues\(alpha: 0\.1\)", "Theme.of(context).shadowColor.withOpacity(0.1)"),

    # Signup header text that was set to Colors.black (line 695 area)
    (r"color: Colors\.black,\s*\n\s*fontSize: 26,", "color: Theme.of(context).colorScheme.onSurface,\n                    fontSize: 26,"),
]

for pattern, replacement in replacements:
    src = re.sub(pattern, replacement, src)

# Fix any remaining "const TextStyle(color: Theme.of" or "const BoxDecoration(color: Theme.of"
src = re.sub(r'const TextStyle\(\s*color: Theme\.of\(context\)', 'TextStyle(color: Theme.of(context)', src)
src = re.sub(r'const BoxDecoration\(border: Border\(bottom: BorderSide\(width: 1, color: Theme\.of\(context\)', 'BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Theme.of(context)', src)
src = re.sub(r'const BoxDecoration\(shape: BoxShape\.circle,\s*color: Theme\.of\(context\)', 'BoxDecoration(shape: BoxShape.circle, color: Theme.of(context)', src)
src = re.sub(r'const Icon\([^)]*color: Theme\.of\(context\)', lambda m: m.group(0).replace('const ', ''), src)

with open(path_reg, 'w', encoding='utf-8') as f:
    f.write(src)

print("[1/3] user_registration.dart: DONE")


# ═══════════════════════════════════════════════════════
# 2. HOME_PAGE.DART — Fix scaffold background + color fields
# ═══════════════════════════════════════════════════════
path_home = r'd:\HERALD\FYP\smart_kisan\lib\home_page.dart'
with open(path_home, 'r', encoding='utf-8') as f:
    src = f.read()

# Fix scaffold background from _white -> theme
src = src.replace(
    'backgroundColor: _white,',
    'backgroundColor: Theme.of(context).scaffoldBackgroundColor,',
)

# Fix the DBEA color
src = src.replace(
    "iconColor = const Color(0xFFDBEAFE);",
    "iconColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);",
)

with open(path_home, 'w', encoding='utf-8') as f:
    f.write(src)

print("[2/3] home_page.dart: DONE")


# ═══════════════════════════════════════════════════════
# 3. PEST_DISEASE_HELP.DART — Fix green-on-green button
# ═══════════════════════════════════════════════════════
path_pest = r'd:\HERALD\FYP\smart_kisan\lib\pest_disease_help.dart'
with open(path_pest, 'r', encoding='utf-8') as f:
    src = f.read()

# The "Scan Now" button text + icon are using colorScheme.primary (green on green button)
# They need to be onPrimary (white)
# Lines 526 and 530: inside the ElevatedButton child
src = src.replace(
    "Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary)",
    "Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onPrimary)",
)

# Fix the Scan Now text color
old_scan_now = """Text(LocalizationService.translate('Scan Now'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,"""
new_scan_now = """Text(LocalizationService.translate('Scan Now'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,"""
src = src.replace(old_scan_now, new_scan_now)

with open(path_pest, 'w', encoding='utf-8') as f:
    f.write(src)

print("[3/3] pest_disease_help.dart: DONE")
print("\nAll theme fixes applied successfully!")
