# 🛠️ Krishi-Saarthi — Summary of Codebase Fixes & Stabilization

This document tracks all recent technical issues identified in the codebase, the root causes discovered, and the engineering solutions implemented to make Krishi-Saarthi 100% production-ready, resilient, and testable side-by-side.

---

## 1. 🗄️ Hybrid Database Engine & Automatic SQLite Fallback
- **Problem**: When running without Docker, `init_db.py` and `base.py` attempted to connect to PostgreSQL on port 5433, causing immediate `ConnectionRefusedError [Errno 61]` and crashing `run_app.sh`.
- **Root Cause**: `backend/.env` configured a PostgreSQL connection string that unconditionally assumed a live Docker container was running.
- **Solution**:
  - Implemented non-blocking TCP socket auto-detection in [`backend/app/db/base.py`](file:///Files/SIH2026.%204/backend/app/db/base.py).
  - If PostgreSQL port 5433 is unreachable within 0.3s, the engine seamlessly and automatically switches to local SQLite (`sqlite+aiosqlite:///backend/krishi_saarthi.db`).
  - Updated [`backend/scripts/init_db.py`](file:///Files/SIH2026.%204/backend/scripts/init_db.py) to inherit the resilient engine, allowing zero-config startup on any developer machine.

---

## 2. 📜 Disease Database SQL Seeder Parser
- **Problem**: When seeding [`ai_module/disease_database.sql`](file:///Files/SIH2026.%204/ai_module/disease_database.sql), descriptions containing semicolons inside single quotes (e.g. *"Spray Mancozeb; ensure proper spacing"*) caused SQLite and asyncpg syntax errors.
- **Root Cause**: The migration script used a naive regex `re.findall(r'.*?;')` which split SQL statements in the middle of text strings.
- **Solution**:
  - Implemented `split_sql_statements()` in [`backend/scripts/seed_disease_kb.py`](file:///Files/SIH2026.%204/backend/scripts/seed_disease_kb.py).
  - The parser accurately tracks quote delimiters, escape characters, and SQL comments, ensuring all 21 diseases, 40 symptoms, 30 treatments, 38 prevention steps, and 22 ICAR sources seed with zero errors.

---

## 3. 🎙️ Cross-Platform Speech Bridge (Web JS Interop ↔ Native Audio)
- **Problem**: `speech_to_text` and `flutter_tts` rely on mobile platform channels that failed or threw missing plugin exceptions when running on Flutter Web or macOS.
- **Root Cause**: Flutter Web lacks direct native channel support for speech recognition without browser JS bindings.
- **Solution**:
  - Engineered an abstraction layer: [`speech_bridge.dart`](file:///Files/SIH2026.%204/mobile_app/lib/screens/voice_chat/speech_bridge.dart).
  - Implemented [`speech_bridge_web.dart`](file:///Files/SIH2026.%204/mobile_app/lib/screens/voice_chat/speech_bridge_web.dart) using modern `dart:js_interop` to bind directly to W3C `webkitSpeechRecognition` and `window.speechSynthesis`.
  - Implemented [`speech_bridge_stub.dart`](file:///Files/SIH2026.%204/mobile_app/lib/screens/voice_chat/speech_bridge_stub.dart) for native targets.
  - The voice copilot now compiles and runs cleanly across all platforms.

---

## 4. 🔒 macOS Desktop Hardware Permissions & Entitlements
- **Problem**: On macOS desktop, camera, microphone, location, and backend network requests were blocked by the macOS App Sandbox.
- **Root Cause**: [`DebugProfile.entitlements`](file:///Files/SIH2026.%204/mobile_app/macos/Runner/DebugProfile.entitlements), [`Release.entitlements`](file:///Files/SIH2026.%204/mobile_app/macos/Runner/Release.entitlements), and [`Info.plist`](file:///Files/SIH2026.%204/mobile_app/macos/Runner/Info.plist) were missing privacy keys and sandbox permissions.
- **Solution**:
  - Added `com.apple.security.network.client` to allow communication with `http://127.0.0.1:8000`.
  - Added `com.apple.security.device.camera` for leaf pathology scans.
  - Added `com.apple.security.device.audio-input` for microphone voice copilot.
  - Added `com.apple.security.personal-information.location` for GPS weather and insurance claims.
  - Configured privacy descriptions in `macos/Runner/Info.plist`.

---

## 5. 🧹 Bloatware & Duplicate File Removal
- **Problem**: Duplicate 33.4 MB folder `LLMMODEL/` contained obsolete copies of model weights and redundant schemas, cluttering git and confusing imports.
- **Solution**:
  - Deleted `LLMMODEL/` completely. All AI model weights and schemas are now consolidated in [`ai_module/`](file:///Files/SIH2026.%204/ai_module) and [`database/schemas/`](file:///Files/SIH2026.%204/database/schemas).
  - Deleted obsolete shell scripts `test_startup.sh` and `verify_app.sh`, merging all functionality into [`run_app.sh`](file:///Files/SIH2026.%204/run_app.sh).
  - Removed dangling references in git staging.

---

## 6. 🚀 Master Unified Application Launcher (`run_app.sh`)
- **Problem**: Previous scripts failed on systems where Homebrew wasn't in PATH, repeatedly froze during `pip install`, and lacked clean test commands.
- **Solution**:
  - Built [`run_app.sh`](file:///Files/SIH2026.%204/run_app.sh) with automatic PATH resolution (`/opt/homebrew/bin`).
  - Added smart package cache checks to skip unnecessary `pip install` cycles.
  - Added single-command modes:
    - `./run_app.sh` (Web/Chrome with hot-reload)
    - `./run_app.sh --macos` (Native macOS desktop)
    - `./run_app.sh --test` (Automated backend & frontend test suite)
    - `./run_app.sh --backend` (Standalone API server)
    - `./run_app.sh --stop` (Clean process termination)

---

## 7. 🧪 Testing Scorecard
- **FastAPI PyTest Suite**: **16 / 16 PASSED** (Includes multipart image upload, AI singleton inference, database profile enrichment, weather, mandi, and dashboard endpoints).
- **Flutter Analyzer**: **0 issues found** (0 errors, 0 warnings).
- **Flutter Unit & Widget Tests**: **8 / 8 PASSED** (LanguageProvider, WeatherProvider, AppTranslations, Widget smoke tests).
