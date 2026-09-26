# Development & Collaboration Setup

This is the exact contract for running Krishi-Saarthi so that **every contributor gets
byte-identical dependency versions**. Follow it precisely — deviations are the main cause
of "works on my machine" failures.

---

## 1. Prerequisites (must match exactly)

| Tool | Required version | How to check |
|---|---|---|
| **Flutter** | `>=3.44.0` (verified on 3.47.5) | `flutter --version` |
| **Dart** | `>=3.12.0 <4.0.0` (verified on 3.13.4) | `dart --version` |
| **Git** | Any recent version | `git --version` |
| **Python** | 3.11 (recommended; 3.13 also works) | `python --version` |

> **Git is mandatory.** The Flutter toolchain refuses to start without it, and it is
> required for the push/pull workflow. Install from <https://git-scm.com/download/win>
> and make sure `git` is on your `PATH`.

`mobile_app/pubspec.yaml` declares these bounds explicitly, so an older SDK will fail
loudly at `pub get` rather than silently misbehaving.

---

## 2. First-time setup

```bash
git clone <repo-url>
cd SIH-2026

# --- Backend (from the repo ROOT, not from backend/) ---
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -r backend/requirements.txt
```

> **Note on the two virtualenvs.** This repo has `.venv` (Python 3.13) and
> `.venv311` (Python 3.11). **`.venv311` is the working one** — it is the only
> environment with the backend dependencies installed. `.venv` is a bare
> Python 3.13 environment that predates the requirements install. Both are
> gitignored. If `import fastapi` fails, you are in the wrong one.
>
> If you are starting completely fresh, use a single environment:
> ```powershell
> python -m venv .venv
> .venv\Scripts\activate
> pip install -r backend/requirements.txt
> ```

### Environment file

`.env` is **gitignored by design** — never commit it. Create it locally:

```bash
cp .env.example .env            # Linux/macOS
copy .env.example .env          # Windows cmd
```

Defaults are zero-configuration (SQLite, no API keys required), so the project runs
immediately after copying.

### Seed the database

The demo dataset is **not** committed (binary DB files are gitignored). Seed it once
after cloning:

```bash
cd backend
python scripts/init_db.py
```

If you prefer to run everything with an explicit interpreter instead of activating a
venv (recommended, avoids the `.venv` / `.venv311` confusion above):

```powershell
cd backend
..\.venv311\Scripts\python.exe scripts\init_db.py
```

To confirm the seed worked, `backend/scripts/_check_db.py` prints row counts per table:

```powershell
cd backend
..\.venv311\Scripts\python.exe scripts\_check_db.py
```

Expect `farmers 3`, `farm_plots 2`, `mandi_prices 12`, `disease_telemetry 10`,
`weather_cache 2`, `fertilizer_registry 3`, `insurance_claims 1`, `diseases 21`.
`mesh_packets 0` is normal. If a count is `0` when it should not be, re-run
`init_db.py` — it repairs partial seeds automatically.

This creates all tables and loads 3 farmers, 2 plots, 3 diagnoses, 12 mandi prices,
2 weather caches, 3 fertilizer records, 10 telemetry points, and 1 insurance claim,
plus the 21-class disease knowledge base.

The script is **idempotent** — running it twice is a safe no-op. If a previous run was
interrupted, it detects the incomplete data and re-seeds cleanly.

---

## 3. Verifying your setup

Run both suites before you start work. Both must be green.

```bash
# Backend  (note: from repo root or backend/, but use the explicit interpreter)
cd backend
..\.venv311\Scripts\python.exe -m pytest -q
# expected: 16 passed

# Flutter
cd mobile_app
flutter analyze
# expected: No issues found!
flutter test
# expected: All tests passed!
```

## 3a. Running the app

The backend is the API server; the Flutter app talks to it.

```powershell
# Terminal 1 — backend on http://127.0.0.1:8000
cd backend
..\.venv311\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Then open <http://127.0.0.1:8000/docs> for the interactive Swagger UI.

To start it detached (so it keeps running while you do other work):

```powershell
cd backend
Start-Process -FilePath "..\.venv311\Scripts\python.exe" `
  -ArgumentList "-m","uvicorn","app.main:app","--host","127.0.0.1","--port","8000" `
  -WorkingDirectory (Get-Location) -WindowStyle Hidden
```

Sanity check it is alive:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

`"status": "degraded"` on a laptop is **normal and expected** — it means the SQLite
database is connected but optional Redis / MinIO are not running. The app works
without them. `"database": "connected"` is the line that matters.

```powershell
# Flutter app (needs git installed, see section 1)
cd mobile_app
flutter run
```

Available devices:

```powershell
flutter devices          # lists what you can run on
flutter run -d chrome    # fastest to try, no emulator needed
```

---

## 4. Dependency management rules

These rules are what keep your work and your friend's work merging cleanly.

### Never delete `pubspec.lock`

It is committed on purpose. For an application (not a library), the lock file **is** the
source of truth for reproducible builds. Your friend's resolved versions and yours are
currently identical.

### Never loosen a constraint to "get it working"

If `pub get` fails to resolve, the correct fix is to align the constraint with the
locked version, not to delete the lock or run `pub upgrade`. Use:

```bash
cd mobile_app
flutter pub get --enforce-lockfile    # fails loudly if the lock would change
```

### When you genuinely add a dependency

```bash
cd mobile_app
flutter pub add <package>
```

Then **commit `pubspec.yaml` AND `pubspec.lock` together** in the same commit. A
mismatched pair is the single most common source of painful merge conflicts.

Tell your friend in the PR description which packages changed so they can pull
immediately without surprises.

### Backend dependencies

`backend/requirements.txt` uses exact `==` pins for the same reason. Update it
deliberately and note the change:

```bash
cd backend
..\.venv311\Scripts\python.exe -m pip install <package>==<version>
# then edit requirements.txt to match what pip just installed
```

Verify the backend environment is complete at any time:

```powershell
..\.venv311\Scripts\python.exe -m pip install -r requirements.txt --dry-run
```

---

## 5. Day-to-day git workflow

```bash
git pull --rebase origin main     # before you start
# ... work ...
flutter analyze && flutter test   # mobile_app
..\.venv311\Scripts\python.exe -m pytest -q   # backend
git add -A
git commit -m "feat: add mandi price trend chart"
git push origin main
```

Before pushing, run the verification steps in section 3. Both of you should keep the
suites green on your own branch so merges stay boring.

---

## 6. Known non-issues (expected, not bugs)

- **`DEBUG` may resolve to `False` on some machines.** A machine-wide `DEBUG=release`
  environment variable can shadow the app config. `app/config.py` now parses booleans
  leniently, so this no longer crashes. The startup `CRITICAL SECURITY RISK` message
  about the default `SECRET_KEY` is *expected* in local development — it only fires
  when `DEBUG=False`, which is what that stray variable causes.
- **The PyTorch model reports as unavailable.** `best_model_final.pth` and `torch` are
  intentionally excluded from git (large binaries). `CropAIService` degrades to a
  deterministic offline fallback, and the test suite is written to accept either mode.
  The app works fully without the weights.
- **`flutter analyze` may report newer package versions available.** That is normal.
  The project intentionally pins older versions that are verified to work together.
  Do not upgrade casually.
