#!/bin/bash

# ==============================================================================
# Krishi-Saarthi (कृषि-सारथी) — Master Unified Application Launcher
# Starts FastAPI AI Backend + Flutter Mobile/Desktop/Web App
# ==============================================================================

set -eo pipefail

# Ensure Homebrew and standard system paths are in PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
MOBILE_APP_DIR="$PROJECT_ROOT/mobile_app"

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               🌾 Krishi-Saarthi | कृषि-सारथी Unified App             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"

# Parse Mode
MODE="web"
if [[ "$1" == "--mac" || "$1" == "--macos" || "$1" == "-m" ]]; then
    MODE="macos"
elif [[ "$1" == "--backend" || "$1" == "-b" ]]; then
    MODE="backend"
elif [[ "$1" == "--test" || "$1" == "-t" ]]; then
    MODE="test"
elif [[ "$1" == "--stop" ]]; then
    MODE="stop"
elif [[ "$1" == "--clean" ]]; then
    MODE="clean"
fi

# ─── Stop Command ───
if [[ "$MODE" == "stop" ]]; then
    echo -e "${YELLOW}Stopping all running Krishi-Saarthi processes...${NC}"
    if [ -f "$PROJECT_ROOT/stop_all.sh" ]; then
        bash "$PROJECT_ROOT/stop_all.sh"
    else
        pkill -f "uvicorn app.main:app" 2>/dev/null || true
        pkill -f "flutter_tools" 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ All services stopped.${NC}"
    exit 0
fi

# ─── Clean Command ───
if [[ "$MODE" == "clean" ]]; then
    echo -e "${YELLOW}Cleaning Flutter and Python caches...${NC}"
    cd "$MOBILE_APP_DIR" && flutter clean
    find "$PROJECT_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "$PROJECT_ROOT" -name "*.pyc" -delete 2>/dev/null || true
    echo -e "${GREEN}✅ Project cleaned successfully.${NC}"
    exit 0
fi

# ─── Step 1: Check Environment Prerequisites ───
echo -e "\n${CYAN}[1/4] Checking Prerequisites...${NC}"

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ python3 not found. Please install Python 3.10+${NC}"
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter SDK not found in PATH.${NC}"
    echo -e "${YELLOW}   Expected location: /opt/homebrew/bin/flutter${NC}"
    exit 1
fi

echo -e "   ${GREEN}✓${NC} Python:  $(python3 --version)"
echo -e "   ${GREEN}✓${NC} Flutter: $(flutter --version | head -n 1)"

# ─── Step 2: Setup & Verify Backend Environment ───
echo -e "\n${CYAN}[2/4] Verifying Backend & Database...${NC}"

cd "$BACKEND_DIR"

if [ ! -d "venv" ]; then
    echo -e "${BLUE}   Creating Python virtual environment...${NC}"
    python3 -m venv venv
    venv/bin/pip install -q --upgrade pip
    venv/bin/pip install -q -r requirements.txt
elif ! venv/bin/python3 -c "import fastapi, torch, sqlalchemy, aiosqlite" 2>/dev/null; then
    echo -e "${BLUE}   Installing missing dependencies in venv...${NC}"
    venv/bin/pip install -q -r requirements.txt
fi

# Ensure database tables and disease knowledge base exist
venv/bin/python3 scripts/init_db.py > /dev/null 2>&1 || true
echo -e "   ${GREEN}✓${NC} Backend environment and database verified"

# ─── Test Mode ───
if [[ "$MODE" == "test" ]]; then
    echo -e "\n${CYAN}[3/4] Running Full Test Suite...${NC}"
    
    echo -e "\n${BOLD}--- 1. Backend AI & API Pytest ---${NC}"
    cd "$BACKEND_DIR"
    venv/bin/pytest tests/ -v
    
    echo -e "\n${BOLD}--- 2. Flutter Code Analysis ---${NC}"
    cd "$MOBILE_APP_DIR"
    flutter analyze
    
    echo -e "\n${BOLD}--- 3. Flutter Unit & Widget Tests ---${NC}"
    flutter test
    
    echo -e "\n${GREEN}══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   ✅ All Test Suites Completed Successfully!${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════════${NC}"
    exit 0
fi

# ─── Step 3: Start FastAPI Backend ───
echo -e "\n${CYAN}[3/4] Starting FastAPI AI Backend...${NC}"

# Check if backend is already running
if curl -s http://127.0.0.1:8000/docs > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓${NC} Backend already running on http://127.0.0.1:8000"
else
    pkill -f "uvicorn app.main:app" 2>/dev/null || true
    nohup "$BACKEND_DIR/venv/bin/python3" -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload > "$PROJECT_ROOT/backend.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$PROJECT_ROOT/backend.pid"

    # Wait for backend to be ready
    BACKEND_READY=false
    for i in {1..20}; do
        if curl -s http://127.0.0.1:8000/docs > /dev/null 2>&1; then
            BACKEND_READY=true
            break
        fi
        sleep 0.5
    done

    if [ "$BACKEND_READY" = true ]; then
        echo -e "   ${GREEN}✓${NC} Backend started (PID: $BACKEND_PID)"
    else
        echo -e "${RED}❌ Backend failed to start. Last log lines:${NC}"
        tail -n 15 "$PROJECT_ROOT/backend.log"
        exit 1
    fi
fi

echo -e "   ${BLUE}• API Docs:${NC}  http://127.0.0.1:8000/docs"
echo -e "   ${BLUE}• AI Endpoint:${NC} http://127.0.0.1:8000/api/v1/diagnose"

if [[ "$MODE" == "backend" ]]; then
    echo -e "\n${GREEN}✅ Backend is live! Tail logs with: tail -f backend.log${NC}"
    echo -e "${YELLOW}Press Ctrl+C or run ./run_app.sh --stop to shutdown.${NC}"
    tail -f "$PROJECT_ROOT/backend.log"
    exit 0
fi

# ─── Step 4: Launch Flutter Mobile / Desktop / Web App ───
echo -e "\n${CYAN}[4/4] Launching Flutter Application...${NC}"
cd "$MOBILE_APP_DIR"

if [[ "$MODE" == "macos" ]]; then
    echo -e "${BLUE}🚀 Starting macOS Desktop Application natively...${NC}"
    flutter run -d macos
elif [[ "$MODE" == "web" ]]; then
    echo -e "${BLUE}🚀 Starting Flutter Web in Google Chrome (Port 3000)...${NC}"
    echo -e "${YELLOW}   Hot Reload: Press 'r' in this terminal${NC}"
    echo -e "${YELLOW}   Hot Restart: Press 'R' in this terminal${NC}"
    flutter run -d chrome --web-port 3000
fi
