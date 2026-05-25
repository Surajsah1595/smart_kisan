import os
import re

errors = """
lib/main.dart:193:94: Error: Not a constant expression.
lib/main.dart:194:95: Error: Not a constant expression.
lib/main.dart:195:94: Error: Not a constant expression.
lib/main.dart:196:95: Error: Not a constant expression.
lib/main.dart:197:96: Error: Not a constant expression.
lib/main.dart:198:95: Error: Not a constant expression.
lib/main.dart:199:92: Error: Not a constant expression.
lib/main.dart:200:93: Error: Not a constant expression.
lib/main.dart:201:92: Error: Not a constant expression.
lib/main.dart:203:92: Error: Not a constant expression.
lib/main.dart:204:91: Error: Not a constant expression.
lib/main.dart:205:92: Error: Not a constant expression.
lib/main.dart:206:93: Error: Not a constant expression.
lib/main.dart:207:92: Error: Not a constant expression.
lib/main.dart:238:92: Error: Not a constant expression.
lib/main.dart:239:93: Error: Not a constant expression.
lib/main.dart:240:92: Error: Not a constant expression.
lib/home_page.dart:367:39: Error: Undefined name 'context'.
lib/home_page.dart:368:37: Error: Undefined name 'context'.
lib/pest_disease_help.dart:196:52: Error: Method invocation is not a constant expression.
lib/pest_disease_help.dart:432:62: Error: Not a constant expression.
lib/pest_disease_help.dart:434:48: Error: Method invocation is not a constant expression.
lib/pest_disease_help.dart:534:42: Error: Method invocation is not a constant expression.
lib/pest_disease_help.dart:790:42: Error: Method invocation is not a constant expression.
lib/pest_disease_help.dart:792:37: Error: Not a constant expression.
lib/pest_disease_help.dart:798:42: Error: Method invocation is not a constant expression.
lib/pest_disease_help.dart:800:37: Error: Not a constant expression.
lib/pest_disease_help.dart:975:42: Error: Method invocation is not a constant expression.
lib/weather_page.dart:283:57: Error: Method invocation is not a constant expression.
lib/weather_page.dart:284:60: Error: Not a constant expression.
lib/water_optimization.dart:1601:51: Error: Not a constant expression.
lib/notification.dart:664:36: Error: Method invocation is not a constant expression.
lib/notification.dart:666:31: Error: Not a constant expression.
lib/notification.dart:673:36: Error: Method invocation is not a constant expression.
lib/notification.dart:675:31: Error: Not a constant expression.
lib/settings.dart:587:29: Error: Undefined name 'context'.
lib/settings.dart:737:41: Error: Not a constant expression.
lib/settings.dart:789:39: Error: Not a constant expression.
lib/settings.dart:1022:47: Error: Method invocation is not a constant expression.
lib/settings.dart:1045:67: Error: Not a constant expression.
lib/settings.dart:1431:49: Error: Method invocation is not a constant expression.
lib/settings.dart:1493:59: Error: Not a constant expression.
lib/settings.dart:1497:55: Error: Not a constant expression.
lib/settings.dart:1519:54: Error: Not a constant expression.
lib/settings.dart:1523:55: Error: Not a constant expression.
lib/settings.dart:1696:53: Error: Not a constant expression.
lib/settings.dart:1722:81: Error: Not a constant expression.
lib/settings.dart:1727:79: Error: Not a constant expression.
lib/settings.dart:1729:125: Error: Not a constant expression.
lib/settings.dart:1829:124: Error: Not a constant expression.
lib/settings.dart:1898:49: Error: Method invocation is not a constant expression.
lib/settings.dart:2045:124: Error: Not a constant expression.
lib/settings.dart:2081:47: Error: Not a constant expression.
lib/settings.dart:2083:50: Error: Not a constant expression.
lib/settings.dart:2376:108: Error: Not a constant expression.
lib/settings.dart:2466:42: Error: Method invocation is not a constant expression.
lib/settings.dart:2468:42: Error: Method invocation is not a constant expression.
lib/settings.dart:2469:43: Error: Not a constant expression.
lib/ai_chat_page.dart:216:64: Error: Not a constant expression.
"""

def fix():
    lines = errors.strip().split('\n')
    file_fixes = {}
    
    for line in lines:
        if not line: continue
        parts = line.split(':')
        filepath = parts[0].strip()
        line_num = int(parts[1].strip())
        error_msg = parts[3].strip() if len(parts) > 3 else ""
        
        if filepath not in file_fixes:
            file_fixes[filepath] = []
        file_fixes[filepath].append((line_num, error_msg))

    for filepath, fixes in file_fixes.items():
        if not os.path.exists(filepath):
            filepath = os.path.join("d:/HERALD/FYP/smart_kisan", filepath)
            if not os.path.exists(filepath):
                continue

        with open(filepath, 'r', encoding='utf-8') as f:
            content_lines = f.readlines()

        for line_num, error_msg in fixes:
            ln = line_num - 1
            if ln < 0 or ln >= len(content_lines): continue
            
            # 1. Main.dart Theme definitions
            if 'main.dart' in filepath:
                if 'Theme.of(context)' in content_lines[ln]:
                    content_lines[ln] = content_lines[ln].replace('Theme.of(context).textTheme.bodyLarge?.color', 'const Color(0xFF101727)')
                    content_lines[ln] = content_lines[ln].replace('Theme.of(context).textTheme.bodyMedium?.color', 'const Color(0xFF495565)')
                    content_lines[ln] = content_lines[ln].replace('Theme.of(context).colorScheme.primary', 'const Color(0xFF00C950)')
                    
                # Also if there's a parent 'const TextTheme(' that was replaced by regex
                content_lines[ln] = content_lines[ln].replace('const TextTheme', 'TextTheme')
                content_lines[ln] = content_lines[ln].replace('const TextStyle', 'TextStyle')
                
            # 2. Undefined name 'context' (e.g. final Color _accentGreen = Theme.of(context)...)
            elif 'home_page.dart' in filepath or 'settings.dart' in filepath:
                if 'Undefined name' in error_msg or 'context' in content_lines[ln]:
                    content_lines[ln] = content_lines[ln].replace('Theme.of(context).colorScheme.primary', 'Color(0xFF00C950)')
                    content_lines[ln] = content_lines[ln].replace('Theme.of(context).cardColor', 'Colors.white')
            
            # 3. Not a constant expression -> remove const
            if 'const ' in content_lines[ln]:
                # Remove const if it's before a widget with dynamic Theme/Localization
                content_lines[ln] = content_lines[ln].replace('const Icon', 'Icon')
                content_lines[ln] = content_lines[ln].replace('const Text', 'Text')
                content_lines[ln] = content_lines[ln].replace('const TextStyle', 'TextStyle')
                content_lines[ln] = content_lines[ln].replace('const BorderSide', 'BorderSide')
                content_lines[ln] = content_lines[ln].replace('const LinearGradient', 'LinearGradient')
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(content_lines)
            
        print(f"Fixed {filepath}")

if __name__ == '__main__':
    fix()
