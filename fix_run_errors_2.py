import os

errors = """
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
lib/settings.dart:737:20: Error: Not a constant expression.
lib/settings.dart:789:49: Error: Not a constant expression.
lib/settings.dart:1022:47: Error: Method invocation is not a constant expression.
lib/settings.dart:1431:49: Error: Method invocation is not a constant expression.
lib/settings.dart:1696:63: Error: Not a constant expression.
lib/settings.dart:1722:81: Error: Not a constant expression.
lib/settings.dart:1898:49: Error: Method invocation is not a constant expression.
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
        
        if filepath not in file_fixes:
            file_fixes[filepath] = set()
        file_fixes[filepath].add(line_num)

    for filepath, fixes in file_fixes.items():
        # Ensure path uses correct separators for windows
        full_path = os.path.join("d:/HERALD/FYP/smart_kisan", filepath)
        if not os.path.exists(full_path):
            continue

        with open(full_path, 'r', encoding='utf-8') as f:
            content_lines = f.readlines()

        for line_num in fixes:
            ln = line_num - 1
            if ln < 0 or ln >= len(content_lines): continue
            
            # Remove const keyword from the specific lines
            content_lines[ln] = content_lines[ln].replace('const ', '')
                
        with open(full_path, 'w', encoding='utf-8') as f:
            f.writelines(content_lines)
            
        print(f"Fixed {full_path}")

if __name__ == '__main__':
    fix()
