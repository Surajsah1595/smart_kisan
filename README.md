# Smart Kisan: Digital Farming Assistant

> An AI-powered mobile application built with Flutter & Firebase that helps farmers make data-driven decisions about crop management, pest detection, water optimization, and market pricing — all in one place.

**Student:** Suraj Sah (Student ID: 2408185)  
**Supervisor:** Mr. Rahul Parajuli  
**Reader:** Mr. Siman Giri
**Platform:** Android (Flutter)  
**Version:** 1.0.0

---

## Table of Contents

1. [What is Smart Kisan?](#what-is-smart-kisan)
2. [Prerequisites](#prerequisites)
3. [Setup & Installation](#setup--installation)
4. [Project Structure](#project-structure)
5. [Complete User Journey (A to Z)](#complete-user-journey-a-to-z)
   - [Step 1: Welcome Screen](#step-1-welcome-screen)
   - [Step 2: Language Selection](#step-2-language-selection)
   - [Step 3: Onboarding Carousel](#step-3-onboarding-carousel)
   - [Step 4: Sign Up / Log In](#step-4-sign-up--log-in)
   - [Step 5: Home Dashboard](#step-5-home-dashboard)
   - [Step 6: Weather Monitoring](#step-6-weather-monitoring)
   - [Step 7: Crop Advisory](#step-7-crop-advisory)
   - [Step 8: Water Optimization](#step-8-water-optimization)
   - [Step 9: Pest & Disease Detection](#step-9-pest--disease-detection)
   - [Step 10: Market Prices](#step-10-market-prices)
   - [Step 11: AI Chat Assistant](#step-11-ai-chat-assistant)
   - [Step 12: Notifications](#step-12-notifications)
   - [Step 13: Settings & Profile](#step-13-settings--profile)
   - [Step 14: Logging Out](#step-14-logging-out)
6. [Technology Stack](#technology-stack)
7. [API Keys & Configuration](#api-keys--configuration)
8. [Troubleshooting](#troubleshooting)

---

## What is Smart Kisan?

Smart Kisan is a comprehensive digital farming assistant designed for smallholder farmers in South Asia (India & Nepal). The app bridges the gap between traditional farming and modern technology by providing:

- **AI-powered crop recommendations** using both local ML models and the Gemini AI API
- **Real-time weather monitoring** with GPS-based location detection
- **Computer vision pest detection** — scan a plant leaf photo to identify diseases
- **Precision irrigation calculator** backed by FAO scientific standards
- **Live market prices** for agricultural commodities
- **Trilingual support** — English, Hindi, and Nepali
- **Light/Dark mode** with Material 3 dynamic theming

---

## Prerequisites

Before running the app, make sure you have the following installed on your machine:

| Tool | Version | Purpose |
|------|---------|---------|
| **Flutter SDK** | ≥ 3.2.3, < 4.0.0 | Core mobile framework |
| **Dart SDK** | Bundled with Flutter | Programming language |
| **Android Studio** or **VS Code** | Latest | IDE with Flutter plugins |
| **Android SDK** | API 21+ | Android build tools |
| **Python** | 3.8+ | ML Backend server |
| **Git** | Any | Version control |
| **Firebase CLI** | Latest | Firebase project management |
| **A physical Android device or Emulator** | — | Testing |

---

## Setup & Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Surajsah1595/smart_kisan.git
cd smart_kisan
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

The app uses Firebase for authentication, Firestore database, cloud storage, and push notifications. The `firebase_options.dart` file is already configured. If you need to reconfigure:

```bash
# Install FlutterFire CLI if not already installed
dart pub global activate flutterfire_cli

# Configure Firebase for your own project
flutterfire configure
```

### 4. Set Up the ML Backend (Optional — for Crop Recommendations)

The ML backend provides a local Random Forest model for crop recommendations.

```bash
cd ml_backend
pip install -r requirements.txt
python app.py
```

> **Note:** If testing on a physical Android device connected via USB, run:
> ```bash
> adb reverse tcp:8000 tcp:8000
> ```
> This forwards port 8000 from your PC to the phone so the app can reach `http://127.0.0.1:8000`.

### 5. Run the App

```bash
flutter run
```

Or press **F5** in VS Code with a device connected.

---

## Project Structure

```
smart_kisan/
├── lib/                          # All Flutter source code
│   ├── main.dart                 # App entry point, theme config, Firebase init
│   ├── welcome_screen.dart       # Splash, language picker, onboarding
│   ├── user_registration.dart    # Login, Sign-up, Forgot Password flows
│   ├── home_page.dart            # Central dashboard (weather, grid, activities)
│   ├── weather_page.dart         # Detailed weather forecasts
│   ├── weather_service.dart      # OpenWeatherMap API integration
│   ├── crop_advisory.dart        # Field & crop management + AI advisory
│   ├── water_optimization.dart   # Precision irrigation calculator
│   ├── pest_disease_help.dart    # Pest scanning UI (camera/gallery)
│   ├── pest_disease_service.dart # Gemini AI pest analysis + Firestore
│   ├── market_price_page.dart    # Live Kalimati market commodity prices
│   ├── ai_chat_page.dart         # Free-form AI farming assistant chat
│   ├── ai_service.dart           # Gemini AI SDK wrapper
│   ├── notification.dart         # Notification center UI
│   ├── notification_service.dart # FCM + local notification logic
│   ├── settings.dart             # Profile, theme, units, privacy, security
│   ├── auth_service.dart         # Firebase Auth wrapper (email, Google, biometric)
│   ├── localization_service.dart # Trilingual translation engine
│   ├── translations_map.dart     # 600+ translated string pairs (EN/HI/NE)
│   ├── app_config.dart           # Network routing config (local vs tunnel)
│   └── firebase_options.dart     # Auto-generated Firebase project config
├── ml_backend/                   # Python FastAPI ML server
│   ├── app.py                    # FastAPI endpoints
│   ├── crop_model.pkl            # Trained Random Forest model
│   └── requirements.txt          # Python dependencies
├── assets/                       # Images, fonts, icons, translations
│   ├── translations/             # JSON locale files (en.json, hi.json, ne.json)
│   ├── Logo.png                  # App logo
│   ├── sk.jpg                    # Welcome screen background
│   ├── Onboarding1.png           # Onboarding illustrations
│   ├── Onboarding2.png
│   ├── Onboarding3.png
│   ├── Ls.png                    # Login screen illustration
│   └── Fp.png                    # Forgot password illustration
├── pubspec.yaml                  # Flutter project config & dependencies
└── README.md                     # This file
```

---

## Complete User Journey (A to Z)

Below is the full walkthrough of every screen and feature in Smart Kisan, in the exact order a new user would experience them.

---

### Step 1: Welcome Screen

**File:** `lib/welcome_screen.dart`

When you first open the app, you see a fullscreen splash screen with:

- The **Smart Kisan logo** and app name
- The tagline **"Empowering Farmers"**
- Two buttons:
  - **"Get Started"** → Takes you to the language selection (for new users)
  - **"Log In"** → Jumps directly to the login screen (for returning users)

The background is a high-quality agricultural image with a dark overlay for readability.

---

### Step 2: Language Selection

**File:** `lib/welcome_screen.dart` (screen index 1)

After tapping "Get Started", you choose your preferred language:

| Language | Flag | Code |
|----------|------|------|
| English | 🇬🇧 | EN |
| Nepali | 🇳🇵 | NE |
| Hindi | 🇮🇳 | HI |

- Tap a language card to select it (it highlights with a green border)
- Press **"Next"** to confirm — the entire UI instantly translates
- Your choice is saved to `SharedPreferences` and persists across app restarts
- You can also press **"Skip"** to go directly to login with default English

---

### Step 3: Onboarding Carousel

**File:** `lib/welcome_screen.dart` (screen indexes 2, 3, 4)

Three swipeable screens introduce the app's core capabilities:

1. **Monitoring Soil & Plant** — "We aim to use optical (VIR) sensing to observe the fields."
2. **Crop Selection** — "Our project can use AI & Machine learning to select the best crop."
3. **Improve Agriculture Precision** — "We will use satellite imagery, deep learning, computer vision..."

Each screen has:
- An illustration image
- A title and description
- Progress dots (4 total: language + 3 features)
- **Back** and **Next** navigation buttons
- A **Skip** button to jump straight to login

After the third screen, pressing **"Next"** takes you to the Login screen.

---

### Step 4: Sign Up / Log In

**File:** `lib/user_registration.dart`

#### Login Screen
- Enter your **Email** and **Password**
- Tap **"Log In"** to authenticate via Firebase Auth
- Alternatively, sign in with:
  - **Google Sign-In** (OAuth)
  - **Facebook Login**
  - **Fingerprint/Biometric** authentication (if previously set up)
- Tap **"Forgot Password?"** to receive a reset link via email
- Tap **"Create an Account"** if you're a new user

#### Sign Up Screen
- Fill in: **First Name**, **Last Name**, **Email**, **Password**, **Confirm Password**
- Form validation checks:
  - Non-empty fields
  - Valid email format (contains `@`)
  - Password minimum 6 characters
  - Passwords match
- On success, a new Firebase Auth account is created, user profile is saved to Firestore, and you're redirected to the Home Dashboard

#### Forgot Password Flow
1. Enter your email → Firebase sends a reset link
2. Check your inbox, click the link, set a new password
3. Return to the login screen to sign in with the new password

---

### Step 5: Home Dashboard

**File:** `lib/home_page.dart`

The central hub of the app. After logging in, you land here. The dashboard displays:

#### Top App Bar
- **Profile picture** (tap to go to Settings)
- **"Smart Kisan"** title with a greeting: *"Welcome, [Your Name]"*
- **Location name** (auto-detected via GPS)
- **Notification bell** with a red badge showing unread count
- **Settings gear icon**

#### Weather Card
- Shows **current temperature**, **condition** (Clear, Rain, etc.), and a color-coded farming advice chip:
  - 🟢 "Good Field Conditions" (normal weather)
  - 🟡 "Irrigation Needed" (temperature > 30°C)
  - 🔴 "Rain Detected" (rainy weather)
  - 🔵 "Cold Stress Risk" (temperature < 10°C)
- Shows humidity, wind speed, visibility, and feels-like temperature
- **Tap the card** to open the full Weather Page

#### Feature Grid (6 Modules)
A 2×3 grid of cards, each leading to a core module:

| Card | Icon | Destination |
|------|------|-------------|
| Crop Advisory | 🌾 | Crop Advisory Screen |
| Weather | ☁️ | Weather Page |
| Pest & Disease | 🐛 | Pest Detection Screen |
| Water Optimization | 💧 | Water Calculator Screen |
| Market Prices | 📊 | Market Price Page |
| AI Assistant | 🤖 | AI Chat Page |

#### Farm Overview Section
Real-time statistics pulled from Firestore:
- **Active Crops** — total count across all your fields
- **Alerts** — number of unresolved pest/disease alerts
- **Yield Rate** — overall health score
- **Tasks Done** — completed activities derived from notifications

#### Language Card
Quick-access card to change the app language without going to Settings.

#### Recent Activity Feed
Shows the last 5 events (notifications + pest alerts) with relative timestamps like *"5 minutes ago"* or *"2 days ago"*.

#### Bottom Navigation Bar
Three tabs for quick navigation:
- **Home** (Dashboard)
- **Advisory** (Crop Advisory)
- **Chat** (AI Assistant)

---

### Step 6: Weather Monitoring

**File:** `lib/weather_page.dart` + `lib/weather_service.dart`

A full-featured weather dashboard:

- **Auto-detects your GPS location** using the Geolocator plugin
- Calls the **OpenWeatherMap API** for real-time data
- Displays:
  - Current temperature, humidity, wind speed, pressure
  - Weather condition with icon (Clear, Clouds, Rain, Snow, etc.)
  - Feels-like temperature and visibility
  - 5-day / 3-hour forecast
- **Agricultural weather advice** — the app evaluates conditions and provides farming-specific guidance:
  - Heat stress warnings for crops when temp > 35°C
  - Frost risk alerts when temp < 5°C
  - Heavy rain waterlogging warnings
  - Optimal spraying conditions advisories
- Weather data is also pushed as **notifications** when dangerous thresholds are crossed

---

### Step 7: Crop Advisory

**File:** `lib/crop_advisory.dart`

This module lets you manage your physical agricultural fields and the crops planted in them.

#### Managing Fields
1. Tap **"Add Field"** to create a new field
2. Fill in: **Field Name** (e.g., "South Field"), **Size** (e.g., "2 Acres"), **Soil Type** (dropdown: Loamy, Clay, Sandy, Silt, Peaty, Chalky, Black)
3. Tap **"Save"** — the field is stored in Firestore under your user account
4. Select a field by tapping it (highlighted with a green border and checkmark)
5. Limits: Maximum **10 fields per user**, with a 2-second cooldown between creations (rate limiting)

#### Managing Crops
1. With a field selected, tap **"Add Crop"**
2. Either:
   - **Type a custom crop name** and tap "Add Custom Crop"
   - **Select from 45+ predefined crops** (Rice, Wheat, Maize, Potato, Tomato, Sugarcane, Tea, Banana, Mango, etc.) — each comes with pre-filled season, duration, and water need data
3. Limits: Maximum **20 crops per field**, with a 1-second cooldown

#### AI Recommendations
- With a field and crops selected, tap **"Get Smart AI Recommendations"**
- The app sends your field data (soil type, location, crops, weather) to the **Gemini AI API**
- Returns personalized recommendations: best planting times, fertilizer advice, pest risk warnings, and yield optimization tips
- Results are shown in a scrollable markdown dialog

#### Seasonal Tips
Auto-generated based on the current month:
- **Winter (Nov-Feb):** Reduce watering, protect from frost
- **Spring (Mar-May):** Prepare land, watch for aphids
- **Monsoon (Jun-Sep):** Ensure drainage, harvest rainwater
- **Autumn (Oct):** Harvest monsoon crops, prepare soil for wheat

---

### Step 8: Water Optimization

**File:** `lib/water_optimization.dart`

A precision irrigation calculator backed by FAO Irrigation & Drainage Paper 56.

#### How to Use It
1. Enter your **Land Area** and select the unit (Acres, Hectares, or Sq. Meters)
2. **Search and select a crop** from the autocomplete field (150+ crops in the database, from Rice to Aloe Vera)
3. Select your **Soil Type** (Sandy, Sandy-Loam, Loamy, Clay-Loam, Clay, Silty)
4. Select your **Irrigation Method**:
   - Drip (90% efficient)
   - Sprinkler (75% efficient)
   - Flood (50% efficient)
5. Tap **"Calculate"**

#### What Happens Behind the Scenes
1. The crop name is validated by **Gemini AI** to confirm it's a real agricultural crop
2. **Live weather** is fetched to determine current rainfall
3. The math engine calculates:
   - **Baseline ET** (evapotranspiration) per crop lifecycle stage (Seedling 20%, Mid-Season 60%, Harvesting 20%)
   - **Effective Rainfall** (P_eff = Rain × 0.7)
   - **Net Irrigation** (I_net = Baseline - P_eff)
   - **Gross Irrigation** (I_gross = I_net / Efficiency)
   - **Daily water** (I_gross × Area in sqm)
   - **Total season water** (Daily × Growing days)

#### Results Dialog
Shows:
- **Daily Water Needed** (in liters/day) — large, highlighted
- **Total Season Water** (in liters)
- **Growing Season** (in days)
- **Weather status** (current rain forecast)
- **AI Recommendation** (methodological breakdown)

#### Calculation History
- All calculations are saved to Firestore and displayed below the form
- Shows crop name, area, total/daily water, soil type, and growing days
- Each entry can be **deleted** with a confirmation dialog

---

### Step 9: Pest & Disease Detection

**File:** `lib/pest_disease_help.dart` + `lib/pest_disease_service.dart`

An AI-powered crop health scanner.

#### How to Scan
1. Tap **"Scan Now"** on the Scan Your Crop card
2. Choose **Camera** (take a photo) or **Gallery** (select existing photo)
3. The image is encoded to base64 and sent to the **Gemini AI API** with a detailed prompt
4. AI analyzes the image and returns:
   - **Crop name** identified from the photo
   - **Status** — Healthy, Disease Detected, or Pest Detected
   - **Confidence** percentage
   - **Disease/Pest name** (if detected)
   - **Severity** — Low, Medium, or High
   - **Description** of the issue
   - **Treatment** recommendations
   - **Product recommendations** (specific fungicides/pesticides with dosage)

#### Active Alerts
- All detected issues are saved to Firestore as "Pest Alerts"
- They appear as color-coded cards:
  - 🔴 **High** severity — red border
  - 🟡 **Medium** severity — yellow/amber
  - 🟢 **Low** severity — green
- Tap an alert to see the **full detailed analysis** in a dialog with treatment steps and product recommendations

#### Recent Scans
- Shows your last 5 scans with crop name, date, status, and confidence percentage
- Tap any scan to review the full results

#### Prevention Tips
A static checklist of best practices:
- Regular field inspections
- Crop rotation
- Proper plant spacing
- Remove plant debris
- Use disease-resistant varieties

#### Knowledge Base Search
- Type any pest or disease name to search
- AI returns a detailed markdown response with identification info and treatment guidance

---

### Step 10: Market Prices

**File:** `lib/market_price_page.dart`

Live agricultural commodity prices from the Kalimati Fruits and Vegetables Market.

- Displays a **searchable, sortable table** of commodities
- Each entry shows: **Commodity name**, **Unit**, **Minimum price**, **Maximum price**, **Average price**
- Data is fetched in real-time from an external market data API
- Fully supports **Light/Dark mode** with proper contrast
- Prices are in Nepalese Rupees (NPR)

---

### Step 11: AI Chat Assistant

**File:** `lib/ai_chat_page.dart` + `lib/ai_service.dart`

A free-form conversational AI powered by **Google Gemini API**.

- Ask any farming-related question in natural language
- The AI responds with detailed, context-aware advice
- Responses are rendered in **Markdown format** (bold, bullet points, headers)
- Chat history is maintained during the session
- Examples of questions you can ask:
  - "What fertilizer should I use for wheat in clay soil?"
  - "When is the best time to plant rice in Nepal?"
  - "My tomato leaves are turning yellow, what should I do?"
  - "How much water does sugarcane need per day?"

---

### Step 12: Notifications

**File:** `lib/notification.dart` + `lib/notification_service.dart`

A comprehensive notification center:

- **Real-time push notifications** via Firebase Cloud Messaging (FCM)
- **Local notifications** for weather alerts, irrigation reminders, pest detections
- Notification types include:
  - ⛈️ Weather alerts (extreme heat, frost, heavy rain)
  - 🐛 Pest/disease detection results
  - 💧 Water optimization calculation summaries
  - 🌾 Field/crop creation confirmations
  - ⚠️ Low soil moisture alerts
- **Notification center** screen shows all notifications with:
  - Title and message
  - Timestamp
  - Read/unread status
  - Priority level (Normal/High)
- High-priority unread notifications also trigger an **in-app snackbar** alert
- The notification bell on the Home Dashboard shows the **unread count badge**

---

### Step 13: Settings & Profile

**File:** `lib/settings.dart`

A full-featured settings panel with multiple sections:

#### Profile Management
- View and edit: **Full Name**, **Farm Name**, **Email**, **Phone**, **Location**
- **Profile Picture**: Take a photo with camera or choose from gallery
- Changes are synced to Firebase Auth and Firestore

#### App Preferences
- **Language**: Switch between English, Hindi, Nepali (instant UI rebuild)
- **Theme**: Light Mode, Dark Mode, or Auto (follows system setting)
- **Temperature Unit**: Celsius (°C) or Fahrenheit (°F)
- **Area Unit**: Acres, Hectares, or Square Meters
- **Volume Unit**: Liters or Gallons

#### Notification Preferences
Toggle individual alert categories on/off:
- Weather Alerts
- Pest & Disease Alerts
- Irrigation Reminders
- Crop Health Updates
- General Updates

Toggle delivery channels:
- Push Notifications
- Email Notifications

#### Security
- **Change Password** — requires current password verification (re-authentication)
- **Two-Factor Authentication** toggle
- **Logout from All Sessions** — invalidates all active tokens

#### Data & Privacy
- **Share Usage Data** toggle
- **Analytics** toggle
- **Location Tracking** toggle
- **Export Data** — downloads all your data as a JSON file to your device
- **Delete Account** — permanently deletes your account and all associated data (requires password confirmation)

---

### Step 14: Logging Out

There are two ways to sign out:

#### Quick Logout
1. From the **Home Dashboard**, tap the **Settings gear icon** (top right)
2. Scroll down to find the **"Sign Out"** option
3. Tap it → Confirmation dialog appears
4. Confirm → Firebase Auth session is destroyed, you're redirected back to the **Welcome Screen**

#### Logout from All Sessions
1. Go to **Settings** → **Security**
2. Tap **"Logout from All Sessions"**
3. This sets a server timestamp in Firestore that invalidates all active tokens across devices
4. You are signed out on the current device as well

After logging out, the app returns to the Welcome Screen where you can log in again or create a new account.

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.2+ (Dart) | Cross-platform mobile UI |
| **Backend (Auth)** | Firebase Authentication | Email/password, Google, Facebook, Biometric login |
| **Database** | Cloud Firestore | Real-time NoSQL database for all user data |
| **Storage** | Firebase Storage | Profile image storage |
| **Push Notifications** | FCM + flutter_local_notifications | Real-time alerts |
| **AI/ML** | Google Gemini API (`google_generative_ai`) | Crop validation, pest detection, chat assistant |
| **ML Backend** | Python FastAPI + Scikit-learn | Random Forest crop recommendation model |
| **Weather API** | OpenWeatherMap API | GPS-based real-time weather data |
| **Market Data** | Kalimati Market API | Live commodity pricing |
| **Localization** | easy_localization + custom LocalizationService | Trilingual support (EN/HI/NE) |
| **Location** | Geolocator plugin | Device GPS coordinates |
| **Biometrics** | local_auth plugin | Fingerprint authentication |
| **State Management** | Provider + setState | UI reactivity |
| **Theming** | Material 3 (Material Design 3) | Dynamic light/dark theme with seed color `#2C7C48` |

---

## API Keys & Configuration

The app requires the following API keys (configured in the respective service files):

| API | Config Location | Purpose |
|-----|----------------|---------|
| **Firebase** | `lib/firebase_options.dart` | Auth, Firestore, Storage, FCM |
| **Gemini AI** | `lib/ai_service.dart` | AI crop validation, pest detection, chat |
| **OpenWeatherMap** | `lib/weather_service.dart` | Weather data |

> **Security Note:** For production, API keys should be moved to environment variables or a secure vault. The current setup stores them in code for academic demonstration purposes.

The ML backend URL is configured in `lib/app_config.dart`:
- **Local USB testing:** `http://127.0.0.1:8000` (default)
- **Remote tunnel:** Set `useTunnel = true` and update the `_tunnelUrl`

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `flutter pub get` fails | Make sure Flutter SDK ≥ 3.2.3 is installed. Run `flutter doctor` to check. |
| Firebase errors on launch | Ensure `google-services.json` (Android) is in `android/app/`. Run `flutterfire configure` if needed. |
| ML Backend unreachable | Check that `python app.py` is running. For physical devices, run `adb reverse tcp:8000 tcp:8000`. |
| Weather not loading | Check GPS permissions are granted. Ensure OpenWeatherMap API key is valid. |
| Notifications not showing | Ensure notification permissions are granted on the device. Check FCM configuration. |
| Login fails | Verify Firebase Auth is enabled in your Firebase Console (Email/Password provider). |
| App shows English only | Go to Settings → Language, or restart the app after changing language in the Welcome Screen. |
| Dark mode not working | Go to Settings → Theme → select "Dark Mode" or "Auto Mode". |

---

Built as a Final Year Project at Herald College Kathmandu.  
For detailed technical specifications, refer to [`SMART_KISAN_FULL_COMPONENTS_SPEC.md`](SMART_KISAN_FULL_COMPONENTS_SPEC.md).
