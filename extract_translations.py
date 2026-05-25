import os
import json
import re

def extract_translations():
    with open('lib/localization_service.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Create assets/translations directory
    os.makedirs('assets/translations', exist_ok=True)

    # We need to extract the _translations map.
    # It looks like: EN: { 'key': 'value', ... }, HI: { ... }, NE: { ... }
    
    # Very simple parser since dart map syntax is similar to json but without quotes on keys (sometimes)
    # Actually, in localization_service.dart, keys are quoted strings.
    # Let's extract the block for EN, HI, NE.
    
    # We will find the EN block
    en_match = re.search(r'EN:\s*\{([\s\S]*?)\}(?=\s*,\s*HI:)', content)
    hi_match = re.search(r'HI:\s*\{([\s\S]*?)\}(?=\s*,\s*NE:)', content)
    ne_match = re.search(r'NE:\s*\{([\s\S]*?)\}(?=\s*};)', content)

    def parse_block(block_str):
        data = {}
        # Match 'key': 'value' or 'key': "value" or "key": "value"
        # We must handle escaped quotes like \'
        pattern = r'''(['"])(.*?)(?<!\\)\1\s*:\s*(['"])(.*?)(?<!\\)\3'''
        for match in re.finditer(pattern, block_str):
            key = match.group(2).replace("\\'", "'").replace('\\"', '"')
            val = match.group(4).replace("\\'", "'").replace('\\"', '"')
            data[key] = val
        return data

    if en_match:
        en_data = parse_block(en_match.group(1))
        with open('assets/translations/en.json', 'w', encoding='utf-8') as f:
            json.dump(en_data, f, indent=2, ensure_ascii=False)
            
    if hi_match:
        hi_data = parse_block(hi_match.group(1))
        with open('assets/translations/hi.json', 'w', encoding='utf-8') as f:
            json.dump(hi_data, f, indent=2, ensure_ascii=False)
            
    if ne_match:
        ne_data = parse_block(ne_match.group(1))
        with open('assets/translations/ne.json', 'w', encoding='utf-8') as f:
            json.dump(ne_data, f, indent=2, ensure_ascii=False)
            
    print("Extracted translation files to assets/translations/")

if __name__ == '__main__':
    extract_translations()
