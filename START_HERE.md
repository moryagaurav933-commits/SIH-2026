# 🌾 START HERE — Developer Onboarding Guide

Welcome to the **Krishi-Saarthi (कृषि-सारथी)** project for Smart India Hackathon (SIH 2026).

This is the **first document** you should read. It tells you exactly where the project stands, what models are ready, how to run and test everything, and what your tasks are.

---

## 1. What Is This Project?

Krishi-Saarthi is an AI-powered crop advisory and plant disease diagnosis system tailored for Indian agriculture. 

The core flow of the **Scan AI** feature is:
```
Farmer opens app 
    ↓
Selects Crop (e.g. Tomato, Potato, Chilli, Cotton, Grape...)
    ↓
Captures / Uploads leaf photo
    ↓
System routes image to the appropriate AI model
    ↓
Accurate disease / healthy diagnosis returned with treatment advisories
```

---

## 2. What Is Already Completed?

1. **FastAPI AI Backend** with SQLite auto-fallback, relational database seed (farmers, crops, treatments, mandi prices, weather), and REST APIs.
2. **Flutter Cross-Platform Frontend** (Mobile, Web, macOS) with Camera, Diagnosis UI, and Audio advisories.
3. **V1 MobileNetV3-Large Model** trained on 4 crops and 21 classes (PlantVillage benchmark).
4. **V2 MobileNetV3-Large Model** trained and evaluated on 8 crops and 24 classes (**97.32% test accuracy**, zero cross-split duplicate leakage).
5. **Automated Setup & Launcher Scripts** for zero-friction local development.

---

## 3. What Models Exist?

The project uses two separate, complementary MobileNetV3-Large neural network models that together cover **45 disease and healthy classes across 12 crops**:

| Model | Crops Covered | Classes | Status | Checkpoint Location |
| :--- | :--- | :---: | :---: | :--- |
| **V1 Model** | Tomato, Potato, Maize, Apple | **21** | Trained & Validated | `ai_module/best_model_final.pth` |
| **V2 Model** | Cashew, Cassava, Chilli, Cotton, Grape, Groundnut, Papaya, Soybean | **24** | Trained & Evaluated (97.3% Acc) | `ai_module/models/v2/best_model_v2.pth` |
| **Combined** | **12 Indian Crops Total** | **45** | Ready for Routing Integration | — |

---

## 4. Where Is the V1 Model?

- **Weights File:** `ai_module/best_model_final.pth` (~16.3 MB)
- **Class Mapping:** `ai_module/class_names.json` (21 classes)
- **CLI Inference Script:** `ai_module/predict.py`
- **Crops:** `Tomato` (10 classes), `Potato` (3 classes), `Maize` (4 classes), `Apple` (4 classes).

---

## 5. Where Is the V2 Model?

- **Weights File:** `ai_module/models/v2/best_model_v2.pth` (~16.3 MB)
- **Class Mapping:** `ai_module/models/v2/class_names_v2.json` (24 classes)
- **Evaluation Report:** `ai_module/models/v2/evaluation_report.txt`
- **Confusion Matrix:** `ai_module/models/v2/confusion_matrix.png`
- **CLI Inference Script:** `ai_module/predict_v2.py`
- **Crops:** `Cashew` (3), `Cassava` (3), `Chilli` (3), `Cotton` (3), `Grape` (3), `Groundnut` (3), `Papaya` (3), `Soybean` (3).

---

## 6. Where Are the Datasets? (Intentionally NOT in Git)

The full 28,337-image training datasets (`D:\MASTER_DATASET` and `D:\15 Crop 45 Disease...`) are stored on external storage and are **intentionally excluded from Git**.

- **Why?** Git repositories should not hold gigabytes of raw images.
- **Do I need the dataset?** **NO.** Both V1 and V2 models are already trained, validated, and saved as lightweight `.pth` checkpoints. You can run inference on any new, external, or camera image without needing the training images.

---

## 7. Strict Rule: Do NOT Overwrite V1

- Do **not** retrain, overwrite, or delete `ai_module/best_model_final.pth`.
- Do **not** overwrite `ai_module/class_names.json`.
- V1 is tested and currently serves the active application.

---

## 8. Strict Rule: Do NOT Retrain V2 Initially

- `ai_module/models/v2/best_model_v2.pth` already achieved **97.32% test accuracy** on 2,837 unseen images.
- Your immediate goal is **integration**, not retraining. Test it with unseen images first.

---

## 9. How to Install Dependencies (5-Minute Quickstart)

### On Windows (PowerShell):
```powershell
# Run the automated handover setup
powershell -ExecutionPolicy Bypass -File .\scripts\setup_handover.ps1
```

### On macOS / Linux:
```bash
chmod +x scripts/setup_handover.sh
./scripts/setup_handover.sh
```

This automatically:
1. Detects Python 3.10+.
2. Verifies both V1 and V2 model files are present.
3. Sets up `.venv311` virtual environment.
4. Installs required dependencies (`torch`, `torchvision`, `fastapi`, `pillow`, etc.).
5. Creates `backend/.env` from template.
6. Runs `scripts/verify_models.py` to confirm everything works.

---

## 10. How to Start the Backend

```powershell
# From repository root:
.\.venv311\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --app-dir backend
```
- Interactive API Documentation: **http://127.0.0.1:8000/docs**
- Health Check: **http://127.0.0.1:8000/health** (reports `"status": "healthy"`)

---

## 11. How to Start the Frontend

```powershell
# Automated launcher (starts backend + web app simultaneously):
powershell -ExecutionPolicy Bypass -File .\run_app.ps1

# Or manually run Flutter web:
cd mobile_app
flutter run -d chrome
```
App URL: **http://127.0.0.1:8080** (or port assigned by Chrome).

---

## 12. How to Test V1

Run the V1 prediction engine on any image:
```powershell
# Interactive mode (prompts to choose crop 1-4):
.\.venv311\Scripts\python.exe ai_module\predict.py path\to\leaf.jpg

# Or pass crop directly:
.\.venv311\Scripts\python.exe ai_module\predict.py path\to\leaf.jpg tomato
```

---

## 13. How to Test V2

Run the standalone V2 prediction engine on any image:
```powershell
# Global 24-class prediction:
.\.venv311\Scripts\python.exe ai_module\predict_v2.py path\to\leaf.jpg

# With crop routing hint (e.g. cashew, chilli, cotton, grape, groundnut, papaya, soybean, cassava):
.\.venv311\Scripts\python.exe ai_module\predict_v2.py path\to\leaf.jpg cashew
```

---

## 14. How to Test an External Image

1. Download or take any photo of a plant leaf (e.g., from your phone or Google Images).
2. Save it as `test_leaf.jpg`.
3. If it is one of the V1 crops (`tomato`, `potato`, `maize`, `apple`):
   ```powershell
   .\.venv311\Scripts\python.exe ai_module\predict.py test_leaf.jpg tomato
   ```
4. If it is one of the V2 crops (`cashew`, `cassava`, `chilli`, `cotton`, `grape`, `groundnut`, `papaya`, `soybean`):
   ```powershell
   .\.venv311\Scripts\python.exe ai_module\predict_v2.py test_leaf.jpg chilli
   ```

---

## 15. The Target Scan AI Architecture

In the final application, crop selection acts as a **router**, NOT an image crop:

```
                  ┌──────────────────────┐
                  │ Farmer Selects Crop  │
                  └──────────┬───────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   [ V1 Crops (4) ]                  [ V2 Crops (8) ]
   Tomato, Potato, Maize, Apple      Cashew, Cassava, Chilli, Cotton,
            │                        Grape, Groundnut, Papaya, Soybean
            ▼                                 │
   Route to V1 Model                          ▼
   (ai_module/best_model_final.pth)   Route to V2 Model
            │                         (ai_module/models/v2/best_model_v2.pth)
            │                                 │
            │                         Restrict prediction to selected
            │                         crop's valid 3 classes
            │                                 │
            └────────────────┬────────────────┘
                             ▼
              Display Diagnosis + Treatments
```

---

## 16. What Work Remains for You?

1. **Verify both models:** Run `.\.venv311\Scripts\python.exe scripts\verify_models.py`.
2. **Test external images:** Download 2-3 sample images for each of the 8 new crops and confirm `predict_v2.py` gives sensible outputs.
3. **Connect V2 in backend:** Update `backend/app/services/crop_ai_service.py` to load V2 alongside V1 and route requests based on the selected crop.
4. **Expose new crops in Flutter UI:** Add the 8 new crops to the mobile crop selector in `mobile_app/lib/screens/diagnosis/diagnosis_screen.dart`.
5. **End-to-End Test:** Take a picture in the Flutter app $\rightarrow$ send to `/api/diagnose` $\rightarrow$ verify diagnosis and treatment cards display correctly.

---

## 17. How to Verify Models Are Loading

Run the dedicated read-only verification tool anytime:
```powershell
.\.venv311\Scripts\python.exe scripts\verify_models.py
```
Expected output:
```
============================================================
VERIFICATION SUMMARY
============================================================
  V1 Model (21 classes / 4 crops): [PASS]
  V2 Model (24 classes / 8 crops): [PASS]
  Combined Target:                 45 total disease/healthy classes
============================================================
ALL MODEL CHECKS PASSED. Ready for handover and inference testing.
```

---

## 18. Common Problems & How to Fix Them

- **"No Python 3.10+ found"**
  Install Python 3.11 from python.org and ensure **"Add python.exe to PATH"** is ticked during install.
- **"CUDA out of memory" or "CUDA not available"**
  Both models are lightweight MobileNetV3-Large networks. They run fast on CPU (~18 ms per image). GPU is completely optional.
- **"Port 8000 already in use"**
  ```powershell
  Get-NetTCPConnection -LocalPort 8000 -State Listen | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
  ```
- **"Crop Mismatch Warning"**
  If `predict.py` or `predict_v2.py` prints `[WARNING] CROP MISMATCH DETECTED`, the model determined that the image looks like a different crop. This is a built-in safety guard preventing farmers from spraying the wrong pesticide.

For in-depth technical details on the architecture and integration steps, read **`HANDOVER.md`**.
