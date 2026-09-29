# 🛠️ Krishi-Saarthi Technical Handover Document

**Target Audience:** Next Backend / ML / Mobile Integration Engineer  
**Objective:** Integrate V1 (21 classes) and V2 (24 classes) models into a unified 45-class Scan AI pipeline without retraining.

---

## 1. Current Status & System Architecture

### 1.1 The Dual-Model Architecture
To achieve high diagnostic accuracy across 12 major Indian crops without the negative interference and catastrophic forgetting of a single monolithic model, the system uses a **Dual-Model Routing Architecture**:

- **Model V1 (4 Crops / 21 Classes):**
  - **File:** `ai_module/best_model_final.pth`
  - **Class Mapping:** `ai_module/class_names.json`
  - **Crops:** Tomato, Potato, Maize, Apple
  - **Origin:** PlantVillage benchmark fine-tuned on MobileNetV3-Large.
  - **Status:** **FROZEN.** Do not modify, retrain, or convert.

- **Model V2 (8 Crops / 24 Classes):**
  - **File:** `ai_module/models/v2/best_model_v2.pth`
  - **Class Mapping:** `ai_module/models/v2/class_names_v2.json`
  - **Crops:** Cashew, Cassava, Chilli, Cotton, Grape, Groundnut, Papaya, Soybean
  - **Origin:** ICAR & Indian benchmark dataset (28,337 images), trained with MobileNetV3-Large + ImageNet weights.
  - **Metrics:** **97.32% test accuracy**, **97.97% Macro F1**.
  - **Status:** **TRAINED & VERIFIED.** Ready for deployment.

### 1.2 Combined Target: 45 Classes Across 12 Crops
| Crop | Model Assigned | Conditions / Classes Covered |
| :--- | :---: | :--- |
| **Tomato** | **V1** | Bacterial spot, Early blight, Late blight, Leaf Mold, Septoria leaf spot, Spider mites, Target Spot, Tomato Yellow Leaf Curl Virus, Mosaic virus, Healthy (10) |
| **Potato** | **V1** | Early blight, Late blight, Healthy (3) |
| **Maize (Corn)** | **V1** | Cercospora leaf spot (Gray leaf spot), Common rust, Northern Leaf Blight, Healthy (4) |
| **Apple** | **V1** | Apple scab, Black rot, Cedar apple rust, Healthy (4) |
| **Cashew** | **V2** | Leaf Miner, Red Rust, Healthy (3) |
| **Cassava** | **V2** | Brown Spot, Mosaic, Healthy (3) |
| **Chilli** | **V2** | Healthy, Nutrition Deficiency, White Spot (3) |
| **Cotton** | **V2** | Bacterial Blight, Curl Virus, Healthy (3) |
| **Grape** | **V2** | Black Rot, Leaf Blight, Healthy (3) |
| **Groundnut** | **V2** | Healthy Leaf, Late Leaf Spot, Nutrition Deficiency (3) |
| **Papaya** | **V2** | Bacterial Spot, Healthy, Ring Spot (3) |
| **Soybean** | **V2** | Caterpillar, Diabrotica speciosa, Healthy (3) |
| **TOTAL** | **V1 + V2** | **45 Total Classes across 12 Crops** |

---

## 2. Core Principle: Crop Selection as a ROUTER

> **CRITICAL CONCEPT:**  
> When the user selects a crop in the mobile UI, that selection acts as an **intelligent model router and class filter**.  
> It does **NOT** mean cropping/slicing the image pixels!

### How Routing Must Function:

```
                          [ Incoming Image ]
                                  │
                       [ User Selected Crop ]
                                  │
          ┌───────────────────────┴───────────────────────┐
          ▼                                               ▼
   Is it a V1 Crop?                                Is it a V2 Crop?
   (Tomato, Potato, Maize, Apple)                  (Cashew, Cassava, Chilli, Cotton,
          │                                         Grape, Groundnut, Papaya, Soybean)
          ▼                                               │
   Execute V1 Model                                       ▼
   ai_module/best_model_final.pth                  Execute V2 Model
          │                                        ai_module/models/v2/best_model_v2.pth
          ▼                                               │
   Filter prediction to V1                                ▼
   selected crop's indices                         Filter prediction to V2
          │                                        selected crop's 3 indices
          └───────────────────────┬───────────────────────┘
                                  ▼
                     [ Return Diagnosis & Advice ]
```

### Why Scoped Filtering Is Mandatory:
The V2 model has 24 output logits. If a farmer chooses **Chilli**, you must **never** return `Soybean___Caterpillar` or `Cashew___Leaf_Miner`, even if the model's global top logit happened to fire for another crop.

Instead:
1. Extract the probability mass across the 3 classes belonging to Chilli (`indices = [6, 7, 8]`).
2. Verify that the model actually believes the leaf is Chilli (`crop_mass >= 0.35`). If `crop_mass < 0.35`, raise a **Crop Mismatch Warning** asking the user to re-check the crop.
3. Renormalize the softmax probabilities over those 3 Chilli classes:
   $$\hat{P}_i = \frac{P_i}{\sum_{j \in \text{Chilli}} P_j}$$
4. Return the top condition among the selected crop's valid diseases.

*Note: This pattern is already fully implemented and tested in `ai_module/predict_v2.py`. Refer to lines 80–110 of that file for the reference implementation.*

---

## 3. Step-by-Step Developer Integration Roadmap

Your job is to connect V2 into the full application flow. Here is the recommended sequence:

### Step 1: Verification & External Image Testing
1. Run `.\scripts\setup_handover.ps1` (or `python scripts/verify_models.py`). Confirm both models pass.
2. Test V1 with an external leaf image:
   ```powershell
   python ai_module/predict.py <path_to_image> tomato
   ```
3. Test V2 with an external leaf image:
   ```powershell
   python ai_module/predict_v2.py <path_to_image> chilli
   ```

### Step 2: Update Backend Service (`backend/app/services/crop_ai_service.py`)
Currently, `CropAIService` loads only the V1 PyTorch checkpoint. Update it to:
1. Hold two model instances: `self._model_v1` and `self._model_v2`.
2. Load `class_names_v2.json` and initialize `MobileNetV3-Large` for V2 (24 classes).
3. In `run_inference(image_bytes, crop_hint)`:
   - Check if `crop_hint` matches one of the 8 V2 crops.
   - If V2 crop: run inference through `self._model_v2` with V2 transforms (`Resize 256 -> CenterCrop 224 -> Normalize`).
   - If V1 crop: run inference through `self._model_v1` as before.
   - If no crop given: run global inference or default to highest confidence across models.

### Step 3: Populate Disease Profiles for V2 Crops in the Database
The backend retrieves treatments from the database tables (`crops`, `diseases`, `treatments`).
- Check `backend/scripts/init_db.py`.
- Add relational entries for the 8 new crops and their 24 conditions (English and Hindi names, chemical treatments, cultural remedies, prevention steps).
- Re-run `python backend/scripts/init_db.py` to update the local SQLite database (`backend/krishi_saarthi.db`).

### Step 4: Update Mobile UI (`mobile_app/`)
1. In `mobile_app/lib/screens/diagnosis/diagnosis_screen.dart`:
   - Expand the crop selector dropdown / chips to include all 12 crops:
     `Tomato`, `Potato`, `Maize`, `Apple`, `Cashew`, `Cassava`, `Chilli`, `Cotton`, `Grape`, `Groundnut`, `Papaya`, `Soybean`.
2. Ensure the selected crop string is sent as the `crop_hint` multipart form field in `mobile_app/lib/services/cv_service.dart`.
3. Verify diagnosis cards and treatment text display properly for new crops.

### Step 5: End-to-End Validation
- Start backend: `uvicorn app.main:app --port 8000 --app-dir backend`
- Start frontend: `flutter run -d chrome`
- Upload a test photo for each crop and confirm end-to-end diagnosis flow.

---

## 4. Key File Reference

| File | Purpose |
| :--- | :--- |
| `ai_module/best_model_final.pth` | V1 MobileNetV3 weights (21 classes) — **DO NOT MODIFY** |
| `ai_module/class_names.json` | V1 class names mapping — **DO NOT MODIFY** |
| `ai_module/predict.py` | V1 standalone prediction script |
| `ai_module/models/v2/best_model_v2.pth` | V2 MobileNetV3 weights (24 classes) — **DO NOT RETRAIN** |
| `ai_module/models/v2/class_names_v2.json` | V2 class names & crop-to-index mapping |
| `ai_module/models/v2/evaluation_report.txt` | Complete test evaluation metrics on 2,837 unseen images |
| `ai_module/models/v2/confusion_matrix.png` | 24x24 visual confusion matrix |
| `ai_module/predict_v2.py` | V2 standalone prediction script (reference inference implementation) |
| `scripts/verify_models.py` | Automated read-only test confirming both models load |
| `scripts/setup_handover.ps1` | One-click developer setup for Windows |
| `scripts/setup_handover.sh` | One-click developer setup for Linux/macOS |
| `backend/app/services/crop_ai_service.py` | Backend AI inference service (target for routing integration) |
| `backend/app/api/v1/endpoints/diagnoses.py` | `/api/diagnose` endpoint handler |
| `START_HERE.md` | Primary onboarding guide |

---

## 5. Known Gotchas & Troubleshooting

1. **Crop Hint as Form Field:**
   In `/api/diagnose`, `crop_hint` must be passed as a **multipart form-data field**, NOT a URL query parameter (`?crop_hint=...`). Passing it as a query parameter is ignored by FastAPI form parser.
2. **Deterministic Transforms:**
   Always use `Resize(256) -> CenterCrop(224) -> ToTensor() -> ImageNet Normalization` for inference. Never use random augmentations during prediction.
3. **CPU vs GPU:**
   Both models run natively on CPU in ~18 milliseconds per image. CUDA is an optional accelerator, not a requirement.
4. **Offline SQLite Fallback:**
   The backend automatically uses `backend/krishi_saarthi.db` when Docker/PostgreSQL is offline. No Docker installation is required to develop or test the application.
