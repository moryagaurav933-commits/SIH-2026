#!/bin/bash

# Krishi-Saarthi — Service Shutdown Script
# Cleanly stops all running services (Backend, Flutter, Docker)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Stopping Krishi-Saarthi Services...${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}\n"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

STOPPED_COUNT=0

# ─── Stop Flutter App ───
if [ -f "flutter.pid" ]; then
    FLUTTER_PID=$(cat flutter.pid)
    if ps -p $FLUTTER_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Stopping Flutter App (PID: $FLUTTER_PID)...${NC}"
        kill $FLUTTER_PID 2>/dev/null || true
        sleep 1
        if ps -p $FLUTTER_PID > /dev/null 2>&1; then
            kill -9 $FLUTTER_PID 2>/dev/null || true
        fi
        echo -e "${GREEN}✅ Flutter App stopped${NC}"
        STOPPED_COUNT=$((STOPPED_COUNT + 1))
    fi
    rm -f flutter.pid
fi

# ─── Stop Backend Server ───
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Stopping FastAPI Backend (PID: $BACKEND_PID)...${NC}"
        kill $BACKEND_PID 2>/dev/null || true
        sleep 1
        if ps -p $BACKEND_PID > /dev/null 2>&1; then
            kill -9 $BACKEND_PID 2>/dev/null || true
        fi
        echo -e "${GREEN}✅ Backend stopped${NC}"
        STOPPED_COUNT=$((STOPPED_COUNT + 1))
    fi
    rm -f backend.pid
fi

# ─── Kill any remaining processes ───
echo -e "${YELLOW}Checking for remaining processes...${NC}"

# Kill uvicorn processes
UVICORN_PIDS=$(pgrep -f "uvicorn app.main:app" 2>/dev/null || true)
if [ ! -z "$UVICORN_PIDS" ]; then
    echo -e "${YELLOW}Stopping remaining uvicorn processes...${NC}"
    echo "$UVICORN_PIDS" | xargs kill 2>/dev/null || true
    sleep 1
    echo "$UVICORN_PIDS" | xargs kill -9 2>/dev/null || true
    echo -e "${GREEN}✅ Uvicorn processes stopped${NC}"
    STOPPED_COUNT=$((STOPPED_COUNT + 1))
fi

# Kill flutter processes
FLUTTER_PIDS=$(pgrep -f "flutter run" 2>/dev/null || true)
if [ ! -z "$FLUTTER_PIDS" ]; then
    echo -e "${YELLOW}Stopping remaining flutter processes...${NC}"
    echo "$FLUTTER_PIDS" | xargs kill 2>/dev/null || true
    sleep 1
    echo "$FLUTTER_PIDS" | xargs kill -9 2>/dev/null || true
    echo -e "${GREEN}✅ Flutter processes stopped${NC}"
    STOPPED_COUNT=$((STOPPED_COUNT + 1))
fi

# ─── Stop Docker Containers (if any) ───
if command -v docker &> /dev/null; then
    if [ -f "infrastructure/docker/docker-compose.dev.yml" ]; then
        RUNNING_CONTAINERS=$(docker compose -f infrastructure/docker/docker-compose.dev.yml ps -q 2>/dev/null || true)
        if [ ! -z "$RUNNING_CONTAINERS" ]; then
            echo -e "${YELLOW}Stopping Docker containers...${NC}"
            docker compose -f infrastructure/docker/docker-compose.dev.yml down 2>/dev/null || true
            echo -e "${GREEN}✅ Docker containers stopped${NC}"
            STOPPED_COUNT=$((STOPPED_COUNT + 1))
        fi
    fi
fi

# ─── Summary ───
echo -e "\n${GREEN}═══════════════════════════════════════════════════════${NC}"
if [ $STOPPED_COUNT -eq 0 ]; then
    echo -e "${YELLOW}  No running services found${NC}"
else
    echo -e "${GREEN}  ✅ Successfully stopped $STOPPED_COUNT service(s)${NC}"
fi
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}\n"

# Clean up log files
if [ -f "backend.log" ]; then
    echo -e "${YELLOW}Backend logs preserved in: backend.log${NC}"
fi
