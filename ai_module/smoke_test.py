"""
smoke_test.py - sanity checks for the disease model pipeline.
Verifies: checkpoint loads, architecture matches, class index mapping is
consistent, and inference produces a valid probability distribution.
"""
import io
import json
import os
import sys

import numpy as np
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)

CKPT = os.path.join(BASE, "best_model_final.pth")
CLASSES = os.path.join(BASE, "class_names.json")

fails = []


def check(name, cond, detail=""):
    print(f"  [{'PASS' if cond else 'FAIL'}] {name}{(' - ' + detail) if detail else ''}")
    if not cond:
        fails.append(name)


print("=" * 60)
print("  DISEASE MODEL SMOKE TEST")
print("=" * 60)

# 1. Class names sanity
with open(CLASSES) as f:
    cfg = json.load(f)
names = cfg["class_names"]
c2i = cfg["class_to_idx"]
print(f"\n1. Class config: {len(names)} classes")
check("21 classes", len(names) == 21)
check("class_to_idx consistent", all(c2i[n] == i for i, n in enumerate(names)))
check("unique class names", len(set(names)) == len(names))

# 2. PLANT_INDICES must match class_names prefixes exactly
import predict as P

print("\n2. Crop index mapping")
for key, (crop, indices) in P.PLANT_INDICES.items():
    prefixes = {names[i].split("___")[0] for i in indices}
    ok = len(prefixes) == 1
    print(f"   {crop:8s} idx={indices[0]}..{indices[-1]}  prefix={prefixes}")
    check(f"{crop} indices contiguous+single crop", ok and indices == list(range(indices[0], indices[-1] + 1)))

covered = sorted(i for _, idx in P.PLANT_INDICES.values() for i in idx)
check("all 21 classes covered by a crop group", covered == list(range(21)))
for k in ("1", "2", "3", "4"):
    crop, idx = P.PLANT_INDICES[k]
    check(f"'{crop}' group contains its healthy class",
          any("healthy" in names[i].lower() for i in idx))

# 3. Load model
print("\n3. Model checkpoint")
import torch
import torch.nn as nn
from torchvision import models

ckpt = torch.load(CKPT, map_location="cpu", weights_only=False)
sd = ckpt.get("model_state", ckpt) if isinstance(ckpt, dict) else ckpt
model = models.mobilenet_v3_large(weights=None)
model.classifier[3] = nn.Linear(model.classifier[3].in_features, len(names))
model.load_state_dict(sd)
model.eval()
fc = model.classifier[3]
check("classifier outputs 21 classes", fc.out_features == 21, f"out_features={fc.out_features}")
extra = set(k for k in ckpt.keys()) - {"model_state", "epoch", "val_acc"} if isinstance(ckpt, dict) else set()
if isinstance(ckpt, dict) and "epoch" in ckpt:
    print(f"   checkpoint epoch={ckpt['epoch']}"
          + (f" val_acc={ckpt['val_acc']:.4f}" if isinstance(ckpt.get("val_acc"), float) else ""))

# 4. Inference smoke test on synthetic images
print("\n4. Inference")
from torchvision import transforms

tf = transforms.Compose([
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])

rng = np.random.default_rng(0)
for label, maker in [
    ("random noise", lambda: rng.integers(0, 256, (300, 300, 3), dtype=np.uint8)),
    ("green leaf-ish", lambda: np.tile(
        np.linspace(40, 160, 300, dtype=np.uint8)[None, :, None], (300, 1, 3))),
    ("brown patch", lambda: np.full((256, 256, 3), (120, 80, 40), np.uint8)),
]:
    arr = maker()
    pil = Image.fromarray(arr)
    proc = P._preprocess_image(pil)
    with torch.no_grad():
        probs = torch.softmax(model(tf(proc).unsqueeze(0))[0], dim=0).numpy()
    check(f"{label}: 224x224 crop", proc.size == (224, 224), str(proc.size))
    check(f"{label}: probs sum to 1", abs(probs.sum() - 1.0) < 1e-5, f"sum={probs.sum():.6f}")
    check(f"{label}: no NaN/inf", np.isfinite(probs).all())
    top = int(probs.argmax())
    print(f"      -> top={names[top]}  p={probs[top]:.4f}  crop_prob={probs[P.PLANT_INDICES['1'][1]].sum():.4f}")

# 5. crop-restricted path works
print("\n5. Crop-restricted prediction path")
arr = rng.integers(0, 256, (300, 300, 3), dtype=np.uint8)
pil = Image.fromarray(arr)
with torch.no_grad():
    probs = torch.softmax(model(tf(P._preprocess_image(pil)).unsqueeze(0))[0], dim=0).numpy()
for k, (crop, indices) in P.PLANT_INDICES.items():
    sub = np.array([probs[i] for i in indices])
    norm = sub / sub.sum()
    order = np.argsort(norm)[::-1]
    check(f"{crop}: renormalized sums to 1", abs(norm.sum() - 1.0) < 1e-6)
    print(f"      {crop:8s} top={names[indices[order[0]]]} ({norm[order[0]]*100:.1f}%)")

print("\n" + "=" * 60)
if fails:
    print(f"  {len(fails)} CHECK(S) FAILED: {fails}")
    sys.exit(1)
print("  ALL CHECKS PASSED")
print("=" * 60)
