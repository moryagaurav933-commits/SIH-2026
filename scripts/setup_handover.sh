#!/usr/bin/env bash
# ==============================================================================
# Krishi-Saarthi — Handover Developer Environment Setup (Linux / macOS / WSL)
# Sets up Python virtualenv, installs required dependencies, and verifies models.
# ==============================================================================

set -eo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}  KRISHI-SAARTHI - DEVELOPER HANDOVER SETUP [V1 + V2 MODELS]      ${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "Project Root: $ROOT_DIR\n"

# 1. Check Model Checkpoints
echo -e "${CYAN}[1/5] Checking Required Model Checkpoints...${NC}"
V1_MODEL="$ROOT_DIR/ai_module/best_model_final.pth"
V2_MODEL="$ROOT_DIR/ai_module/models/v2/best_model_v2.pth"
V1_CLASSES="$ROOT_DIR/ai_module/class_names.json"
V2_CLASSES="$ROOT_DIR/ai_module/models/v2/class_names_v2.json"

MISSING=0
for f in "$V1_MODEL" "$V2_MODEL" "$V1_CLASSES" "$V2_CLASSES"; do
    if [ ! -f "$f" ]; then
        echo -e "${RED}[FAIL] Missing required model file: $f${NC}"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo -e "${YELLOW}Please ensure you have checked out the branch: handover/ml-v2-integration${NC}"
    exit 1
fi

echo -e "   ${GREEN}[PASS]${NC} V1 Model present: $(basename "$V1_MODEL")"
echo -e "   ${GREEN}[PASS]${NC} V2 Model present: $(basename "$V2_MODEL")"

# 2. Check Python 3.10+
echo -e "\n${CYAN}[2/5] Checking Python 3.10+...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[FAIL] python3 not found. Please install Python 3.10+${NC}"
    exit 1
fi
echo -e "   ${GREEN}[PASS]${NC} Found Python: $(python3 --version)"

# 3. Virtual Environment
echo -e "\n${CYAN}[3/5] Setting up Virtual Environment (.venv311)...${NC}"
VENV_DIR="$ROOT_DIR/.venv311"
if [ ! -d "$VENV_DIR" ]; then
    echo "   Creating virtual environment at $VENV_DIR ..."
    python3 -m venv "$VENV_DIR"
    echo -e "   ${GREEN}Virtual environment created.${NC}"
else
    echo "   Existing virtual environment detected at $VENV_DIR."
fi
PYTHON_BIN="$VENV_DIR/bin/python"

# 4. Dependencies
echo -e "\n${CYAN}[4/5] Checking / Installing Dependencies...${NC}"
REQS="$ROOT_DIR/backend/requirements.txt"
if [ "$1" == "--skip-pip" ]; then
    echo "   Skipping pip install as requested (--skip-pip)."
elif [ -f "$REQS" ]; then
    echo "   Upgrading pip and installing requirements from $REQS ..."
    "$PYTHON_BIN" -m pip install --upgrade pip --quiet
    "$PYTHON_BIN" -m pip install -r "$REQS" --quiet
    echo -e "   ${GREEN}Dependencies up to date.${NC}"
fi

# Auto-create backend/.env if missing
if [ ! -f "$ROOT_DIR/backend/.env" ] && [ -f "$ROOT_DIR/backend/.env.example" ]; then
    cp "$ROOT_DIR/backend/.env.example" "$ROOT_DIR/backend/.env"
    echo "   Created backend/.env from template."
fi

# 5. Run Model Verification
echo -e "\n${CYAN}[5/5] Running Model Verification...${NC}"
"$PYTHON_BIN" "$ROOT_DIR/scripts/verify_models.py"

echo -e "\n${GREEN}==================================================================${NC}"
echo -e "${GREEN}  SETUP COMPLETE! Environment is ready for ML V2 integration.      ${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "Next steps:"
echo -e "  1. Read START_HERE.md and HANDOVER.md"
echo -e "  2. Test V1 prediction:  .venv311/bin/python ai_module/predict.py <image>"
echo -e "  3. Test V2 prediction:  .venv311/bin/python ai_module/predict_v2.py <image> [crop]"
echo -e "  4. Start full app:      ./run_app.sh\n"
