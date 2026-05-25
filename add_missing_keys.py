import json
import os

missing_keys = {
    "Don't have an account?": {
        "en": "Don't have an account?",
        "hi": "खाता नहीं है?",
        "ne": "खाता छैन?"
    },
    "Welcome ": {
        "en": "Welcome ",
        "hi": "स्वागत है ",
        "ne": "स्वागत छ "
    },
    "Loading...": {
        "en": "Loading...",
        "hi": "लोड हो रहा है...",
        "ne": "लोड हुँदैछ..."
    },
    "Fetching weather...": {
        "en": "Fetching weather...",
        "hi": "मौसम की जानकारी प्राप्त की जा रही है...",
        "ne": "मौसम जानकारी ल्याउँदै..."
    },
    "Farm productivity": {
        "en": "Farm productivity",
        "hi": "खेत की उत्पादकता",
        "ne": "खेतको उत्पादकत्व"
    },
    "All clear": {
        "en": "All clear",
        "hi": "सब साफ़",
        "ne": "सबै स्पष्ट"
    },
    "This period": {
        "en": "This period",
        "hi": "इस अवधि में",
        "ne": "यस अवधिमा"
    },
    "Pest & Disease": {
        "en": "Pest & Disease",
        "hi": "कीट और रोग",
        "ne": "कीरा र रोग"
    },
    "Currently growing": {
        "en": "Currently growing",
        "hi": "वर्तमान में उग रहा है",
        "ne": "हाल बढ्दै छ"
    },
    "Issues detected": {
        "en": "Issues detected",
        "hi": "समस्याएँ पाई गईं",
        "ne": "समस्याहरू फेला परे"
    }
}

base_path = 'assets/translations'
languages = ['en', 'hi', 'ne']

for lang in languages:
    filepath = os.path.join(base_path, f'{lang}.json')
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        updated = False
        for key, translations in missing_keys.items():
            if key not in data:
                data[key] = translations[lang]
                updated = True
                
        if updated:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"Updated {lang}.json with missing keys.")
