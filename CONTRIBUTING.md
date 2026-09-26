# 🌾 Contributing to Krishi-Saarthi

Welcome to the **Krishi-Saarthi** development team! This guide will help you set up your local development environment safely, collaborate with other developers, and uphold security, code quality, and privacy standards across the codebase.

---

## 📋 Table of Contents
1. [Project Overview](#-project-overview)
2. [Prerequisites](#-prerequisites)
3. [Quick Start Setup](#-quick-start-setup)
   - [Environment Configuration](#1-environment-configuration)
   - [Unified Launcher](#2-unified-launcher-run_appsh)
   - [Manual Backend & Flutter Setup](#3-manual-backend--flutter-setup)
4. [Testing & Quality Verification](#-testing--quality-verification)
5. [Security & Secrets Policy](#-security--secrets-policy)
6. [Git Workflow & Best Practices](#-git-workflow--best-practices)

---

## 🚜 Project Overview

The repository is organized into modular layers:
- `ai_module/`: PyTorch MobileNetV3 model weights, inference pipeline (`predict.py`), class mappings, and SQL knowledge base.
- `backend/`: FastAPI REST server, hybrid SQLite/PostgreSQL database engine, PyTorch inference service, and ICAR agronomy heuristics.
- `mobile_app/`: Flutter cross-platform mobile/desktop/web client with trilingual Voice Copilot, leaf disease scanner, live mandi rates, and PMFBY insurance vault.
- `database/`: Production relational database schemas.

---

## 🛠️ Prerequisites

Ensure you have the following installed on your machine:
- **Python 3.10+** (Python 3.10, 3.11, or 3.12)
- **Flutter 3.24+** (Stable channel)
- **Google Chrome** (for Web testing) or **Xcode 15+** (for macOS/iOS)
- **Git**

---

## 🚀 Quick Start Setup

### 1. Environment Configuration
Copy the environment template if needed:
```bash
cp backend/.env.example backend/.env
```
*(Note: Krishi-Saarthi runs out-of-the-box with local SQLite and offline heuristics even if no external API keys are configured).*

### 2. Unified Launcher (`run_app.sh`)
Run backend + Flutter Web simultaneously in one command:
```bash
./run_app.sh
```

### 3. Manual Backend & Flutter Setup

**Backend:**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 scripts/init_db.py
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

**Flutter App:**
```bash
cd mobile_app
flutter pub get
flutter run -d chrome --web-port 3000
# or: flutter run -d macos
```

---

## 🧪 Testing & Quality Verification

Before submitting any code changes, always run the automated test suite:

```bash
./run_app.sh --test
```

This verifies:
1. **PyTest Suite** (16/16 backend tests pass).
2. **Flutter Code Analysis** (`flutter analyze` reports 0 issues).
3. **Flutter Widget & Provider Tests** (8/8 tests pass).

---

## 🔐 Security & Secrets Policy

1. **Zero Hardcoded Secrets**: Never commit real API keys, passwords, bearer tokens, or private keys to any file tracked by Git.
2. **Local Machine Files**: Do not commit IDE folders (`.idea/`, `.vscode/`), system files (`.DS_Store`), or local SDK paths (`local.properties`).
3. **Multi-Platform Permissions**: When adding new native features, declare proper usage descriptions in both `Info.plist` and `AndroidManifest.xml`.

---

## 🌿 Git Workflow & Best Practices

1. **Create a descriptive branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. **Test your changes**:
   ```bash
   ./run_app.sh --test
   ```
3. **Commit with clean, descriptive messages**:
   ```bash
   git add .
   git commit -m "feat: add feature description"
   ```
