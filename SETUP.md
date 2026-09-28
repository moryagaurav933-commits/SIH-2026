# Krishi-Saarthi — Fresh Clone Setup

Verified end-to-end on a clean machine. Follow this to get the project running
from a brand new clone.

Repo: `https://github.com/moryagaurav933-commits/SIH-2026.git`

---

## 1. Prerequisites (install once per laptop)

| Tool | Version | Notes |
|------|---------|-------|
| Python | 3.11 (3.10–3.13 OK) | **Tick "Add python.exe to PATH"** during install |
| Git | any | <https://git-scm.com/download/win> |
| Flutter | 3.24+ | **Only needed for the mobile app.** The backend + ML work without it |

> If you skip the PATH checkbox, the setup script will still find your Python
> automatically — but it's cleaner to tick it.

---

## 2. Clone

```powershell
git clone https://github.com/moryagaurav933-commits/SIH-2026.git
cd SIH-2026
```

---

## 3. Run it

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\run_app.ps1
```

On the **first run only** this creates the virtualenv, installs ~100 packages
(torch/geopandas are large — allow 5–10 minutes), seeds the database, and starts
the backend. Every later run takes a few seconds.

| | URL |
|---|---|
| Backend + API docs | <http://127.0.0.1:8000/docs> |
| App | <http://127.0.0.1:8080> |

### macOS / Linux

```bash
chmod +x run_app.sh
./run_app.sh
```

### Manual / Linux alternative

```bash
python3 -m venv .venv311
source .venv311/bin/activate          # Windows: .venv311\Scripts\activate
pip install --upgrade pip
pip install -r backend/requirements.txt
cp backend/.env.example backend/.env
python backend/scripts/init_db.py
cd backend && uvicorn app.main:app --port 8000
```

---

## 4. Verify the ML model works

```powershell
.\.venv311\Scripts\python.exe ai_module\smoke_test.py
```

Expected: `ALL CHECKS PASSED` (loads the checkpoint, validates 21 classes,
runs inference, checks the probability distribution).

Quick single-image test:

```powershell
.\.venv311\Scripts\python.exe ai_module\predict.py path\to\leaf.jpg tomato
```

---

## 5. What's installed / not installed

**No external services required.** PostgreSQL, Redis and MinIO are optional.
The app auto-falls back to a local SQLite database, so `init_db.py` and the
backend work on a fresh laptop with nothing else running. The `/health` endpoint
reports `"status": "healthy"` with mode `"sqlite_local"` and notes Redis/MinIO as
optional offline services. The database shows `"status": "connected"`.

To enable containerized PostgreSQL, Redis, and MinIO later, use `infrastructure/docker/docker-compose.dev.yml`.

---

## Troubleshooting

**`[setup] FAILED - no Python 3.10+ found`**
Python isn't installed, or the PATH checkbox was skipped. Install Python 3.11
from <https://www.python.org/downloads/> and tick *Add python.exe to PATH*.

**`CMake configuration failed` during install**
You have an old copy of `requirements.txt`. `llama-cpp-python` is now commented
out by default because it needs a C++ compiler and its `tinyllama.gguf` weights
are not in the repo. Pull the latest changes. Only uncomment it if you have
Visual Studio Build Tools / Xcode and actually want offline chat.

**`Address already in use` / port 8000 busy**
```powershell
Get-NetTCPConnection -LocalPort 8000,8080 -State Listen |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

**Backend says model failed to load / always returns "Tomato Early Blight"**
`ai_module/best_model_final.pth` is missing (17 MB). Confirm it exists:
```powershell
Test-Path ai_module\best_model_final.pth
```

**Flutter not found**
Only needed for the mobile app. Install from <https://docs.flutter.dev/get-started/install>.
To use the backend alone, just run `run_app.ps1 -Backend`.

**`flutter` command found but "Unable to find git in your PATH"** — install Git
and reopen the terminal.

---

## API examples

The crop disease endpoint takes a **multipart form**, and `crop_hint` is a
**form field** (not a query parameter):

```powershell
curl.exe -X POST "http://127.0.0.1:8000/api/diagnose" `
  -F "file=@leaf.jpg" -F "crop_hint=tomato"
```

Valid `crop_hint` values: `tomato`, `potato`, `maize` (or `corn`), `apple`.
Omit it to let the model identify the crop itself.

The response includes `is_low_confidence` (model wasn't sure) and
`is_crop_mismatch` (the photo doesn't look like the crop that was selected).
When either is `true`, the app shows a warning instead of a diagnosis — this is
deliberate, so a farmer isn't told to spray the wrong pesticide.
