#!/bin/bash
# ============================================
# SkyNetCMS - Site Build Script
# ============================================

set -e

echo "[INFO] Running site build..."

cd /data/repo

if [ -f "package.json" ]; then
    npm run build
    echo "[OK] Build completed"
else
    # Fallback for repos without package.json
    if [ -d "src" ]; then
        cp -r src/* dist/ 2>/dev/null || true
        echo "[OK] Copied src/ to dist/ (no package.json)"
    fi
fi
