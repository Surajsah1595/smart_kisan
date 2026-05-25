import os
import re
import json
import urllib.request
import urllib.parse

def translate_text(text, target_lang):
    if target_lang == 'en':
        return text
    try:
        # Very simple fallback translation using a free API or just return text if it fails
        # Using Google Translate web API endpoint
        url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=" + target_lang + "&dt=t&q=" + urllib.parse.quote(text)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req)
        data = json.loads(response.read().decode('utf-8'))
        return data[0][0][0]
    except Exception as e:
        print(f"Translation failed for '{text}' to {target_lang}: {e}")
        return text

def find_missing_keys():
    # 1. Scan all dart files for LocalizationService.translate('...') or tr('...')
    dart_files = []
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))

    keys_found = set()
    pattern1 = re.compile(r"LocalizationService\.translate\(\s*'([^']*)'\s*\)")
    pattern2 = re.compile(r"tr\(\s*'([^']*)'\s*\)")
    pattern3 = re.compile(r"LocalizationService\.translate\(\s*\"([^\"]*)\"\s*\)")

    for file in dart_files:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
            for match in pattern1.finditer(content):
                keys_found.add(match.group(1))
            for match in pattern2.finditer(content):
                keys_found.add(match.group(1))
            for match in pattern3.finditer(content):
                keys_found.add(match.group(1))

    # Add the ones reported from backend/API that might not be in dart directly
    backend_keys = [
        "Real-Time Market Prices", "Kalimati Market Rates", "Find today's best prices", "Search commodity...",
        "Tomato Big(Nepali)", "Unit", "Kg", "Min", "Avg", "Max", "Tomato Small(Local)", "Potato Red", "Potato White",
        "Onion Dry (Indian)", "Onion Green", "Brinjal Long", "Brinjal Round", "Cabbage(Local)", "Cauli Local", 
        "Cauli Jyoti", "Broccoli", "Carrot(Local)", "Raddish White(Local)", "Raddish Red", "Cow pea(Long)", 
        "Green Peas", "French Bean(Local)", "Soyabean Green", "Bitter Gourd (Tite Karela)", "Bottle Gourd (Lauka)",
        "Pointed Gourd (Parwar)", "Sponge Gourd (Ghiula)", "Snake Gourd (Chichindo)", "Pumpkin", "Okra (Bhindi)",
        "Chayote (Iskush)", "Spinach Leaf (Palungo)", "Mustard Leaf (Rayo)", "Cress Leaf (Chamsur)", "Fenugreek Leaf (Methi)",
        "Coriander Green", "Colocasia Leaf (Karkalo)", "Garlic Dry Chinese", "Garlic Dry Local", "Ginger (Aduwa)",
        "Chilli Green", "Lemon", "Apple(Jholey)", "Apple(Fuji)", "Banana", "Dozen", "Orange(Local)", "Orange(Indian)",
        "Mango(Malda)", "Mango(Chauri)", "Pomegranate (Anar)", "Watermelon", "Papaya(Local)", "Grapes(Green)",
        "Grapes(Black)", "Pineapple", "Piece", "Litchi", "Guava (Amba)", "Sweet Lime (Mausam)", "Mansuli Rice",
        "Quintal", "Jeera Masino Rice", "Basmati Rice Premium", "Wheat (Gahun)", "Maize Yellow (Makai)", "Millet (Kodo)",
        "Black Gram (Maas ko Daal)", "Red Lentil (Musuro Daal)", "Pigeon Pea (Rahar Daal)", "Green Gram (Mugi Daal)",
        "Chickpeas (Chana)", "Mustard Seed (Tori)", "Use your camera to identify pests and diseases", "Active Alerts",
        "Recent Scans", "Prevention Tips", "Search", "No active alerts. Your crops are looking healthy!",
        "No scans yet. Start by scanning a crop!", "Treatment: ", "Smart Kisan AI", "Your Expert Assistant",
        "Ask about farming...", "unread notifications", "Clear all", "Notification Summary", "Mark as read",
        "Your Fields", "Get Smart AI Recommendations", "Seasonal Tips", "Spring Season (Mar-May)",
        "Prepare land for planting.", "Watch for aphids.", "Clean irrigation channels.", "Crops in", "Water Needed",
        "Calculate Your Water Requirements", "Irrigation Method", "Calculate", "Hourly Forecast", "7-Day Forecast",
        "Farming Advice"
    ]
    keys_found.update(backend_keys)

    # 2. Check en.json
    base_path = 'assets/translations'
    with open(os.path.join(base_path, 'en.json'), 'r', encoding='utf-8') as f:
        en_data = json.load(f)
    
    missing_in_en = [k for k in keys_found if k not in en_data]
    print(f"Found {len(missing_in_en)} missing keys.")

    if not missing_in_en:
        return

    languages = {'en': 'en', 'hi': 'hi', 'ne': 'ne'}
    
    # Pre-translate all missing keys
    new_translations = {lang: {} for lang in languages}
    
    for i, key in enumerate(missing_in_en):
        try:
            print(f"Translating {i+1}/{len(missing_in_en)}: {key.encode('ascii', 'replace').decode('ascii')}")
        except:
            pass
        new_translations['en'][key] = key
        new_translations['hi'][key] = translate_text(key, 'hi')
        new_translations['ne'][key] = translate_text(key, 'ne')

    # Merge into files
    for lang, code in languages.items():
        filepath = os.path.join(base_path, f'{code}.json')
        if os.path.exists(filepath):
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            data.update(new_translations[code])
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"Saved {len(missing_in_en)} new keys to {code}.json")

if __name__ == '__main__':
    find_missing_keys()
