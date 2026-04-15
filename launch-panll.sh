#!/usr/bin/env bash
# PanLL Launcher - Starts the service and opens browser

set -euo pipefail

PANLL_DIR="/var/mnt/eclipse/repos/panll"
PORT=8080
URL="http://localhost:$PORT/public/"

echo "🔍 Checking if PanLL is running on port $PORT..."

if curl -sf "$URL" >/dev/null 2>&1; then
    echo "✅ PanLL is already running"
else
    echo "⚠️  PanLL not running. Starting it now..."
    cd "$PANLL_DIR"
    
    # Start PanLL in background
    nohup just serve > /tmp/panll.log 2>&1 &
    sleep 3
    
    # Check if it started
    if curl -sf "$URL" >/dev/null 2>&1; then
        echo "✅ PanLL started successfully"
    else
        echo "❌ Failed to start PanLL. Check /tmp/panll.log"
        echo "Last 10 lines of log:"
        tail -10 /tmp/panll.log
        exit 1
    fi
fi

# Open browser
echo "🚀 Opening PanLL in browser..."
xdg-open "$URL"

echo "🎉 PanLL is ready!"
