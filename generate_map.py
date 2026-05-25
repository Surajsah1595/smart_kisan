import json
import os

def generate_dart_map():
    base_path = 'assets/translations'
    dart_file_path = 'lib/translations_map.dart'
    
    with open(os.path.join(base_path, 'hi.json'), 'r', encoding='utf-8') as f:
        hi_data = json.load(f)
        
    with open(os.path.join(base_path, 'ne.json'), 'r', encoding='utf-8') as f:
        ne_data = json.load(f)

    dart_content = "/// AUTO-GENERATED FALLBACK TRANSLATIONS\n"
    dart_content += "class TranslationsMap {\n"
    dart_content += "  static const Map<String, Map<String, String>> data = {\n"
    
    # Iterate through all keys
    all_keys = set(hi_data.keys()).union(set(ne_data.keys()))
    
    for key in all_keys:
        hi_val = hi_data.get(key, key).replace("'", "\\'").replace("\n", "\\n").replace('$', '\\$')
        ne_val = ne_data.get(key, key).replace("'", "\\'").replace("\n", "\\n").replace('$', '\\$')
        safe_key = key.replace("'", "\\'").replace("\n", "\\n").replace('$', '\\$')
        
        dart_content += f"    '{safe_key}': {{\n"
        dart_content += f"      'hi': '{hi_val}',\n"
        dart_content += f"      'ne': '{ne_val}',\n"
        dart_content += "    },\n"
        
    dart_content += "  };\n"
    dart_content += "}\n"
    
    with open(dart_file_path, 'w', encoding='utf-8') as f:
        f.write(dart_content)
        
    print("Generated translations_map.dart successfully.")

if __name__ == '__main__':
    generate_dart_map()
