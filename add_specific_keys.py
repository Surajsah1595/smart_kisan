import json
import os
import urllib.request
import urllib.parse

keys_to_add = [
    "Enter area", "Search crop (e.g., wheat, rice)", "Enter your password", "Theme changed to"
]

def translate_text(text, target_lang):
    if target_lang == 'en':
        return text
    try:
        url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=" + target_lang + "&dt=t&q=" + urllib.parse.quote(text)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req)
        data = json.loads(response.read().decode('utf-8'))
        return data[0][0][0]
    except Exception as e:
        return text

base_path = 'assets/translations'
languages = ['en', 'hi', 'ne']

for lang in languages:
    filepath = os.path.join(base_path, f'{lang}.json')
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        updated = False
        for key in keys_to_add:
            if key not in data:
                data[key] = translate_text(key, lang)
                updated = True
                
        if updated:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"Updated {lang}.json")
