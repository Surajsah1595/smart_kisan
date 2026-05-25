import json
import os

even_more_keys = {
    "Export My Data": {"en": "Export My Data", "hi": "मेरा डेटा निर्यात करें", "ne": "मेरो डाटा निर्यात गर्नुहोस्"},
    "Delete Account": {"en": "Delete Account", "hi": "खाता हटाएं", "ne": "खाता मेटाउनुहोस्"},
    "© 2026 Smart Kisan. All rights reserved.": {"en": "© 2026 Smart Kisan. All rights reserved.", "hi": "© 2026 स्मार्ट किसान। सभी अधिकार सुरक्षित।", "ne": "© २०२६ स्मार्ट किसान। सबै अधिकार सुरक्षित।"},
    "Good Field Conditions": {"en": "Good Field Conditions", "hi": "खेत की अच्छी स्थितियाँ", "ne": "खेतको राम्रो अवस्था"},
    "घर": {"en": "Home", "hi": "होम", "ne": "घर"},
    "एआईलाई सोध्नुहोस्": {"en": "Ask AI", "hi": "एआई से पूछें", "ne": "एआईलाई सोध्नुहोस्"},
    "कीरा र रोग": {"en": "Pest & Disease", "hi": "कीट और रोग", "ne": "कीरा र रोग"},
    "फसल थप्नुहोस्": {"en": "Add Crop", "hi": "फसल जोड़ें", "ne": "फसल थप्नुहोस्"},
    "होम": {"en": "Home", "hi": "होम", "ne": "घर"},
    "एआई से पूछें": {"en": "Ask AI", "hi": "एआई से पूछें", "ne": "एआईलाई सोध्नुहोस्"},
    "कीट और रोग": {"en": "Pest & Disease", "hi": "कीट और रोग", "ne": "कीरा र रोग"},
    "फसल जोड़ें": {"en": "Add Crop", "hi": "फसल जोड़ें", "ne": "फसल थप्नुहोस्"},
    "Market Prices": {"en": "Market Prices", "hi": "बाजार भाव", "ne": "बजार मूल्य"},
    "Notification Settings": {"en": "Notification Settings", "hi": "अधिसूचना सेटिंग्स", "ne": "सूचना सेटिङहरू"},
    "Manage your alerts and notifications": {"en": "Manage your alerts and notifications", "hi": "अपने अलर्ट और सूचनाएं प्रबंधित करें", "ne": "आफ्नो अलर्ट र सूचनाहरू व्यवस्थापन गर्नुहोस्"},
    "Active Notifications": {"en": "Active Notifications", "hi": "सक्रिय सूचनाएं", "ne": "सक्रिय सूचनाहरू"},
    "You have 7 notifications enabled": {"en": "You have 7 notifications enabled", "hi": "आपके पास 7 सूचनाएं सक्षम हैं", "ne": "तपाईंसँग ७ सूचनाहरू सक्षम छन्"},
    "7/9": {"en": "7/9", "hi": "7/9", "ne": "७/९"},
    "Manage Notifications": {"en": "Manage Notifications", "hi": "सूचनाएं प्रबंधित करें", "ne": "सूचनाहरू व्यवस्थापन गर्नुहोस्"},
    "Language": {"en": "Language", "hi": "भाषा", "ne": "भाषा"},
    "Select your preferred language": {"en": "Select your preferred language", "hi": "अपनी पसंदीदा भाषा चुनें", "ne": "आफ्नो मनपर्ने भाषा चयन गर्नुहोस्"},
    "Theme": {"en": "Theme", "hi": "थीम", "ne": "विषय"},
    "Choose your display theme": {"en": "Choose your display theme", "hi": "अपनी डिस्प्ले थीम चुनें", "ne": "आफ्नो प्रदर्शन विषय छान्नुहोस्"},
    "Light Mode": {"en": "Light Mode", "hi": "लाइट मोड", "ne": "हल्का मोड"},
    "Dark Mode": {"en": "Dark Mode", "hi": "डार्क मोड", "ne": "अँध्यारो मोड"},
    "Auto Mode": {"en": "Auto Mode", "hi": "ऑटो मोड", "ne": "स्वत: मोड"},
    "Units of Measurement": {"en": "Units of Measurement", "hi": "माप की इकाइयाँ", "ne": "मापनको एकाइहरू"},
    "Set your preferred units": {"en": "Set your preferred units", "hi": "अपनी पसंदीदा इकाइयाँ सेट करें", "ne": "आफ्नो मनपर्ने एकाइहरू सेट गर्नुहोस्"},
    "Temperature": {"en": "Temperature", "hi": "तापमान", "ne": "तापक्रम"},
    "Celsius (°C)": {"en": "Celsius (°C)", "hi": "सेल्सियस (°C)", "ne": "सेल्सियस (°C)"},
    "Fahrenheit (°F)": {"en": "Fahrenheit (°F)", "hi": "फ़ारेनहाइट (°F)", "ne": "फरेनहाइट (°F)"},
    "Area": {"en": "Area", "hi": "क्षेत्र", "ne": "क्षेत्रफल"},
    "Acres": {"en": "Acres", "hi": "एकड़", "ne": "एकर"},
    "Hectares": {"en": "Hectares", "hi": "हेक्टेयर", "ne": "हेक्टर"},
    "Volume": {"en": "Volume", "hi": "आयतन", "ne": "भोल्युम"},
    "Gallons": {"en": "Gallons", "hi": "गैलन", "ne": "ग्यालन"},
    "Privacy & Security": {"en": "Privacy & Security", "hi": "गोपनीयता और सुरक्षा", "ne": "गोपनीयता र सुरक्षा"},
    "Manage your privacy settings": {"en": "Manage your privacy settings", "hi": "अपनी गोपनीयता सेटिंग्स प्रबंधित करें", "ne": "आफ्नो गोपनीयता सेटिङहरू व्यवस्थापन गर्नुहोस्"},
    "Share Usage Data": {"en": "Share Usage Data", "hi": "उपयोग डेटा साझा करें", "ne": "प्रयोग डाटा साझेदारी गर्नुहोस्"},
    "Help improve the app": {"en": "Help improve the app", "hi": "ऐप को बेहतर बनाने में मदद करें", "ne": "अनुप्रयोग सुधार गर्न मद्दत गर्नुहोस्"},
    "Analytics": {"en": "Analytics", "hi": "एनालिटिक्स", "ne": "एनालिटिक्स"},
    "Allow analytics tracking": {"en": "Allow analytics tracking", "hi": "एनालिटिक्स ट्रैकिंग की अनुमति दें", "ne": "एनालिटिक्स ट्र्याकिङ अनुमति दिनुहोस्"},
    "Location Tracking": {"en": "Location Tracking", "hi": "स्थान ट्रैकिंग", "ne": "स्थान ट्र्याकिङ"},
    "For weather and field data": {"en": "For weather and field data", "hi": "मौसम और खेत के डेटा के लिए", "ne": "मौसम र खेत डाटाको लागि"},
    "Change Password": {"en": "Change Password", "hi": "पासवर्ड बदलें", "ne": "पासवर्ड परिवर्तन गर्नुहोस्"},
    "About": {"en": "About", "hi": "के बारे में", "ne": "बारेमा"},
    "App information and version": {"en": "App information and version", "hi": "ऐप की जानकारी और संस्करण", "ne": "अनुप्रयोग जानकारी र संस्करण"},
    "Smart Kisan App": {"en": "Smart Kisan App", "hi": "स्मार्ट किसान ऐप", "ne": "स्मार्ट किसान अनुप्रयोग"},
    "Version 1.0.0": {"en": "Version 1.0.0", "hi": "संस्करण 1.0.0", "ne": "संस्करण १.०.०"},
    "Logout": {"en": "Logout", "hi": "लॉग आउट", "ne": "लग आउट गर्नुहोस्"}
}

base_path = 'assets/translations'
languages = ['en', 'hi', 'ne']

for lang in languages:
    filepath = os.path.join(base_path, f'{lang}.json')
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        updated = False
        for key, translations in even_more_keys.items():
            if key not in data:
                data[key] = translations[lang]
                updated = True
                
        if updated:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"Updated {lang}.json with even more missing keys.")
