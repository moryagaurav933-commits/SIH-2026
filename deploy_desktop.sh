#!/bin/bash
# ==============================================================================
# Krishi-Saarthi (कृषि-सारथी) — macOS Desktop Launcher & Deployer
# Usage: ./deploy_desktop.sh
# ==============================================================================

set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$PROJECT_ROOT/SIH-2026-fresh" ]; then
    ROOT_DIR="$PROJECT_ROOT/SIH-2026-fresh"
else
    ROOT_DIR="$PROJECT_ROOT"
fi

echo "🌾 Starting Krishi-Saarthi macOS Desktop App..."
exec bash "$ROOT_DIR/run_app.sh" --macos
