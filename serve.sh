#!/bin/bash
# Quick dev server for testing panll UI

echo "🚀 Starting PanLL dev server..."
echo ""
echo "📍 Server: http://localhost:8000"
echo "📂 Serving: public/"
echo ""
echo "Press Ctrl+C to stop"
echo ""

cd public && python3 -m http.server 8000
