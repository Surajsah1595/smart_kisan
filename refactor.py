import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Add import if not exists
    if "import 'localization_service.dart';" not in content and "class LocalizationService" not in content:
        # Find the last import
        import_match = list(re.finditer(r"import\s+['\"].*?['\"];", content))
        if import_match:
            last_import = import_match[-1]
            content = content[:last_import.end()] + "\nimport 'localization_service.dart';" + content[last_import.end():]

    # Regex to wrap hardcoded Text strings with LocalizationService.translate()
    # E.g. Text('Some text') -> Text(LocalizationService.translate('Some text'))
    # Only if it's not already translated or empty or just variables.
    
    def text_replacer(match):
        prefix = match.group(1) # Text( or const Text(
        string_literal = match.group(2) # 'Something' or "Something"
        suffix = match.group(3) # ) or ,
        
        # Skip if already translated
        if "LocalizationService.translate" in string_literal or "tr(" in string_literal:
            return match.group(0)
            
        # Extract the actual string
        inner_string = string_literal[1:-1]
        if not inner_string or inner_string.isspace() or "$" in inner_string or inner_string.startswith(" "):
            return match.group(0) # skip empty, variables, or prefixed spaces
            
        # Check if we removed 'const' by accident.
        new_prefix = prefix.replace('const Text', 'Text').replace('const  Text', 'Text')
        return f"{new_prefix}(LocalizationService.translate({string_literal}){suffix}"

    content = re.sub(r'(const\s+Text|Text)\s*\(\s*([\'"][^\'"]+[\'"])\s*([\)\,])', text_replacer, content)

    # Global Theme replacements for Colors.white, Colors.black, and const Color(...)
    # Instead of injecting theme, we will try to use context if possible. 
    # But for a robust regex, we can just replace specific color constants with Theme.of(context).xxxx 
    # ONLY IF we are inside a method that has BuildContext context.
    
    # We will use Theme.of(context).colorScheme.primary instead of Color(0xFF00A63E) or Color(0xFF00C850) or Color(0xFF00C950)
    content = re.sub(r'(const\s+)?Color\(0xFF00[A-Z0-9]{4}\)', 'Theme.of(context).colorScheme.primary', content)
    
    # Replace Colors.white with Theme.of(context).cardColor (generally safe for cards/backgrounds)
    # Actually, let's replace scaffold backgrounds first
    content = re.sub(r'backgroundColor:\s*(const\s+)?Color\(0xFF[A-Z0-9]+\),?', '', content) # remove hardcoded scaffold background
    
    # Colors.white in BoxDecoration -> Theme.of(context).cardColor
    content = re.sub(r'color:\s*Colors\.white,', 'color: Theme.of(context).cardColor,', content)
    
    # Colors.black or dark colors in TextStyle -> Theme.of(context).textTheme.bodyLarge?.color
    content = re.sub(r'color:\s*(const\s+)?Color\(0xFF101727\)', 'color: Theme.of(context).textTheme.bodyLarge?.color', content)
    content = re.sub(r'color:\s*(const\s+)?Color\(0xFF495565\)', 'color: Theme.of(context).textTheme.bodyMedium?.color', content)
    
    # Text colors that are white -> Theme.of(context).colorScheme.onPrimary
    # Very risky with regex, but we will try a safe one:
    # style: TextStyle(color: Colors.white
    content = re.sub(r'style:\s*(const\s+)?TextStyle\(\s*color:\s*Colors\.white', 'style: TextStyle(color: Theme.of(context).colorScheme.onPrimary', content)
    
    # Remove const from TextStyle if it has Theme.of(context)
    content = re.sub(r'const\s+TextStyle\([^)]*Theme\.of\(context\)[^)]*\)', lambda m: m.group(0).replace('const ', ''), content)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Refactored: {filepath}")

def main():
    lib_dir = "d:/HERALD/FYP/smart_kisan/lib"
    for root, _, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart') and file not in ['app_config.dart', 'localization_service.dart', 'firebase_options.dart']:
                process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
