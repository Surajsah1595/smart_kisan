# Quick Localization Reference

## TL;DR - How to Add Localization to Any Page

### Step 1: Import
```dart
import 'localization_service_full.dart';
```

### Step 2: Replace Hardcoded Strings
```dart
// Before:
Text('Hello World')

// After:
Text(LocalizationService.translate('Hello World'))
```

### Step 3: If Key Doesn't Exist, Add to localization_service_full.dart
Find the `_translations` map and add your key to all 3 languages:

```dart
EN: {
  'your_key': 'English text here',
},
HI: {
  'your_key': 'हिंदी पाठ यहाँ',
},
NE: {
  'your_key': 'नेपाली पाठ यहाँ',
}
```

## Available Languages
- **English** → Code: `EN`
- **Hindi** → Code: `HI`  
- **Nepali** → Code: `NE`

## Common Translation Keys Already Available

### Navigation
- `'Home'`
- `'Settings'`
- `'Logout'`
- `'Back'`
- `'Next'`
- `'Skip'`

### Features
- `'Weather Forecast'`
- `'Crop Advisory'`
- `'Water Optimization'`
- `'Pest & Disease Help'`
- `'Notifications'`

### Authentication
- `'Email'`
- `'Password'`
- `'Sign In'`
- `'Sign Up'`
- `'Create Account'`

### Settings
- `'Language'`
- `'Theme'`
- `'Privacy & Security'`
- `'Profile Settings'`

## How Language Changes Work

1. User opens **Settings** 
2. User selects a language (English/Hindi/Nepali)
3. `LocalizationService.setLanguage()` is called
4. `LocalizationProvider` notifies all listeners
5. App rebuilds with new language
6. **All pages instantly update** ✨

## Files Modified

1. **main.dart** - Added StatefulWidget with language listener
2. **settings.dart** - Updated to use translations & handle language selection
3. **localization_service_full.dart** - Added LocalizationProvider class

## Testing Checklist

- [ ] Open app
- [ ] Navigate to Settings
- [ ] Click on Language section
- [ ] Select "English" - verify all text is in English
- [ ] Select "Hindi" - verify all text is in Hindi
- [ ] Select "Nepali" - verify all text is in Nepali
- [ ] Go back to home - verify language persists
- [ ] Try all pages - all should be in selected language

---

**That's it!** Your app now supports full localization across all 3 languages! 🎉
