#!/usr/bin/env bash
# PanLL eNSAID — Quick-start script

set -euo pipefail

# Ensure just is installed
if ! command -v just &>/dev/null; then
    echo "Error: 'just' is not installed but is required for this project."
    echo "Please install it: https://just.systems/man/en/chapter_4.html"
    exit 1
fi

# Default to 'dev' (Tauri mode) if no arguments provided
RECIPE=${1:-dev}

exec just "$RECIPE"
