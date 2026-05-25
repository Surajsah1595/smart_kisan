import json
import os

more_missing_keys = {
    "Recommended Products": {"en": "Recommended Products", "hi": "अनुशंसित उत्पाद", "ne": "सिफारिस गरिएका उत्पादनहरू"},
    "Early detection and treatment guidance": {"en": "Early detection and treatment guidance", "hi": "शीघ्र पहचान और उपचार मार्गदर्शन", "ne": "प्रारम्भिक पहिचान र उपचार मार्गदर्शन"},
    "Scan Now": {"en": "Scan Now", "hi": "अभी स्कैन करें", "ne": "अहिले स्क्यान गर्नुहोस्"},
    "Search Knowledge Base": {"en": "Search Knowledge Base", "hi": "ज्ञानकोष खोजें", "ne": "ज्ञान आधार खोज्नुहोस्"},
    "Find information about pests and diseases": {"en": "Find information about pests and diseases", "hi": "कीटों और बीमारियों के बारे में जानकारी प्राप्त करें", "ne": "कीरा र रोगहरूको बारेमा जानकारी खोज्नुहोस्"},
    "Analyzing crop image...": {"en": "Analyzing crop image...", "hi": "फसल छवि का विश्लेषण किया जा रहा है...", "ne": "बाली छविको विश्लेषण गर्दै..."},
    "Weather Forecast": {"en": "Weather Forecast", "hi": "मौसम का पूर्वानुमान", "ne": "मौसम पूर्वानुमान"},
    "No notifications": {"en": "No notifications", "hi": "कोई सूचना नहीं", "ne": "कुनै सूचना छैन"},
    "No unread notifications to show": {"en": "No unread notifications to show", "hi": "दिखाने के लिए कोई अपठित सूचना नहीं", "ne": "देखाउन कुनै नपढिएको सूचना छैन"},
    "Failed to update theme": {"en": "Failed to update theme", "hi": "थीम अपडेट करने में विफल", "ne": "विषय अद्यावधिक गर्न असफल भयो"},
    "Failed to update profile. Please try again.": {"en": "Failed to update profile. Please try again.", "hi": "प्रोफ़ाइल अपडेट करने में विफल। कृपया पुनः प्रयास करें।", "ne": "प्रोफाइल अद्यावधिक गर्न असफल भयो। कृपया फेरि प्रयास गर्नुहोस्।"},
    "Failed to change password. Please verify your old password and try again.": {"en": "Failed to change password. Please verify your old password and try again.", "hi": "पासवर्ड बदलने में विफल। कृपया अपना पुराना पासवर्ड सत्यापित करें और पुनः प्रयास करें।", "ne": "पासवर्ड परिवर्तन गर्न असफल भयो। कृपया आफ्नो पुरानो पासवर्ड प्रमाणित गर्नुहोस् र फेरि प्रयास गर्नुहोस्।"},
    "About Notifications": {"en": "About Notifications", "hi": "सूचनाओं के बारे में", "ne": "सूचनाहरूको बारेमा"},
    "We recommend keeping critical alerts like weather and pest notifications enabled to stay informed about important farming conditions.": {"en": "We recommend keeping critical alerts like weather and pest notifications enabled to stay informed about important farming conditions.", "hi": "हम महत्वपूर्ण खेती की स्थितियों के बारे में सूचित रहने के लिए मौसम और कीट सूचनाओं जैसे महत्वपूर्ण अलर्ट को सक्षम रखने की सलाह देते हैं।", "ne": "हामी महत्त्वपूर्ण खेती अवस्थाहरूको बारेमा सूचित रहन मौसम र कीरा सूचनाहरू जस्ता महत्त्वपूर्ण अलर्टहरू सक्षम राख्न सिफारिस गर्छौं।"}
}

base_path = 'assets/translations'
languages = ['en', 'hi', 'ne']

for lang in languages:
    filepath = os.path.join(base_path, f'{lang}.json')
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        updated = False
        for key, translations in more_missing_keys.items():
            if key not in data:
                data[key] = translations[lang]
                updated = True
                
        if updated:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"Updated {lang}.json with more missing keys.")
