"""
verify_models.py — Read-Only Verification of V1 and V2 Crop Disease Models
Krishi-Saarthi / SIH-2026 Agriculture Disease Detection Project

Checks:
- V1: best_model_final.pth, class_names.json (21 classes), MobileNetV3 load, eval mode
- V2: best_model_v2.pth, class_names_v2.json (24 classes), MobileNetV3 load, eval mode

Guarantees:
- Strictly READ-ONLY. Does not modify or retrain anything.
- Exits 0 on PASS, 1 on FAIL.
"""

import os
import sys
import json
from pathlib import Path

# Fix console encoding on Windows to prevent cp1252 charmap crashes
try:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

import torch
import torch.nn as nn
from torchvision import models

ROOT_DIR = Path(__file__).resolve().parent.parent
AI_DIR = ROOT_DIR / "ai_module"

V1_MODEL_PATH = AI_DIR / "best_model_final.pth"
V1_CLASSES_PATH = AI_DIR / "class_names.json"

V2_MODEL_PATH = AI_DIR / "models" / "v2" / "best_model_v2.pth"
V2_CLASSES_PATH = AI_DIR / "models" / "v2" / "class_names_v2.json"

EXPECTED_V1_CLASSES = 21
EXPECTED_V2_CLASSES = 24


def verify_v1():
    print("-" * 60)
    print("VERIFYING V1 MODEL (Existing 4 Crops / 21 Classes)")
    print("-" * 60)

    # 1. File checks
    if not V1_MODEL_PATH.exists():
        print(f"  [FAIL] V1 model weights not found at: {V1_MODEL_PATH}")
        return False
    size_mb = V1_MODEL_PATH.stat().st_size / (1024 * 1024)
    print(f"  [PASS] V1 model weights exist: {V1_MODEL_PATH.name} ({size_mb:.2f} MB)")

    if not V1_CLASSES_PATH.exists():
        print(f"  [FAIL] V1 class mapping not found at: {V1_CLASSES_PATH}")
        return False
    print(f"  [PASS] V1 class mapping exists: {V1_CLASSES_PATH.name}")

    # 2. Read class mapping
    try:
        with open(V1_CLASSES_PATH, "r", encoding="utf-8") as f:
            v1_meta = json.load(f)
        v1_classes = v1_meta.get("class_names", [])
        if len(v1_classes) != EXPECTED_V1_CLASSES:
            print(f"  [FAIL] V1 expected {EXPECTED_V1_CLASSES} classes, got {len(v1_classes)}")
            return False
        print(f"  [PASS] V1 class count matches: {len(v1_classes)} classes verified")
    except Exception as e:
        print(f"  [FAIL] Error reading V1 class mapping: {e}")
        return False

    # 3. Load model and verify eval mode
    try:
        model = models.mobilenet_v3_large(weights=None)
        in_features = model.classifier[3].in_features
        model.classifier[3] = nn.Linear(in_features, len(v1_classes))
        
        ckpt = torch.load(V1_MODEL_PATH, map_location="cpu", weights_only=False)
        state_dict = ckpt.get("model_state", ckpt) if isinstance(ckpt, dict) else ckpt
        model.load_state_dict(state_dict)
        model.eval()

        if model.training:
            print("  [FAIL] V1 model failed to enter evaluation mode")
            return False
        print("  [PASS] V1 MobileNetV3-Large loaded into evaluation mode")

        # Smoke forward pass
        dummy = torch.randn(1, 3, 224, 224)
        with torch.no_grad():
            out = model(dummy)
        if out.shape != (1, EXPECTED_V1_CLASSES):
            print(f"  [FAIL] V1 output shape mismatch: {out.shape} != (1, {EXPECTED_V1_CLASSES})")
            return False
        print(f"  [PASS] V1 forward pass succeeded: output shape {tuple(out.shape)}")
        return True
    except Exception as e:
        print(f"  [FAIL] V1 load or inference failed: {e}")
        return False


def verify_v2():
    print("\n" + "-" * 60)
    print("VERIFYING V2 MODEL (New 8 Crops / 24 Classes)")
    print("-" * 60)

    # 1. File checks
    if not V2_MODEL_PATH.exists():
        print(f"  [FAIL] V2 model weights not found at: {V2_MODEL_PATH}")
        return False
    size_mb = V2_MODEL_PATH.stat().st_size / (1024 * 1024)
    print(f"  [PASS] V2 model weights exist: {V2_MODEL_PATH.name} ({size_mb:.2f} MB)")

    if not V2_CLASSES_PATH.exists():
        print(f"  [FAIL] V2 class mapping not found at: {V2_CLASSES_PATH}")
        return False
    print(f"  [PASS] V2 class mapping exists: {V2_CLASSES_PATH.name}")

    # 2. Read class mapping
    try:
        with open(V2_CLASSES_PATH, "r", encoding="utf-8") as f:
            v2_meta = json.load(f)
        v2_classes = v2_meta.get("class_names", [])
        if len(v2_classes) != EXPECTED_V2_CLASSES:
            print(f"  [FAIL] V2 expected {EXPECTED_V2_CLASSES} classes, got {len(v2_classes)}")
            return False
        crops = v2_meta.get("crops", [])
        print(f"  [PASS] V2 class count matches: {len(v2_classes)} classes across {len(crops)} crops")
    except Exception as e:
        print(f"  [FAIL] Error reading V2 class mapping: {e}")
        return False

    # 3. Load model and verify eval mode
    try:
        model = models.mobilenet_v3_large(weights=None)
        in_features = model.classifier[3].in_features
        model.classifier[3] = nn.Linear(in_features, len(v2_classes))
        
        ckpt = torch.load(V2_MODEL_PATH, map_location="cpu", weights_only=False)
        state_dict = ckpt.get("model_state", ckpt) if isinstance(ckpt, dict) else ckpt
        model.load_state_dict(state_dict)
        model.eval()

        if model.training:
            print("  [FAIL] V2 model failed to enter evaluation mode")
            return False
        print("  [PASS] V2 MobileNetV3-Large loaded into evaluation mode")

        # Smoke forward pass
        dummy = torch.randn(1, 3, 224, 224)
        with torch.no_grad():
            out = model(dummy)
        if out.shape != (1, EXPECTED_V2_CLASSES):
            print(f"  [FAIL] V2 output shape mismatch: {out.shape} != (1, {EXPECTED_V2_CLASSES})")
            return False
        print(f"  [PASS] V2 forward pass succeeded: output shape {tuple(out.shape)}")
        return True
    except Exception as e:
        print(f"  [FAIL] V2 load or inference failed: {e}")
        return False


def main():
    print("=" * 60)
    print("  KRISHI-SAARTHI MODEL VERIFICATION (READ-ONLY)")
    print("=" * 60)

    v1_ok = verify_v1()
    v2_ok = verify_v2()

    print("\n" + "=" * 60)
    print("VERIFICATION SUMMARY")
    print("=" * 60)
    print(f"  V1 Model (21 classes / 4 crops): {'[PASS]' if v1_ok else '[FAIL]'}")
    print(f"  V2 Model (24 classes / 8 crops): {'[PASS]' if v2_ok else '[FAIL]'}")
    print(f"  Combined Target:                 45 total disease/healthy classes")
    print("=" * 60)

    if v1_ok and v2_ok:
        print("ALL MODEL CHECKS PASSED. Ready for handover and inference testing.")
        sys.exit(0)
    else:
        print("ONE OR MORE MODEL CHECKS FAILED. See details above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
