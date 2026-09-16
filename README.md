# Krishi-Saarthi (कृषि-सारथी) — Field OS for Indian Farmers

> **Offline-First Agricultural Intelligence Mobile Application with FastAPI Backend & Database**

Krishi-Saarthi is an agricultural operating system engineered for Indian farmers. It features an edge-first Flutter mobile application seamlessly connected to a local FastAPI backend and SQLite/PostgreSQL database.

---

## 🚀 Quick Start (Single Command)

Run the entire system (Backend, Database, and Flutter App) with one command:

```bash
# 1. Launch FastAPI Backend (port 8000) + Flutter Web App (port 3000)
./run_app.sh

# 2. Or launch with native macOS Desktop App
./run_app.sh --mac

# 3. Or launch with Flutter Chrome Dev Server (hot reload)
./run_app.sh --dev
```

When started:
- **Flutter Mobile App**: [http://localhost:3000](http://localhost:3000)
- **FastAPI Backend & DB**: [http://localhost:8000/api/v1](http://localhost:8000/api/v1)
- **Interactive Swagger Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)

To stop all services:
```bash
./stop_all.sh
```

---

## 📂 Architecture & Directory Layout

```
SIH2026./
├── mobile_app/           # Flutter Mobile / Web / Desktop application
│   ├── lib/              # Core Dart logic, screens, widgets, design tokens
│   ├── assets/           # Local app assets, portraits, icons
│   └── test/             # Smoke, unit, and widget test suites
├── backend/              # FastAPI backend engine
│   ├── app/              # API endpoints, models, database session
│   ├── krishi_saarthi.db # Local SQLite/SQLCipher database
│   └── venv/             # Python virtual environment
├── infrastructure/       # Containerized services (Docker Compose for Postgres, Redis, MinIO)
├── ml_models/            # Computer vision and soil health training scripts
├── run_app.sh            # Primary launcher for Backend + Flutter App
├── run_all.sh            # Unified alias delegating to run_app.sh
├── stop_all.sh           # Clean service shutdown script
└── README.md             # Project documentation
```

---

## 🌾 Core Capabilities

1. **AI Crop Disease Diagnosis**: Real-time leaf pathology diagnosis with pathogen identification, immediate action advice, spot dosage rates (ml/L), chemical treatments (CIBRC-approved), and organic remedies.
2. **24x7 ICAR AI Agronomist**: Agricultural RAG knowledge engine covering ICAR Package of Practices for major Indian crops (Wheat, Rice, Cotton, Potato, Mustard, Pulses) and government schemes (PM-Kisan, PMFBY, KCC).
3. **Live Mandi Commodity Prices**: Agricultural commodity prices across top APMC mandis (Lucknow, Kanpur, Varanasi, Indore, Agra, etc.) with price trends.
4. **Hyperlocal Weather & Agro-Advisory**: 5-day predictive forecasts, rainfall probabilities, and district-level ICAR farming advisories.
5. **2G Telecom USSD (*123#) & SMS Gateway Simulator**: Interactive USSD session state machine and toll-free 56161 SMS gateway for low-connectivity regions.
6. **Smart Fertilizer & NPK Dosage Calculator**: Soil health card to fertilizer dosage calculator determining Urea, DAP, and MOP requirements per acre.
7. **Counterfeit Seed & Pesticide Verifier**: QR code, barcode, and batch verification with authenticity scoring.
8. **Encrypted Database & Merkle Tree Delta Sync**: Local encrypted database storage with Merkle tree differential replication for offline mesh sync.

---

## 🧪 Testing & Validation

```bash
# Validate Flutter Mobile App
cd mobile_app
flutter analyze --no-fatal-infos    # 0 issues found
flutter test                       # All tests passed

# Validate FastAPI Backend
cd ../backend
./venv/bin/pytest tests/           # Run backend tests
```
# zip-
