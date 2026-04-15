#!/usr/bin/env bash
# PanLL Desktop Launcher - Smart detection and browser opening

set -euo pipefail

PORT=8080
URL="http://localhost:$PORT/public/"

echo "🔍 Checking PanLL status..."

if curl -sf "$URL" >/dev/null 2>&1; then
    echo "✅ PanLL is running on port $PORT"
    xdg-open "$URL"
else
    echo "❌ PanLL is not running on port $PORT"
    konsole --title "PanLL Not Running" -e bash -c "
        echo 'PanLL is not running on port 8080'
        echo
        echo 'To start PanLL:'
        echo '  1. Open terminal'
        echo '  2. cd /var/mnt/eclipse/repos/panll'
        echo '  3. just serve'
        echo
        echo 'After starting, click the desktop icon again.'
        read -p 'Press Enter to close...'
    "
fi