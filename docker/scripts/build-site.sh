#!/bin/bash
# ============================================
# SkyNetCMS - Site Build Script
# ============================================
# Placeholder for M4: Site build pipeline
# ============================================

echo "[INFO] Build: Not implemented yet (M4)"

# For now, just copy src to dist
if [ -d "/data/repo/src" ]; then
    cp -r /data/repo/src/* /data/repo/dist/ 2>/dev/null || true
    echo "[OK] Copied src/ to dist/"
fi
