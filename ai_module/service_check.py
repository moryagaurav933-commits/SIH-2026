"""End-to-end check of the backend CropAIService confidence gating across V1 and V2 models."""
import io, os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "backend"))
from app.services.crop_ai_service import CropAIService

svc = CropAIService.get_instance()
assert svc._model is not None, "V1 model failed to load - would silently fall back!"
assert svc._model_v2 is not None, "V2 model failed to load - would silently fall back!"

print("=" * 94)
print("  KRISHI-SAARTHI UNIFIED SERVICE CHECK: DUAL MOBILENETV3 (V1 + V2)")
print("=" * 94)
print(f"  V1 Model (4 crops / 21 classes) : Loaded (best_model_final.pth)")
print(f"  V2 Model (8 crops / 24 classes) : Loaded (best_model_v2.pth)")
print(f"  Total Classes Integrated        : {len(svc._class_names) + len(svc._class_names_v2)} classes across 12 crops")
print("=" * 94)

rng = np.random.default_rng(7)
base = np.zeros((300, 300, 3), np.uint8)
base[..., 0], base[..., 1], base[..., 2] = 60, 130, 55
green = np.clip(base.astype(int) + rng.normal(0, 8, base.shape), 0, 255).astype(np.uint8)
buf = io.BytesIO(); Image.fromarray(green).save(buf, format="JPEG")

print(f"{'crop hint':<12}{'model engine':<25}{'predicted':<35}{'conf':>8}{'mismatch':>10}")
print("-" * 94)
ok = True

test_hints = ["tomato", "potato", "maize", "apple", "cashew", "chilli", "cotton", "grape", None]
for hint in test_hints:
    r = svc.run_inference(buf.getvalue(), hint)
    engine_short = "V2 (best_model_v2)" if "V2" in r.get("model_engine", "") else "V1 (best_model_final)"
    print(f"{str(hint):<12}{engine_short:<25}{r['predicted_class']:<35}{r['confidence']*100:>7.1f}%"
          f"{str(r['is_crop_mismatch']):>10}")
    
    # A crop the model barely believes in must be flagged as a mismatch
    if hint in ("potato", "apple") and not r["is_crop_mismatch"]:
        ok = False
    if hint == "tomato" and r["is_crop_mismatch"]:
        ok = False
    if hint is None and r["is_crop_mismatch"]:
        ok = False

print()
print("PASS: Both V1 and V2 models active, wrong-crop results flagged, right-crop trusted" if ok
      else "FAIL: crop-match gating is not behaving as expected")
sys.exit(0 if ok else 1)