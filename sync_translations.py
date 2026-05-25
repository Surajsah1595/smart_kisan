import json
import os
import urllib.request
import urllib.parse
import time

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

with open(os.path.join(base_path, 'en.json'), 'r', encoding='utf-8') as f:
    en_data = json.load(f)

for lang in ['hi', 'ne']:
    filepath = os.path.join(base_path, f'{lang}.json')
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        missing = [k for k in en_data if k not in data]
        if missing:
            print(f"Found {len(missing)} missing keys for {lang}. Translating...")
            for idx, key in enumerate(missing):
                if idx % 50 == 0:
                    print(f"  {idx}/{len(missing)} translated...")
                data[key] = translate_text(key, lang)
                
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"Updated {lang}.json completely.")
