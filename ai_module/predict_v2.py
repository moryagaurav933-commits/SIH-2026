"""
predict_v2.py — Standalone V2 Crop Disease Prediction Engine
Krishi-Saarthi / SIH-2026 Agriculture Disease Detection Project

Usage:
  python ai_module/predict_v2.py <image_path> [crop_hint]

Examples:
  python ai_module/predict_v2.py leaf.jpg
  python ai_module/predict_v2.py leaf.jpg cashew
  python ai_module/predict_v2.py leaf.jpg grape

Guarantees:
- Input preprocessing EXACTLY matches validation and test evaluation (Resize 256 -> CenterCrop 224 -> Normalize).
- Outputs predicted crop, disease/condition, confidence, and top-3 ranked predictions.
- Supports optional crop-hint scoping with crop mass verification.
- Completely isolated from V1 models and configs.
"""

import os
import sys
import json
from pathlib import Path

# Ensure UTF-8 output on Windows consoles/pipes to prevent cp1252 charmap crashes
try:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

import numpy as np
import torch
import torch.nn as nn
from torchvision import transforms, models
from PIL import Image

BASE_DIR = Path(__file__).resolve().parent
V2_MODEL_DIR = BASE_DIR / "models" / "v2"
MODEL_PATH = V2_MODEL_DIR / "best_model_v2.pth"
CLASS_MAPPING_PATH = V2_MODEL_DIR / "class_names_v2.json"

MIN_CROP_MASS_THRESHOLD = 0.35
LOW_CONFIDENCE_THRESHOLD = 0.50


def load_v2_model(device):
    """Load MobileNetV3-Large V2 model and class metadata."""
    if not MODEL_PATH.exists():
        sys.exit(f"[ERROR] V2 model checkpoint not found: {MODEL_PATH}\nPlease train the model first with: python ai_module/train_v2.py")
    if not CLASS_MAPPING_PATH.exists():
        sys.exit(f"[ERROR] V2 class mapping not found: {CLASS_MAPPING_PATH}")

    with open(CLASS_MAPPING_PATH, "r", encoding="utf-8") as f:
        meta = json.load(f)

    class_names = meta["class_names"]
    num_classes = len(class_names)
    plant_indices = meta.get("plant_indices", {})

    # Load architecture
    model = models.mobilenet_v3_large(weights=None)
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, num_classes)

    # Load weights
    ckpt = torch.load(MODEL_PATH, map_location=device, weights_only=False)
    state_dict = ckpt.get("model_state", ckpt)
    model.load_state_dict(state_dict)
    model.eval().to(device)

    return model, class_names, plant_indices, ckpt


def get_v2_transform():
    """
    Deterministic inference preprocessing EXACTLY matching validation/test:
    Resize(256) -> CenterCrop(224) -> ToTensor() -> ImageNet Normalization
    """
    return transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])


def verify_leaf_presence(img):
    """Botanical leaf foliage check."""
    small = img.convert("RGB").resize((128, 128), Image.BILINEAR)
    arr = np.array(small, dtype=np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    is_green = (g > r * 0.92) & (g > b * 1.05) & (g > 28) & (g < 250)
    is_yellow = (r > 50) & (g > 50) & (b < r * 0.85) & (b < g * 0.85) & (np.abs(r - g) < 70)
    is_brown = (r > 35) & (r < 220) & (g > 20) & (g < r * 0.98) & (b < g * 0.88) & ((r - b) > 15)
    leaf_mask = is_green | is_yellow | is_brown
    leaf_ratio = float(np.mean(leaf_mask))

    channel_stds = np.std(arr, axis=(0, 1))
    if float(np.mean(channel_stds)) < 6.0:
        if leaf_ratio < 0.80:
            return False

    diff_h = np.mean(leaf_mask[1:, :] ^ leaf_mask[:-1, :])
    diff_w = np.mean(leaf_mask[:, 1:] ^ leaf_mask[:, :-1])
    coherence = 1.0 - float(diff_h + diff_w) / 2.0
    if leaf_ratio < 0.05 or (leaf_ratio > 0.30 and coherence < 0.60):
        return False
    return True


def predict(image_path: str, crop_hint: str = None):
    """Run V2 disease inference on a single image."""
    p = Path(image_path)
    if not p.is_file():
        sys.exit(f"[ERROR] Image file not found: {image_path}")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model, class_names, plant_indices, ckpt = load_v2_model(device)
    transform = get_v2_transform()

    try:
        with Image.open(p) as pil_img:
            img = pil_img.convert("RGB")
    except Exception as e:
        sys.exit(f"[ERROR] Cannot open image {p.name}: {e}")

    # Check botanical leaf presence
    if not verify_leaf_presence(img):
        return {
            "image_file": p.name,
            "predicted_crop": "None",
            "predicted_disease": "NO leaf detected in the image you provide",
            "full_class_tag": "no_leaf_detected",
            "confidence": 0.0,
            "crop_mass": 0.0,
            "is_crop_mismatch": True,
            "is_leaf_detected": False,
            "top_3_predictions": [],
            "device": str(device),
            "val_acc_checkpoint": 0.0
        }

    tensor = transform(img).unsqueeze(0).to(device)

    with torch.no_grad():
        logits = model(tensor)[0]
        probs = torch.softmax(logits, dim=0).cpu().numpy()

    # Determine crop scoping if crop_hint given
    key = crop_hint.lower().strip() if crop_hint else None
    if key and key in plant_indices:
        crop_name, indices = plant_indices[key]
        plant_probs = np.array([probs[i] for i in indices])
        crop_mass = float(plant_probs.sum())
        norm_probs = plant_probs / crop_mass if crop_mass > 0 else plant_probs
        order = np.argsort(norm_probs)[::-1]

        top_idx = indices[order[0]]
        confidence = float(norm_probs[order[0]])
        is_mismatch = crop_mass < MIN_CROP_MASS_THRESHOLD

        top_candidates = [
            (class_names[indices[order[r]]], float(norm_probs[order[r]]))
            for r in range(min(3, len(indices)))
        ]
    else:
        # Global multi-crop prediction across all 24 classes
        order = np.argsort(probs)[::-1]
        top_idx = order[0]
        confidence = float(probs[top_idx])
        crop_mass = 1.0
        is_mismatch = False

        top_candidates = [
            (class_names[order[r]], float(probs[order[r]]))
            for r in range(min(3, len(class_names)))
        ]

    top_tag = class_names[top_idx]
    parts = top_tag.split("___")
    crop_detected = parts[0]
    disease_detected = parts[1].replace("_", " ") if len(parts) > 1 else "Unknown"

    return {
        "image_file": p.name,
        "predicted_crop": crop_detected,
        "predicted_disease": disease_detected,
        "full_class_tag": top_tag,
        "confidence": confidence,
        "crop_mass": crop_mass,
        "is_crop_mismatch": is_mismatch,
        "top_3_predictions": top_candidates,
        "device": str(device),
        "val_acc_checkpoint": ckpt.get("val_acc", 0.0)
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: python ai_module/predict_v2.py <image_path> [crop_hint]")
        print("Example: python ai_module/predict_v2.py leaf.jpg cashew")
        sys.exit(1)

    image_path = sys.argv[1]
    crop_hint = sys.argv[2] if len(sys.argv) >= 3 else None

    result = predict(image_path, crop_hint)

    sep = "=" * 65
    print("\n" + sep)
    print("  KRISHI-SAARTHI V2 DISEASE PREDICTION ENGINE")
    print("  Model: MobileNetV3-Large V2 (24 Classes / 8 Crops)")
    print(sep)
    print(f"  Image File:     {result['image_file']}")
    print(f"  Predicted Crop: {result['predicted_crop']}")
    print(f"  Condition:      {result['predicted_disease']}")
    print(f"  Confidence:     {result['confidence']*100:.2f}%")
    print(f"  Device:         {result['device']}")

    if result["is_crop_mismatch"]:
        print("\n  [WARNING] CROP MISMATCH DETECTED!")
        print(f"  The model found only {result['crop_mass']*100:.1f}% evidence that this leaf is '{crop_hint}'.")
        print("  Please check crop selection before trusting this diagnosis.")
    elif result["confidence"] < LOW_CONFIDENCE_THRESHOLD:
        print("\n  [NOTICE] LOW CONFIDENCE PREDICTION (<50%)")
        print("  Recommendation: Retake photo in better light and focus.")

    print("\n  Top-3 Predictions:")
    for rank, (tag, prob) in enumerate(result["top_3_predictions"], 1):
        clean_name = tag.replace("___", " -> ").replace("_", " ")
        bar = "#" * int(prob * 25)
        print(f"    #{rank}  {prob*100:6.2f}%  {bar:<25}  {clean_name}")

    print(sep + "\n")


if __name__ == "__main__":
    main()
