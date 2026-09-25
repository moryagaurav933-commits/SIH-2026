# 📱 Krishi-Saarthi Mobile & Web Application

> **Trilingual Flutter Client for Android, iOS, macOS Desktop, and Google Chrome**  
> An edge-first agricultural companion designed for Indian farmers with offline capabilities, deep learning disease diagnosis, and cross-platform voice copilot.

---

## 🏛️ Frontend Architecture

The Flutter application follows a clean, decoupled architecture utilizing `Provider` for state management, `LocalDB` for offline-first data persistence, and an abstraction layer for cross-platform hardware access.

```text
mobile_app/lib/
├── main.dart                          # Application entry point & Provider registration
├── localization/
│   └── app_translations.dart         # Trilingual translation dictionaries (10 languages)
├── providers/
│   ├── language_provider.dart        # Language state & persistent locale switching
│   └── weather_provider.dart         # Weather polling, GPS coordinates & agro-advisory
├── db/
│   └── local_db.dart                 # Local database storage for offline access
├── screens/
│   ├── home_screen.dart              # Main dashboard hub with animated cards & ticker
│   ├── diagnosis/
│   │   └── diagnosis_screen.dart     # Leaf photo upload & AI pathology report viewer
│   ├── voice_chat/
│   │   ├── voice_chat_screen.dart    # Trilingual AI Voice Copilot screen
│   │   ├── speech_bridge.dart        # Unified cross-platform speech interface
│   │   ├── speech_bridge_web.dart    # W3C Web Speech API via dart:js_interop
│   │   ├── speech_bridge_stub.dart   # Native platform audio fallback
│   │   └── camera_capture_sheet.dart # In-browser high-res camera capture modal
│   ├── mandi/
│   │   └── mandi_screen.dart         # Agmarknet live wholesale mandi commodity rates
│   ├── weather/
│   │   └── weather_screen.dart       # Hyperlocal 5-day weather & spray forecast
│   ├── insurance/
│   │   └── insurance_screen.dart     # PMFBY tamper-proof crop damage claim logger
│   ├── dashboard/
│   │   └── dashboard_screen.dart     # Farm overview, plot moisture & analytics
│   └── settings/
│   │   └── settings_screen.dart      # Language selector & user preferences
├── services/
│   ├── api_config.dart               # Dynamic backend host resolution (Web/Simulator/Device)
│   ├── cv_service.dart               # Disease diagnosis API dispatcher
│   ├── llm_service.dart              # AI Copilot conversational engine
│   ├── insurance_recorder.dart       # Evidence vault & GPS geotagging recorder
│   └── weather_mandi_service.dart    # Open-Meteo & Agmarknet client
└── test/                             # Flutter widget & unit test suites
```

---

## 🎙️ The Cross-Platform Speech Bridge

A key highlight of the app is its seamless Speech-to-Text (STT) and Text-to-Speech (TTS) engine that compiles without errors across Web and Native:

- **Web (Chrome, Edge, Safari)**:
  - Uses [`speech_bridge_web.dart`](file:///Files/SIH2026.%204/mobile_app/lib/screens/voice_chat/speech_bridge_web.dart) via modern `dart:js_interop`.
  - Connects directly to the browser's native `webkitSpeechRecognition` and `window.speechSynthesis`.
- **Native (macOS, iOS, Android)**:
  - Uses [`speech_bridge_stub.dart`](file:///Files/SIH2026.%204/mobile_app/lib/screens/voice_chat/speech_bridge_stub.dart) backed by standard platform audio channels.

---

## 🌐 10-Language Multilingual Engine

Controlled via `LanguageProvider`, the app supports dynamic in-place switching between 10 languages without reloading:
1. **हिन्दी (Hindi)**
2. **Hinglish** (Phonetic Romanized Hindi)
3. **मराठी (Marathi)**
4. **ਪੰਜਾਬੀ (Punjabi)**
5. **ગુજરાતી (Gujarati)**
6. **বাংলা (Bengali)**
7. **தமிழ் (Tamil)**
8. **తెలుగు (Telugu)**
9. **ಕನ್ನಡ (Kannada)**
10. **English**

---

## 🚀 Running the App

### Option 1: Using the Master Launcher (Recommended)
From the project root:
```bash
./run_app.sh          # Web (Google Chrome)
./run_app.sh --macos  # macOS Desktop
```

### Option 2: Running via Flutter CLI
```bash
cd mobile_app

# Fetch dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome --web-port 3000

# Run on macOS Desktop
flutter run -d macos
```

---

## 🧪 Testing & Code Quality

```bash
# Analyze code (verifies 0 lint errors)
flutter analyze

# Run unit and widget tests
flutter test
```

---

## 📦 Building for Production

```bash
# Build Web release bundle
flutter build web --release

# Build macOS app bundle
flutter build macos --release

# Build Android APK
flutter build apk --release
```
