#!/usr/bin/env bash
# PanLL eNSAID — Quick-start script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Avoid noisy caniuse-lite age warnings during desktop launches.
export BROWSERSLIST_IGNORE_OLD_DATA=1

# Ensure just is installed
if ! command -v just &>/dev/null; then
    echo "Error: 'just' is not installed but is required for this project."
    echo "Please install it: https://just.systems/man/en/chapter_4.html"
    exit 1
fi

# Default to 'dev' (Tauri mode) if no arguments provided
RECIPE=${1:-dev}

exec just "$RECIPE"
