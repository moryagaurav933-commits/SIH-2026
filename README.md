# 🌾 Krishi-Saarthi (कृषि-सारथी) — Field OS for Indian Farmers

> **An Edge-First, Offline-Capable AI Agricultural Operating System**  
> Engineered for smallholder and marginal farmers across rural India. Featuring on-device Computer Vision diagnosis, trilingual Voice Copilot with Speech Bridge, live Agmarknet mandi market rates, hyperlocal meteorological forecasts, and tamper-proof geo-tagged insurance evidence collection.

---

## 📑 Table of Contents
- [About Krishi-Saarthi](#-about-krishi-saarthi)
- [Key Features & Implemented Capabilities](#-key-features--implemented-capabilities)
- [System Architecture](#-system-architecture)
- [Prerequisites & Dependencies](#-prerequisites--dependencies)
- [🚀 Quick Start (Single Command)](#-quick-start-single-command)
- [Manual Step-by-Step Setup](#-manual-step-by-step-setup)
- [🧪 Testing & Verification](#-testing--verification)
- [Hardware Permissions & Entitlements](#-hardware-permissions--entitlements)
- [📂 Clean Project Structure](#-clean-project-structure)
- [API & Service Endpoints](#-api--service-endpoints)
- [Troubleshooting FAQ](#-troubleshooting-faq)

---

## 🌾 About Krishi-Saarthi

Agriculture employs over 45% of India's workforce, yet farmers face recurrent losses from delayed crop disease diagnosis, volatile market pricing, extreme weather volatility, and complex insurance claim procedures.

**Krishi-Saarthi (कृषि-सारथी)** bridges this gap by providing an intuitive, multi-modal mobile and desktop platform that runs smoothly even with intermittent 2G/3G connectivity or completely offline:
- **Zero-Config Database**: Automatic auto-fallback between local SQLite (`krishi_saarthi.db`) and production containerized PostgreSQL (port 5433).
- **Fast Multimodal AI**: PyTorch MobileNetV3 deep learning classifier for 21 crop diseases enriched with ICAR-verified agronomic treatments.
- **Cross-Platform Voice Copilot**: Native microphone input on macOS/iOS/Android and modern W3C `SpeechRecognition` via `dart:js_interop` on Web browsers.
- **Multilingual Support**: Fully localized across **10 Indian languages** (Hindi, Hinglish, Marathi, Punjabi, Gujarati, Bengali, Tamil, Telugu, Kannada, and English).

---

## 🌟 Key Features & Implemented Capabilities

### 1. 🔬 AI Crop Disease Diagnosis & Treatment
- Snap or upload a leaf photo from camera or gallery.
- Powered by a fine-tuned **MobileNetV3** PyTorch model (`best_model_final.pth`) classifying across 21 conditions (Tomato, Potato, Corn, Apple, etc.).
- Returns disease confidence, pathogen identification, symptoms, cultural/biological cures, CIBRC-approved chemical remedies, and ICAR source citations.
- **One-Tap "Ask AI" Copilot Handoff**: Passes diagnosis context directly into the Voice Copilot for conversational follow-up questions.

### 2. 🎙️ AI Voice Copilot with Cross-Platform Speech Bridge
- Natural voice conversations with an agronomic AI assistant.
- Trilingual voice input and text-to-speech feedback (Hindi, Hinglish, English).
- Powered by a unified Speech Bridge: utilizes Web Speech API on Chrome/Edge browsers and native platform speech on Android/macOS/iOS.
- Offline fallback to rule-based ICAR agronomy heuristics if LLM APIs or internet connections are unavailable.

### 3. 📈 Live Mandi Commodity Market Rates
- Integrates government Agmarknet APMC mandi prices for major wholesale markets (Lucknow, Kanpur, Indore, Agra, Varanasi, etc.).
- Displays real-time modal, minimum, and maximum prices per quintal, daily price trends, and distance to nearest mandis.

### 4. 🌦️ Hyperlocal Weather & Agro-Advisories
- High-precision GPS meteorological forecasts powered by Open-Meteo.
- 5-day predictive forecasts, relative humidity, wind speed, precipitation probability, and agricultural spray advisories.

### 5. 🛡️ Geo-Tagged Crop Loss Insurance Vault
- Streamlines Pradhan Mantri Fasal Bima Yojana (PMFBY) insurance claim logging.
- Captures tamper-proof evidence records with high-precision GPS coordinates, timestamps, loss percentage estimates, and photo attachments.
- Encrypted local vault with status tracking and PDF/CSV export readiness.

### 6. 📊 Farmer Farm Overview & Analytics
- Comprehensive farm management dashboard displaying active plots, soil moisture levels, NDVI vegetation health indicators, and pending spray tasks.

---

## 🏛️ System Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        Flutter Client (Mobile / Web / macOS)           │
│  - Trilingual UI (10 Languages via LanguageProvider)                  │
│  - Cross-Platform Speech Bridge (Web JS Interop ↔ Native Audio)        │
│  - Offline Local Storage (LocalDB SQLite / SharedPreferences)          │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │ REST / Multipart HTTP
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        FastAPI AI Backend Engine (Port 8000)           │
│  - crop_ai_service.py (Singleton PyTorch MobileNetV3 Classifier)       │
│  - ai_service.py (Gemini 2.5 Flash + ICAR Knowledge Base Fallback)     │
│  - weather_mandi_service (Open-Meteo & Agmarknet APMC aggregation)     │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │ Async SQLAlchemy
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    Hybrid Database Layer (Auto-Fallback)               │
│  - Default / Offline: sqlite+aiosqlite:///backend/krishi_saarthi.db    │
│  - Production / Docker: postgresql+asyncpg://...:5433/krishi_saarthi   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites & Dependencies

To run Krishi-Saarthi on your machine, ensure the following are installed:

1. **Python 3.10+**:
   ```bash
   python3 --version  # Should be Python 3.10, 3.11, or 3.12
   ```
2. **Flutter SDK (3.24+)**:
   ```bash
   flutter --version  # Should be Flutter stable
   ```
3. **Google Chrome** (for Web testing) or **Xcode 15+** (for native macOS / iOS execution).
4. **Git**:
   ```bash
   git --version
   ```

*(Optional)* **Docker & Docker Compose** (only if you wish to run the containerized PostgreSQL, Redis, and MinIO stack).

---

## 🚀 Quick Start (Single Command)

We provide a master application runner [`run_app.sh`](file:///Files/SIH2026.%204/run_app.sh) that automatically verifies your environment, initializes the database, starts the FastAPI backend, and launches the app:

### 1. Launch in Google Chrome (Web with Hot-Reload)
```bash
./run_app.sh
# or explicitly: ./run_app.sh --web
```
- Starts FastAPI backend at `http://127.0.0.1:8000`.
- Starts Flutter Web application at `http://localhost:3000`.
- Press **`r`** in the terminal for instant Hot Reload.

### 2. Launch Natively on macOS Desktop
```bash
./run_app.sh --macos
```
- Starts backend and opens the native macOS desktop window.

### 3. Run Full Test Suite (Side-by-Side Verification)
```bash
./run_app.sh --test
```
- Executes 16/16 PyTest backend tests.
- Executes `flutter analyze` (verifies 0 lint issues).
- Executes 8/8 Flutter unit and widget tests.

### 4. Run Standalone Backend API (Swagger UI)
```bash
./run_app.sh --backend
```
- Launches the backend server with live console logs at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).

### 5. Stop All Running Services
```bash
./run_app.sh --stop
# or: ./stop_all.sh
```

---

## 🛠️ Manual Step-by-Step Setup

If you prefer to start each component manually in separate terminal windows:

### Terminal 1: FastAPI Backend
```bash
# 1. Navigate to backend directory
cd backend

# 2. Create Python virtual environment and activate
python3 -m venv venv
source venv/bin/activate

# 3. Install Python dependencies
pip install -r requirements.txt

# 4. Initialize database and seed Disease Knowledge Base
python3 scripts/init_db.py

# 5. Start the FastAPI server
python3 -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```
*Backend is now live at `http://127.0.0.1:8000` with interactive docs at `/docs`.*

### Terminal 2: Flutter Frontend
```bash
# 1. Navigate to mobile_app directory
cd mobile_app

# 2. Fetch Flutter packages
flutter pub get

# 3. Run on Chrome
flutter run -d chrome --web-port 3000

# OR run on macOS Desktop
flutter run -d macos
```

---

## 🧪 Testing & Verification

Every layer of Krishi-Saarthi is covered by automated unit and integration tests:

```bash
# Run all tests simultaneously:
./run_app.sh --test
```

### Individual Test Commands:
```bash
# 1. Backend PyTest (AI Inference + Endpoints + Fallback DB)
cd backend
venv/bin/pytest tests/ -v

# 2. Flutter Static Code Analysis
cd mobile_app
flutter analyze

# 3. Flutter Unit & Widget Smoke Tests
cd mobile_app
flutter test
```

**Current Verification Status:**
- **Backend Tests:** 16 / 16 PASSED (100%)
- **Flutter Analyzer:** 0 issues found (0 errors, 0 warnings)
- **Flutter Tests:** 8 / 8 PASSED (100%)

---

## 🔒 Hardware Permissions & Entitlements

The application includes production-grade platform permission manifests across all deployment targets:

| Hardware Resource | Android (`AndroidManifest.xml`) | iOS (`Info.plist`) | macOS (`Debug & Release.entitlements`) | Web |
|---|---|---|---|---|
| **Camera** (Disease & Insurance) | `android.permission.CAMERA` | `NSCameraUsageDescription` | `com.apple.security.device.camera` | Browser `getUserMedia` |
| **Microphone** (Voice Copilot) | `android.permission.RECORD_AUDIO` | `NSMicrophoneUsageDescription` | `com.apple.security.device.audio-input` | Web Speech API |
| **Geolocation** (Weather & Mandi) | `ACCESS_FINE_LOCATION` | `NSLocationWhenInUseUsageDescription` | `personal-information.location` | Browser Geolocation API |
| **Network Client** | `INTERNET` | `NSAllowsArbitraryLoads` | `com.apple.security.network.client` | CORS Fetch |

*Self-Healing Behavior: If a user denies location or camera permission, the app automatically switches to safe fallbacks (e.g. city search for weather) without crashing.*

---

## 📂 Clean Project Structure

```text
SIH2026./
├── ai_module/                       # AI weights, mappings & DB seed
│   ├── best_model_final.pth         # PyTorch MobileNetV3 21-class weights (16MB)
│   ├── class_names.json             # 21 ML class label definitions
│   ├── disease_kb.json              # Agricultural knowledge base
│   ├── convert_checkpoint.py        # Rebuilds a single .pth from a split checkpoint
│   ├── requirements.txt             # Standalone deps for predict.py
│   └── predict.py                   # PyTorch leaf pathology inference module
│
├── backend/                         # FastAPI AI Backend
│   ├── app/
│   │   ├── api/v1/endpoints/        # Diagnoses, Mandi, Weather, Farmers, AI Chat
│   │   ├── db/base.py               # Auto-fallback engine (PostgreSQL ↔ SQLite)
│   │   ├── services/crop_ai_service.py # PyTorch singleton inference & DB enricher
│   │   ├── services/ai_service.py   # Multi-modal LLM & ICAR offline heuristics
│   │   └── main.py                  # API server, Swagger theme & health check
│   ├── scripts/init_db.py           # Table initialization and KB seeder
│   └── tests/                       # 16 passing pytest integration tests
│
├── mobile_app/                      # Flutter Client App
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── diagnosis/           # Camera leaf scan & pathology results
│   │   │   ├── voice_chat/          # Voice Copilot (Speech Bridge & Ask AI)
│   │   │   ├── mandi/               # Agmarknet live wholesale commodity rates
│   │   │   ├── weather/             # Hyperlocal weather & agro-advisory
│   │   │   ├── insurance/           # PMFBY crop loss claim evidence vault
│   │   │   ├── dashboard/           # Farm metrics, vegetation health & tasks
│   │   │   └── home_screen.dart     # Main trilingual navigation hub
│   │   ├── services/                # API config, CV service, LLM copilot service
│   │   └── providers/               # Language and weather state providers
│   └── test/                        # Flutter widget and provider tests
│
├── database/                         # Relational SQL schemas
│   └── disease_database.sql          # 4 crops, 21 diseases, ICAR treatments SQL
│
├── run_app.sh                       # Unified master launcher & test script
├── stop_all.sh                      # Clean process termination script
├── RUN_INSTRUCTIONS.md              # Teammate onboarding & runbook
├── CONTRIBUTING.md                  # Development guidelines & PR standards
├── SECURITY.md                      # Security architecture & API protection
└── README.md                        # Primary project documentation
```

---

## 🌐 API & Service Endpoints

When running locally (`http://127.0.0.1:8000`):

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | API status and root greeting |
| `GET` | `/health` | Live database, engine, and service health check |
| `GET` | `/docs` | Interactive Swagger UI documentation |
| `POST` | `/api/v1/diagnose` | Leaf image upload -> PyTorch inference -> DB profile |
| `POST` | `/api/diagnose` | Direct alias for disease diagnosis |
| `POST` | `/api/v1/ai/chat` | AI Agronomist Copilot conversation endpoint |
| `GET` | `/api/v1/mandi/prices` | Live APMC mandi commodity prices |
| `GET` | `/api/v1/weather/forecast`| Hyperlocal agro-meteorological forecast |
| `GET` | `/api/v1/dashboard/stats` | Farmer farm overview and analytics metrics |

---

## ❓ Troubleshooting FAQ

### Q1: The backend says `Port 8000 is already in use`
**Fix:** Run `./stop_all.sh` or kill the process:
```bash
./stop_all.sh
# Or manual: lsof -ti:8000 | xargs kill -9
```

### Q2: I don't have Docker installed. Will the database work?
**Yes!** The backend includes an **intelligent TCP auto-detection engine** in [`backend/app/db/base.py`](file:///Files/SIH2026.%204/backend/app/db/base.py). If PostgreSQL (port 5433) is not running, it automatically and silently falls back to local SQLite (`krishi_saarthi.db`). Zero Docker or database configuration is required.

### Q3: How do I test the app without an internet connection?
The entire crop disease diagnosis pipeline (PyTorch weights + SQLite database) and the Voice Copilot (ICAR heuristic engine) are built offline-first and function with 100% fidelity without an active internet connection.

---

## 📄 License & Credits
Developed for Smart India Hackathon (SIH 2026).  
*Dedicated to the hardworking farmers of India. Jai Jawan, Jai Kisan! 🇮🇳*
# SIH-2026
