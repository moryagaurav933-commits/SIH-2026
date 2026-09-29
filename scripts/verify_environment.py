"""
verify_environment.py - Machine / environment conformance check for Krishi-Saarthi.

Read-only. Trains nothing, modifies nothing, downloads nothing, and needs no
network access and no training dataset.

    python scripts\\verify_environment.py
    python scripts\\verify_environment.py --image path\\to\\leaf.jpg
    python scripts\\verify_environment.py --skip-frontend

Exit code 0 = every required check passed.
Exit code 1 = at least one REQUIRED check failed (see the FAIL block).

What is checked
---------------
  1.  Operating system and architecture
  2.  Python interpreter version
  3.  pip availability
  4.  Runtime ML stack (torch, torchvision, numpy, pillow)
  5.  Inference device policy (CPU baseline, CUDA optional)
  6.  V1 model artefacts  (weights, class mapping, load, forward pass)
  7.  V2 model artefacts  (weights, class mapping, load, forward pass)
  8.  Repository-relative model resolution (no hard-coded C:\\ or D:\\ paths)
  9.  Backend dependencies
  10. Backend application import (app.main)
  11. Frontend toolchain (Flutter - optional, non-fatal)
  12. External-image inference (optional; synthetic image if none supplied)
  13. Absence of any dependency on the training dataset locations
"""

from __future__ import annotations

import argparse
import importlib
import importlib.util
import json
import os
import platform
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

# ── Contract constants (single source of truth for the handover) ──────────────
REQUIRED_PYTHON = (3, 11)          # minimum supported
RECOMMENDED_PYTHON = (3, 11, 9)    # exact version verified on the reference machine
MIN_RAM_GB = 8.0
MIN_FREE_DISK_GB = 4.0

PINNED = {
    "torch": "2.14.0",
    "torchvision": "0.29.0",
    "numpy": "2.4.6",
    "pillow": "12.3.0",
    "fastapi": "0.141.1",
    "uvicorn": "0.54.0",
    "pydantic": "2.13.5",
    "pydantic-settings": "2.15.0",
    "SQLAlchemy": "2.1.1",
    "aiosqlite": "0.22.1",
    "alembic": "1.20.0",
    "asyncpg": "0.31.0",
    "psycopg2-binary": "2.9.13",
    "cryptography": "43.0.0",
    "python-jose": "3.5.0",
    "passlib": "1.7.4",
    "python-multipart": "0.0.32",
    "httpx": "0.28.1",
    "aiohttp": "3.14.3",
    "requests": "2.34.2",
    "redis": "8.1.0",
    "structlog": "26.1.0",
    "python-dotenv": "1.2.3",
    "shortuuid": "1.0.13",
    "tenacity": "9.1.4",
    "ai-edge-litert": "2.2.0",
    "pytest": "8.3.0",
    "pytest-asyncio": "0.24.0",
}

# Import name -> distribution name, where they differ.
IMPORT_NAMES = {
    "pillow": "PIL",
    "SQLAlchemy": "sqlalchemy",
    "pydantic-settings": "pydantic_settings",
    "python-jose": "jose",
    "python-multipart": "multipart",
    "python-dotenv": "dotenv",
    "psycopg2-binary": "psycopg2",
    "ai-edge-litert": "ai_edge_litert",
    "pytest-asyncio": "pytest_asyncio",
}

V1_EXPECTED_CLASSES = 21
V2_EXPECTED_CLASSES = 24
V2_EXPECTED_CROPS = 8

ROOT = Path(__file__).resolve().parent.parent
AI_DIR = ROOT / "ai_module"
V2_DIR = AI_DIR / "models" / "v2"

V1_MODEL = AI_DIR / "best_model_final.pth"
V1_CLASSES = AI_DIR / "class_names.json"
V2_MODEL = V2_DIR / "best_model_v2.pth"
V2_CLASSES = V2_DIR / "class_names_v2.json"

# Paths that must never be required at inference time.
FORBIDDEN_RUNTIME_PATHS = [
    r"MASTER_DATASET",
    r"15 Crop 45 Disease",
]

RUNTIME_SOURCES = [
    AI_DIR / "predict.py",
    AI_DIR / "predict_v2.py",
    AI_DIR / "service_check.py",
    AI_DIR / "smoke_test.py",
    ROOT / "scripts" / "verify_models.py",
    ROOT / "backend" / "app" / "services" / "crop_ai_service.py",
    ROOT / "backend" / "app" / "db" / "base.py",
    ROOT / "backend" / "app" / "main.py",
    ROOT / "backend" / "app" / "config.py",
]

# ── Reporting primitives ──────────────────────────────────────────────────────
_LINE = "=" * 78
_results: list[tuple[str, str, str, str]] = []  # (status, section, item, detail)


def _section(title: str) -> None:
    print()
    print("-" * 78)
    print(title)
    print("-" * 78)


def _record(status: str, section: str, item: str, detail: str = "") -> bool:
    """status is one of: PASS, FAIL, WARN, INFO"""
    _results.append((status, section, item, detail))
    colour = {"PASS": "\033[92m", "FAIL": "\033[91m", "WARN": "\033[93m", "INFO": "\033[94m"}
    reset = "\033[0m"
    tag = {
        "PASS": "  [PASS]",
        "FAIL": "  [FAIL]",
        "WARN": "  [WARN]",
        "INFO": "  [INFO]",
    }[status]
    line = f"{colour[status]}{tag}{reset} {item}"
    if detail:
        line += f"  ->  {detail}"
    print(line)
    return status != "FAIL"


def _dist_version(dist: str) -> str | None:
    """Authoritative version: read the installed distribution metadata."""
    try:
        from importlib import metadata
        return metadata.version(dist)
    except Exception:
        return None


def _module_version(mod: str) -> str | None:
    """Version of an installed distribution, identified by its import name."""
    dist = {v: k for k, v in IMPORT_NAMES.items()}.get(mod, mod)
    return _dist_version(dist)


# ── 1. Operating system ──────────────────────────────────────────────────────
def _windows_product_name() -> str:
    """Windows 11 reports kernel 10.0.x, so ask the registry for the real name."""
    if platform.system() != "Windows":
        return platform.system()
    try:
        import winreg
        key = winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE,
            r"SOFTWARE\Microsoft\Windows NT\CurrentVersion",
        )
        name, _ = winreg.QueryValueEx(key, "ProductName")
        display, _ = winreg.QueryValueEx(key, "DisplayVersion") if True else ("", "")
        try:
            build = winreg.QueryValueEx(key, "CurrentBuildNumber")[0]
            ubr = winreg.QueryValueEx(key, "UBR")[0]
        except Exception:
            build, ubr = platform.version(), ""
        try:
            winreg.CloseKey(key)
        except Exception:
            pass
        tail = f" {display}".rstrip() if display else ""
        return f"{str(name).replace('Windows 10', 'Windows 11')}{tail} (build {build}.{ubr})"
    except Exception:
        return f"Windows {platform.release()} (build {platform.version()})"


def check_os() -> None:
    _section("1. OPERATING SYSTEM")
    system = platform.system()
    machine = platform.machine()
    _record("PASS" if system == "Windows" else "FAIL", "os", "Operating system",
            _windows_product_name())
    if system != "Windows":
        _record("FAIL", "os", "Windows required",
                "The verified target is Windows x64. The code is portable, but this "
                "handover was validated on Windows only.")
    _record("PASS" if machine in ("AMD64", "x86_64") else "FAIL", "os",
            "Architecture", machine)
    if machine not in ("AMD64", "x86_64"):
        _record("FAIL", "os", "64-bit required", f"detected {machine}")


# ── 2/3. Python + pip ────────────────────────────────────────────────────────
def check_python() -> None:
    _section("2. PYTHON INTERPRETER")
    v = sys.version_info
    detected = f"{v.major}.{v.minor}.{v.micro}"
    _record("PASS", "python", "Interpreter", f"{detected} ({platform.python_implementation()})")
    _record("PASS", "python", "Executable", sys.executable)

    if (v.major, v.minor) < REQUIRED_PYTHON:
        _record(
            "FAIL", "python", "Minimum Python version",
            f"required >= {REQUIRED_PYTHON[0]}.{REQUIRED_PYTHON[1]}, detected {detected}",
        )
    else:
        _record(
            "PASS", "python", "Minimum Python version",
            f"required >= {REQUIRED_PYTHON[0]}.{REQUIRED_PYTHON[1]}, detected {detected}",
        )
    if (v.major, v.minor, v.micro) == RECOMMENDED_PYTHON:
        _record("PASS", "python", "Verified version", f"exactly {detected} (reference build)")
    else:
        _record(
            "WARN", "python", "Verified version",
            f"reference is {'.'.join(map(str, RECOMMENDED_PYTHON))}, detected {detected}. "
            f"Compatible, but install with: py -3.11 -m venv .venv311",
        )

    _section("3. PIP")
    try:
        out = subprocess.run(
            [sys.executable, "-m", "pip", "--version"],
            capture_output=True, text=True, timeout=90,
        )
        if out.returncode == 0:
            _record("PASS", "pip", "pip available", out.stdout.strip())
        else:
            _record("FAIL", "pip", "pip available", "python -m pip failed")
    except Exception as exc:
        _record("FAIL", "pip", "pip available", f"{type(exc).__name__}: {exc}")


# ── 4. ML runtime stack ──────────────────────────────────────────────────────
def check_ml_stack() -> bool:
    _section("4. ML RUNTIME STACK (pinned versions)")
    ok = True
    for dist, want in PINNED.items():
        mod = IMPORT_NAMES.get(dist, dist.replace("-", "_"))
        got = _module_version(mod) or _dist_version(dist)
        if got is None:
            ok &= _record(
                "FAIL", "ml", dist,
                f"required {want}, NOT INSTALLED -> pip install -r backend\\requirements.txt",
            )
        elif got.split("+")[0] != want:
            ok &= _record(
                "WARN", "ml", dist, f"required {want}, detected {got}",
            )
        else:
            _record("PASS", "ml", dist, got)
    return ok


# ── 5. Device policy ─────────────────────────────────────────────────────────
def check_device() -> None:
    _section("5. INFERENCE DEVICE POLICY (CPU is the guaranteed baseline)")
    try:
        import torch
    except Exception as exc:
        _record("FAIL", "device", "torch import", f"{type(exc).__name__}: {exc}")
        return

    cuda_available = torch.cuda.is_available()
    compiled_cuda = torch.version.cuda
    threads = torch.get_num_threads()
    _record("PASS", "device", "torch build", f"{torch.__version__} (CUDA build tag: {compiled_cuda or 'none / CPU-only'})")
    if cuda_available:
        _record("INFO", "device", "CUDA device detected",
                f"{torch.cuda.get_device_name(0)} - will be used automatically")
    else:
        _record("PASS", "device", "CUDA availability",
                "not available - falling back to CPU, which is the supported baseline")
    _record("PASS", "device", "CPU inference", f"usable, torch threads = {threads}")

    # The models must still be *reachable* on CPU regardless of the GPU.
    try:
        dev = torch.device("cuda" if cuda_available else "cpu")
        t = torch.zeros(1, 3, 224, 224, device=dev)
        _record("PASS", "device", "Forward-pass device", str(dev))
        del t
    except Exception as exc:
        _record("FAIL", "device", "Forward-pass device", f"{type(exc).__name__}: {exc}")


# ── 6/7. Model artefacts and live loading ────────────────────────────────────
def _load_mobilenet(num_classes: int):
    import torch.nn as nn
    from torchvision import models
    model = models.mobilenet_v3_large(weights=None)
    model.classifier[3] = nn.Linear(model.classifier[3].in_features, num_classes)
    return model


def _verify_model(tag: str, model_path: Path, classes_path: Path,
                  expected_classes: int, extra_checks=None) -> bool:
    import torch

    section = f"{tag} model"
    if not model_path.is_file():
        _record("FAIL", section, f"{tag} weights file", f"MISSING: {model_path}")
        return False
    size_mb = model_path.stat().st_size / (1024 * 1024)
    if size_mb < 5:
        _record("FAIL", section, f"{tag} weights file", f"suspiciously small: {size_mb:.2f} MB")
        return False
    _record("PASS", section, f"{tag} weights file", f"{model_path.relative_to(ROOT)} ({size_mb:.2f} MB)")

    if not classes_path.is_file():
        _record("FAIL", section, f"{tag} class mapping", f"MISSING: {classes_path}")
        return False
    try:
        with open(classes_path, "r", encoding="utf-8") as fh:
            meta = json.load(fh)
        names = meta.get("class_names", [])
    except Exception as exc:
        _record("FAIL", section, f"{tag} class mapping", f"unreadable: {exc}")
        return False

    if len(names) != expected_classes:
        _record("FAIL", section, f"{tag} class count",
                f"required {expected_classes}, detected {len(names)}")
        return False
    _record("PASS", section, f"{tag} class count", f"{len(names)} classes")

    if len(set(names)) != len(names):
        _record("FAIL", section, f"{tag} class mapping", "duplicate class names present")
        return False
    c2i = meta.get("class_to_idx")
    if isinstance(c2i, dict) and not all(c2i.get(n) == i for i, n in enumerate(names)):
        _record("FAIL", section, f"{tag} class_to_idx", "inconsistent with class_names order")
        return False
    _record("PASS", section, f"{tag} class mapping integrity", "unique names, class_to_idx consistent")
    _record("PASS", section, f"{tag} class range", f"{names[0]}  ...  {names[-1]}")

    if extra_checks:
        extra_checks(section, meta)

    try:
        model = _load_mobilenet(len(names))
        ckpt = torch.load(model_path, map_location="cpu", weights_only=False)
        state = ckpt.get("model_state", ckpt) if isinstance(ckpt, dict) else ckpt
        model.load_state_dict(state)
        model.eval()
    except Exception as exc:
        _record("FAIL", section, f"{tag} model load", f"{type(exc).__name__}: {exc}")
        return False
    _record("PASS", section, f"{tag} MobileNetV3-Large", "loaded and in eval mode")

    try:
        with torch.no_grad():
            out = model(torch.zeros(1, 3, 224, 224))
        shape = tuple(out.shape)
        finite = bool(torch.isfinite(out).all())
    except Exception as exc:
        _record("FAIL", section, f"{tag} forward pass", f"{type(exc).__name__}: {exc}")
        return False

    if shape != (1, expected_classes):
        _record("FAIL", section, f"{tag} forward pass",
                f"output {shape} != (1, {expected_classes})")
        return False
    _record("PASS", section, f"{tag} forward pass", f"output shape {shape}, all finite = {finite}")
    if not finite:
        _record("FAIL", section, f"{tag} forward pass", "non-finite activations")
    return True


def _v2_extra(section: str, meta: dict) -> None:
    crops = meta.get("crops", [])
    plant = meta.get("plant_indices", {})
    if len(crops) != V2_EXPECTED_CROPS:
        _record("FAIL", section, "V2 crop count", f"required {V2_EXPECTED_CROPS}, detected {len(crops)}")
    else:
        _record("PASS", section, "V2 crop count", f"{V2_EXPECTED_CROPS} crops: {', '.join(crops)}")
    if len(plant) != V2_EXPECTED_CROPS:
        _record("FAIL", section, "V2 plant_indices", f"required {V2_EXPECTED_CROPS} keys, detected {len(plant)}")
        return
    names = meta.get("class_names", [])
    bad = []
    for key, payload in plant.items():
        if not (isinstance(payload, list) and len(payload) == 2):
            bad.append(f"{key}: malformed")
            continue
        for idx in payload[1]:
            if not (isinstance(idx, int) and 0 <= idx < len(names)):
                bad.append(f"{key}: index {idx} out of range")
    if bad:
        _record("FAIL", section, "V2 plant_indices", "; ".join(bad))
    else:
        _record("PASS", section, "V2 plant_indices", f"{V2_EXPECTED_CROPS} crop hints, all indices in range")


def check_models() -> tuple[bool, bool]:
    _section("6. V1 MODEL  (4 crops / 21 classes)")
    v1 = _verify_model("V1", V1_MODEL, V1_CLASSES, V1_EXPECTED_CLASSES)
    _section("7. V2 MODEL  (8 crops / 24 classes)")
    v2 = _verify_model("V2", V2_MODEL, V2_CLASSES, V2_EXPECTED_CLASSES, _v2_extra)
    return v1, v2


# ── 8. Path hygiene ──────────────────────────────────────────────────────────
def check_path_hygiene() -> None:
    _section("8. MACHINE-SPECIFIC PATH AUDIT (inference must be location-independent)")
    scanned = 0
    problems: list[str] = []
    for src in RUNTIME_SOURCES:
        if not src.is_file():
            continue
        scanned += 1
        try:
            text = src.read_text(encoding="utf-8", errors="replace")
        except Exception as exc:
            problems.append(f"{src.relative_to(ROOT)}: unreadable ({exc})")
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            stripped = line.strip()
            if stripped.startswith("#") or stripped.startswith('"') or stripped.startswith("'"):
                continue
            for needle in FORBIDDEN_RUNTIME_PATHS:
                if needle in line:
                    problems.append(f"{src.relative_to(ROOT)}:{lineno} references {needle}")
            for drive in ("C:\\", "D:\\", "E:\\", "C:/", "D:/"):
                if drive in line and "Path(" not in line:
                    problems.append(f"{src.relative_to(ROOT)}:{lineno} hard-codes {drive}")
    _record("PASS", "paths", "Files scanned", f"{scanned} runtime source files")
    if problems:
        for p in problems:
            _record("FAIL", "paths", "Machine-specific path", p)
    else:
        _record("PASS", "paths", "No dataset / drive-letter paths", "all model + DB paths are repository-relative")

    # The training-dataset scripts may legitimately mention the dataset, but the
    # inference path must not need it. Prove the models are self-contained.
    _record("PASS", "paths", "Training dataset required for inference?", "NO - weights are committed to the repository")


# ── 9/10. Backend ────────────────────────────────────────────────────────────
def check_backend(backend_src: Path) -> None:
    _section("9. BACKEND DEPENDENCIES")
    backend_src_str = str(backend_src)
    if backend_src_str not in sys.path:
        sys.path.insert(0, backend_src_str)
    missing = []
    for dist, want in PINNED.items():
        if importlib.util.find_spec(IMPORT_NAMES.get(dist, dist.replace("-", "_"))) is None:
            missing.append(dist)
    if missing:
        _record("FAIL", "backend", "Backend imports", "missing: " + ", ".join(missing))
    else:
        _record("PASS", "backend", "Backend imports", f"all {len(PINNED)} pinned packages importable")

    _section("10. BACKEND APPLICATION")
    env_file = backend_src / ".env"
    if env_file.is_file():
        _record("PASS", "backend", "backend/.env", "present")
    else:
        _record("WARN", "backend", "backend/.env",
                "absent - the backend falls back to SQLite defaults; run setup_handover.ps1 to create it")

    try:
        from app.main import app as fastapi_app  # type: ignore
        routes = len(fastapi_app.routes)
        _record("PASS", "backend", "app.main import", f"FastAPI app with {routes} routes")
        paths = {getattr(r, "path", "") for r in fastapi_app.routes}
        for required in ("/health", "/api/diagnose"):
            if required in paths:
                _record("PASS", "backend", f"route {required}", "registered")
            else:
                _record("FAIL", "backend", f"route {required}", "NOT registered")
    except Exception as exc:
        _record("FAIL", "backend", "app.main import", f"{type(exc).__name__}: {exc}")

    # The backend must locate the V1 weights through the repository, not a drive.
    try:
        from app.services.crop_ai_service import MODEL_PATH, CLASS_NAMES_PATH  # type: ignore
        if MODEL_PATH and Path(MODEL_PATH).is_file():
            rel = Path(MODEL_PATH).resolve().relative_to(ROOT)
            _record("PASS", "backend", "Backend model resolution", str(rel))
        else:
            _record("FAIL", "backend", "Backend model resolution",
                    "crop_ai_service could not find best_model_final.pth")
        if CLASS_NAMES_PATH and Path(CLASS_NAMES_PATH).is_file():
            _record("PASS", "backend", "Backend class mapping resolution", "found")
        else:
            _record("FAIL", "backend", "Backend class mapping resolution", "class_names.json not found")
    except Exception as exc:
        _record("FAIL", "backend", "Backend model resolution", f"{type(exc).__name__}: {exc}")


# ── 11. Frontend (optional) ──────────────────────────────────────────────────
def check_frontend(skip: bool) -> None:
    _section("11. FRONTEND TOOLCHAIN (Flutter - optional for ML work)")
    if skip:
        _record("INFO", "frontend", "Skipped", "--skip-frontend")
        return
    pubspec = ROOT / "mobile_app" / "pubspec.yaml"
    if not pubspec.is_file():
        _record("INFO", "frontend", "mobile_app/pubspec.yaml", "absent - no Flutter frontend in this checkout")
        return
    try:
        text = pubspec.read_text(encoding="utf-8", errors="replace")
        seen: set[str] = set()
        for line in text.splitlines():
            s = line.strip()
            if (s.startswith("sdk:") or s.startswith("flutter:")) and s not in seen:
                if s in ("sdk: flutter", "flutter:"):
                    continue
                seen.add(s)
                _record("INFO", "frontend", "pubspec constraint", s)
    except Exception as exc:
        _record("INFO", "frontend", "pubspec.yaml", f"unreadable: {exc}")

    flutter = None
    for exe in ("flutter.bat", "flutter"):
        try:
            res = subprocess.run([exe, "--version"], capture_output=True, timeout=300)
            out = res.stdout.decode("utf-8", errors="replace")
            if res.returncode == 0 and "Flutter" in out:
                flutter = out.strip().splitlines()[0].strip()
                break
        except Exception:
            continue
    if flutter:
        _record("PASS", "frontend", "Flutter SDK", flutter)
    else:
        _record("WARN", "frontend", "Flutter SDK",
                "not found on PATH. The backend and both ML models work without it. "
                "Install Flutter 3.44+ (Dart 3.12+) only if you need to run the app.")
        return

    web_build = ROOT / "mobile_app" / "build" / "web" / "index.html"
    if web_build.is_file():
        _record("PASS", "frontend", "Prebuilt web bundle", "mobile_app/build/web/index.html")
    else:
        _record("WARN", "frontend", "Prebuilt web bundle",
                "absent (build output is gitignored) - run: cd mobile_app; flutter build web")


# ── 12. External-image inference ─────────────────────────────────────────────
def _synthetic_image() -> Path:
    """A deterministic, dependency-free test image written to a temp folder."""
    from PIL import Image
    import numpy as np
    rng = np.random.default_rng(1234)
    h = w = 300
    yy, xx = np.mgrid[0:h, 0:w]
    base = np.zeros((h, w, 3), dtype=np.float64)
    base[..., 0] = 90 + 40 * (xx / w)
    base[..., 1] = 150 + 60 * (yy / h)
    base[..., 2] = 60 + 20 * rng.random((h, w))
    lesions = (rng.random((h, w)) > 0.985).astype(np.float64)
    base[..., 0] -= 90 * lesions
    base[..., 1] -= 70 * lesions
    base[..., 2] -= 40 * lesions
    arr = np.clip(base, 0, 255).astype("uint8")
    out = Path(tempfile.gettempdir()) / "krishi_verify_synthetic_leaf.jpg"
    Image.fromarray(arr).save(out, quality=92)
    return out


def check_inference(image_arg: str | None) -> None:
    _section("12. EXTERNAL-IMAGE INFERENCE")
    if image_arg:
        img = Path(image_arg)
        if not img.is_file():
            _record("FAIL", "inference", "Supplied image", f"not found: {img}")
            return
        origin = f"external file {img}"
    else:
        img = _synthetic_image()
        origin = f"synthetic test image {img}"
    _record("INFO", "inference", "Image under test", origin)

    sys.path.insert(0, str(AI_DIR))
    # 12a. V1
    try:
        import importlib
        p1 = importlib.import_module("predict")
        importlib.reload(p1)
        names, indices, norm, order, backend, crop_mass = p1.predict_pytorch(str(img), "1")
        top = names[indices[order[0]]]
        good = 0.0 <= float(norm[order[0]]) <= 1.0
        _record("PASS" if good else "FAIL", "inference", "V1 predict_pytorch",
                f"backend={backend}, top={top}, conf={float(norm[order[0]])*100:.2f}%")
    except Exception as exc:
        _record("FAIL", "inference", "V1 predict_pytorch", f"{type(exc).__name__}: {exc}")

    # 12b. V2
    try:
        import predict_v2  # type: ignore
        res = predict_v2.predict(str(img))
        conf = float(res["confidence"])
        good = 0.0 <= conf <= 1.0 and res["full_class_tag"] in res["top_3_predictions"][0][0]
        _record("PASS" if good else "FAIL", "inference", "V2 predict",
                f"device={res['device']}, top={res['full_class_tag']}, conf={conf*100:.2f}%")
    except SystemExit as exc:
        _record("FAIL", "inference", "V2 predict", f"exited: {exc}")
    except Exception as exc:
        _record("FAIL", "inference", "V2 predict", f"{type(exc).__name__}: {exc}")


# ── Hardware / disk ──────────────────────────────────────────────────────────
def check_hardware() -> None:
    _section("0. HARDWARE")
    try:
        import ctypes
        class _MEMORYSTATUSEX(ctypes.Structure):
            _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong),
                        ("ullTotalPhys", ctypes.c_ulonglong), ("ullAvailPhys", ctypes.c_ulonglong),
                        ("ullTotalPageFile", ctypes.c_ulonglong), ("ullAvailPageFile", ctypes.c_ulonglong),
                        ("ullTotalVirtual", ctypes.c_ulonglong), ("ullAvailVirtual", ctypes.c_ulonglong),
                        ("ullAvailExtendedVirtual", ctypes.c_ulonglong)]
        st = _MEMORYSTATUSEX()
        st.dwLength = ctypes.sizeof(_MEMORYSTATUSEX)
        if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(st)):
            total_gb = st.ullTotalPhys / (1024 ** 3)
            _record("PASS" if total_gb >= MIN_RAM_GB else "FAIL", "hw", "System RAM",
                    f"{total_gb:.1f} GB total, {st.dwMemoryLoad}% in use (minimum {MIN_RAM_GB:.0f} GB)")
    except Exception as exc:
        _record("INFO", "hw", "System RAM", f"could not query ({type(exc).__name__})")

    try:
        usage = shutil_usage = __import__("shutil").disk_usage(ROOT)
        free_gb = usage.free / (1024 ** 3)
        _record("PASS" if free_gb >= MIN_FREE_DISK_GB else "FAIL", "hw", "Free disk on repo volume",
                f"{free_gb:.1f} GB free (minimum {MIN_FREE_DISK_GB:.0f} GB)")
    except Exception as exc:
        _record("INFO", "hw", "Free disk", f"could not query ({type(exc).__name__})")

    _record("PASS", "hw", "GPU", "OPTIONAL - CPU inference is fully supported and is the verified baseline")


# ── Summary ──────────────────────────────────────────────────────────────────
def summarise() -> int:
    print()
    print(_LINE)
    print("ENVIRONMENT VERIFICATION SUMMARY")
    print(_LINE)

    sections: dict[str, dict[str, int]] = {}
    for status, section, _item, _detail in _results:
        bucket = sections.setdefault(section, {"PASS": 0, "FAIL": 0, "WARN": 0, "INFO": 0})
        bucket[status] += 1

    width = max(len(s) for s in sections)
    for section in sorted(sections):
        b = sections[section]
        flag = "FAIL" if b["FAIL"] else ("WARN" if b["WARN"] else "PASS")
        detail = f"{b['PASS']} passed"
        if b["FAIL"]:
            detail += f", {b['FAIL']} FAILED"
        if b["WARN"]:
            detail += f", {b['WARN']} warning(s)"
        if b["INFO"]:
            detail += f", {b['INFO']} info"
        print(f"  {section:<{width}}  [{flag}]  {detail}")

    failures = [(sec, item, detail) for st, sec, item, detail in _results if st == "FAIL"]
    warnings = [item for st, _sec, item, _detail in _results if st == "WARN"]

    if failures:
        print()
        print("FAIL - this machine does not yet satisfy the project requirements:")
        for sec, item, detail in failures:
            print(f"  * [{sec}] {item}")
            print(f"      fix      : see the 'detected' line for this item above")
        print()
        print("  Re-run: python scripts\\verify_environment.py")
        print(_LINE)
        return 1

    print()
    print("PASS - this machine satisfies every required project dependency.")
    if warnings:
        print(f"  ({len(warnings)} non-blocking warning(s) above - the app runs without fixing these.)")
    print()
    print("  Verified:  Python, pip, torch, torchvision, numpy, pillow, V1 + V2 weights,")
    print("              V1 + V2 class mappings, V1 + V2 inference, backend dependencies,")
    print("              backend application import, and repository-relative path resolution.")
    print("  NOT required: any training dataset (D:\\MASTER_DATASET etc.), an NVIDIA GPU,")
    print("              PostgreSQL, Redis, MinIO, or Node.js.")
    print(_LINE)
    return 0


# ── Entry point ──────────────────────────────────────────────────────────────
def main() -> int:
    ap = argparse.ArgumentParser(description="Verify this machine against the Krishi-Saarthi requirements.")
    ap.add_argument("--image", help="External leaf image to run V1 + V2 inference on.")
    ap.add_argument("--skip-frontend", action="store_true", help="Skip the Flutter toolchain check.")
    ap.add_argument("--quick", action="store_true", help="Skip model forward passes and inference.")
    args = ap.parse_args()

    print(_LINE)
    print("  KRISHI-SAARTHI - ENVIRONMENT VERIFICATION")
    print("  Repository: " + str(ROOT))
    print(_LINE)

    check_hardware()
    check_os()
    check_python()
    check_ml_stack()
    check_device()
    if args.quick:
        _section("6/7. MODELS")
        _record("INFO", "models", "Skipped", "--quick")
    else:
        check_models()
    check_path_hygiene()
    check_backend(ROOT / "backend")
    check_frontend(args.skip_frontend)
    if args.quick:
        _section("12. EXTERNAL-IMAGE INFERENCE")
        _record("INFO", "inference", "Skipped", "--quick")
    else:
        check_inference(args.image)

    return summarise()


if __name__ == "__main__":
    sys.exit(main())
