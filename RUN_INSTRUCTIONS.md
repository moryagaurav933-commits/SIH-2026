# 🚀 Krishi-Saarthi (कृषि-सारथी) — Complete Run & Onboarding Guide

> **Welcome to Krishi-Saarthi!**  
> If you have just received or cloned this project, follow this step-by-step guide to run, test, and experience every feature of the application with zero hassle.

---

## ⚡ 1. The Fastest Way to Run (1-Minute Quick Start)

Open your terminal in the project root folder and execute:

```bash
./run_app.sh
```

### What this single command does automatically:
1. **Verifies Prerequisites**: Checks that Python 3 and Flutter SDK are installed.
2. **Prepares Backend**: Activates the Python virtual environment and verifies all AI dependencies (`fastapi`, `torch`, `torchvision`, `sqlalchemy`, `aiosqlite`).
3. **Initializes Database**: Automatically detects if PostgreSQL is running; if not, seamlessly initializes local SQLite (`krishi_saarthi.db`) and seeds all 21 crop diseases, ICAR treatments, symptoms, and prevention steps.
4. **Starts FastAPI Backend**: Launches the AI backend on `http://127.0.0.1:8000` with interactive Swagger docs at `/docs`.
5. **Opens Flutter Web App**: Automatically compiles and launches the app in Google Chrome on `http://localhost:3000`.

---

## 🎯 2. Available Run Modes

| Command | Target | Description |
|---|---|---|
| `./run_app.sh` *(default)* | **Google Chrome (Web)** | Starts backend and launches Flutter in Chrome with live **Hot Reload** (press `r`). |
| `./run_app.sh --macos` | **macOS Desktop** | Starts backend and opens the native macOS desktop app window. |
| `./run_app.sh --backend` | **FastAPI Server Only** | Starts only the backend API engine with live console logging. |
| `./run_app.sh --test` | **Automated Test Suite** | Runs backend PyTest (16/16) + Flutter Analyze + Flutter Tests (8/8) side-by-side. |
| `./run_app.sh --stop` | **Service Shutdown** | Cleanly terminates any running backend or Flutter background processes. |

---

## 🧭 3. Step-by-Step Feature Walkthrough (What to Test)

Once the app is running in Chrome (`http://localhost:3000`) or macOS Desktop, test each core feature:

### Feature 1: 🔬 AI Crop Disease Diagnosis
1. On the home screen, tap the big green card: **"रोग की पहचान करें (Scan Leaf / Diagnose)"** or navigate via bottom navigation.
2. Select a crop filter (e.g. **Tomato**, **Potato**, **Corn**, or **Apple**).
3. Tap **"कैमरा से फोटो लें"** (Camera) or **"गैलरी से चुनें"** (Gallery).
   - *In Web/Chrome*: A built-in high-resolution camera capture modal opens allowing instant capture or file upload.
4. Tap **"रोग की पहचान करें" (Diagnose)**.
5. **Verify the Results**:
   - The app communicates with the PyTorch MobileNetV3 model on `http://127.0.0.1:8000/api/v1/diagnose`.
   - The diagnosis card displays the detected disease name (in Hindi and English), confidence score, pathogen classification, and severity badge.
   - Switch between the tabs: **लक्षण (Symptoms)**, **उपचार (Treatments)**, **सावधानी (Prevention)**, and **स्रोत (ICAR Sources)** to see verified agronomic guidance.
6. **Test "Ask AI" Handoff**:
   - Tap the **"कृषि कॉपायलट से पूछें (Ask AI)"** button.
   - Notice how it immediately transitions into the Voice Copilot screen with the diagnosed disease context pre-loaded!

### Feature 2: 🎙️ AI Voice Copilot (Speech-to-Text & Text-to-Speech)
1. Tap the **Copilot (कॉपायलट)** icon in the bottom navigation bar.
2. Tap the central microphone button.
3. Speak your agricultural question in **Hindi, Hinglish, or English** (e.g., *"टमाटर में अगेती अंगमारी का क्या इलाज है?"* or *"Wheat irrigation schedule"*).
4. **Verify the Speech Bridge**:
   - On Chrome, the browser W3C `webkitSpeechRecognition` accurately transcribes your spoken words.
   - On macOS/iOS/Android, native platform speech-to-text handles transcription.
   - The Copilot answers back with both rich formatted text and audio speech synthesis!

### Feature 3: 🌦️ Hyperlocal Weather & Agro-Advisories
1. Tap the **Weather (मौसम)** tab.
2. See real-time temperature, humidity, wind speed, and precipitation chance.
3. Check the 5-day predictive forecast and ICAR spray condition recommendations (e.g., whether conditions are safe for spraying pesticides).
4. Use the search bar to look up another district (e.g., *Indore*, *Lucknow*, *Nagpur*).

### Feature 4: 📈 Live Mandi Market Prices
1. Tap the **Mandi (मंडी भाव)** tab.
2. View live APMC wholesale commodity rates for Wheat, Rice, Tomato, Potato, Onion, and Mustard.
3. Search by commodity or APMC market to see minimum, modal, and maximum prices per quintal.

### Feature 5: 🛡️ Tamper-Proof Insurance Claim Vault
1. Tap the **Insurance (फसल बीमा)** tab.
2. Tap **"नई क्षति रिपोर्ट दर्ज करें" (Log New Loss Claim)**.
3. The app automatically fetches your current high-precision GPS coordinates, logs the timestamp, and lets you attach photographic evidence of hail, flood, or pest damage.
4. Saved claims are stored locally in the secure offline claim vault with full details.

### Feature 6: 🌐 10 Indian Regional Languages
1. Tap the **Settings (सेटिंग्स)** tab.
2. Choose from **10 Indian languages**:
   - हिन्दी (Hindi), Hinglish, मराठी (Marathi), ਪੰਜਾਬੀ (Punjabi), ગુજરાતી (Gujarati), বাংলা (Bengali), தமிழ் (Tamil), తెలుగు (Telugu), ಕನ್ನಡ (Kannada), English.
3. Notice the entire interface re-renders instantly without needing an app restart!

---

## 🛠️ 4. Manual Setup (Without Using `run_app.sh`)

If you want to run backend and frontend independently in two terminal tabs:

### Terminal 1: Backend Setup & Launch
```bash
# 1. Open backend folder
cd backend

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install Python requirements
pip install -r requirements.txt

# 4. Initialize database and seed 21 crop diseases
python3 scripts/init_db.py

# 5. Start FastAPI server
python3 -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```
*API is accessible at `http://127.0.0.1:8000` with Swagger docs at `http://127.0.0.1:8000/docs`.*

### Terminal 2: Flutter App Launch
```bash
# 1. Open mobile app folder
cd mobile_app

# 2. Get dependencies
flutter pub get

# 3. Launch on Chrome (Web)
flutter run -d chrome --web-port 3000

# OR launch on macOS Desktop
flutter run -d macos
```

---

## 🧪 5. How to Validate & Test Everything Side-by-Side

To verify that the entire codebase is in 100% working condition before sharing with others:

```bash
./run_app.sh --test
```

### Expected Output Scorecard:
```
╔══════════════════════════════════════════════════════════════════════╗
║               🌾 Krishi-Saarthi | कृषि-सारथी Unified App             ║
╚══════════════════════════════════════════════════════════════════════╝

[1/4] Checking Prerequisites...
   ✓ Python:  Python 3.12 (or 3.10+)
   ✓ Flutter: Flutter 3.47.4 • channel stable

[2/4] Verifying Backend & Database...
   ✓ Backend environment and database verified

[3/4] Running Full Test Suite...

--- 1. Backend AI & API Pytest ---
collected 16 items
tests/test_api_endpoints.py::test_health_check PASSED
tests/test_api_endpoints.py::test_root_endpoint PASSED
tests/test_api_endpoints.py::test_docs_endpoint_theme PASSED
tests/test_api_endpoints.py::test_weather_forecast PASSED
tests/test_api_endpoints.py::test_mandi_prices PASSED
tests/test_api_endpoints.py::test_kriging_risk_surface PASSED
tests/test_api_endpoints.py::test_dashboard_stats PASSED
tests/test_api_endpoints.py::test_disease_heatmap PASSED
tests/test_api_endpoints.py::test_ai_key_status PASSED
tests/test_api_endpoints.py::test_ai_chat_offline_and_knowledge PASSED
tests/test_api_endpoints.py::test_mandi_endpoints PASSED
tests/test_crop_diagnose_pipeline.py::test_crop_ai_service_singleton PASSED
tests/test_crop_diagnose_pipeline.py::test_pytorch_inference_execution PASSED
tests/test_crop_diagnose_pipeline.py::test_postgresql_disease_profile_query PASSED
tests/test_crop_diagnose_pipeline.py::test_api_diagnose_multipart PASSED
tests/test_crop_diagnose_pipeline.py::test_api_v1_diagnose_alias PASSED
============================== 16 passed in 1.6s ==============================

--- 2. Flutter Code Analysis ---
Analyzing mobile_app...
No issues found! (ran in 1.4s)

--- 3. Flutter Unit & Widget Tests ---
All tests passed! (8/8 tests)

══════════════════════════════════════════════════════════════════════
   ✅ All Test Suites Completed Successfully!
══════════════════════════════════════════════════════════════════════
```

---

## 🔧 6. Troubleshooting FAQ

### Problem: "Port 8000 is already in use"
**Solution:**
```bash
./run_app.sh --stop
```
This kills any lingering uvicorn or python server instances on port 8000.

### Problem: "Flutter command not found"
**Solution:**
On macOS, Flutter is typically installed via Homebrew at `/opt/homebrew/bin/flutter`. [`run_app.sh`](file:///Files/SIH2026.%204/run_app.sh) automatically adds `/opt/homebrew/bin` to your PATH. If running manually, export it:
```bash
export PATH="/opt/homebrew/bin:$PATH"
```

### Problem: "Do I need Docker installed?"
**No.** Docker is completely optional. The backend includes a self-healing TCP connection checker: if Docker PostgreSQL on port 5433 is down, it silently falls back to local SQLite (`backend/krishi_saarthi.db`) with zero configuration.

### Problem: "Camera or Mic permission blocked on macOS"
**Solution:**
We have configured full sandbox entitlements in [`DebugProfile.entitlements`](file:///Files/SIH2026.%204/mobile_app/macos/Runner/DebugProfile.entitlements) and [`Release.entitlements`](file:///Files/SIH2026.%204/mobile_app/macos/Runner/Release.entitlements). When macOS displays a permission pop-up asking for Camera, Microphone, or Location access, simply click **"Allow"**. If accidentally denied, open **System Settings > Privacy & Security > Camera / Microphone** and toggle on `krishi_saarthi`.

---

## 📞 Need Help?
- **Backend API Documentation**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **Backend Health Check**: [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)
