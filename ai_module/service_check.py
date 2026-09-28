"""End-to-end check of the backend CropAIService confidence gating."""
import io, os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "backend"))
from app.services.crop_ai_service import CropAIService

svc = CropAIService.get_instance()
assert svc._model is not None, "model failed to load - would silently fall back!"
print(f"engine: {svc.run_inference(open('x','rb').read() or b'', None)['model_engine'] if False else 'loaded'}\n")

rng = np.random.default_rng(7)
base = np.zeros((300, 300, 3), np.uint8)
base[..., 0], base[..., 1], base[..., 2] = 60, 130, 55
green = np.clip(base.astype(int) + rng.normal(0, 8, base.shape), 0, 255).astype(np.uint8)
buf = io.BytesIO(); Image.fromarray(green).save(buf, format="JPEG")

print(f"{'crop hint':<10}{'predicted':<40}{'conf':>8}{'crop mass':>11}{'mismatch':>10}{'lowconf':>9}")
print("-" * 88)
ok = True
for hint in ("tomato", "potato", "maize", "apple", None):
    r = svc.run_inference(buf.getvalue(), hint)
    print(f"{str(hint):<10}{r['predicted_class']:<40}{r['confidence']*100:>7.1f}%"
          f"{r['crop_match_confidence']*100:>10.1f}%{str(r['is_crop_mismatch']):>10}{str(r['is_low_confidence']):>9}")
    # A crop the model barely believes in must be flagged as a mismatch, so the
    # UI shows "WRONG CROP" instead of a confident (but meaningless) disease.
    if hint in ("potato", "apple") and not r["is_crop_mismatch"]:
        ok = False
    # The crop the model actually recognises must NOT be flagged.
    if hint == "tomato" and r["is_crop_mismatch"]:
        ok = False
    # With no crop hint the model picks the crop itself, so mismatch is moot.
    if hint is None and r["is_crop_mismatch"]:
        ok = False

print()
print("PASS: wrong-crop results flagged, right-crop result trusted" if ok
      else "FAIL: crop-match gating is not behaving as expected")
sys.exit(0 if ok else 1)