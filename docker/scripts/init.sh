#!/bin/bash
set -e

echo "============================================"
echo "  SkyNetCMS - Starting Up"
echo "============================================"

# ----------------------------------------
# 1. Validate required environment variables
# ----------------------------------------
if [ -z "$ADMIN_USER" ]; then
    echo "ERROR: ADMIN_USER environment variable is required"
    exit 1
fi

if [ -z "$ADMIN_PASS" ]; then
    echo "ERROR: ADMIN_PASS environment variable is required"
    exit 1
fi

echo "[OK] Environment variables validated"

# ----------------------------------------
# 2. Initialize data directory
# ----------------------------------------
mkdir -p /data/repo/src /data/repo/dist

# ----------------------------------------
# 3. First-run: Copy template if repo is empty
# ----------------------------------------
if [ ! -f "/data/repo/src/index.html" ]; then
    echo "[INFO] First run detected - initializing from template..."
    cp -r /opt/templates/default/* /data/repo/
    
    # Initialize Git repository
    cd /data/repo
    git init
    git config user.email "skynetcms@local"
    git config user.name "SkyNetCMS"
    git add -A
    git commit -m "Initial commit from SkyNetCMS template"
    
    echo "[OK] Repository initialized"
fi

# ----------------------------------------
# 4. Run authentication setup (stub for M2)
# ----------------------------------------
if [ -f "/scripts/setup-auth.sh" ]; then
    /scripts/setup-auth.sh
fi

# ----------------------------------------
# 5. Run initial build (stub for M4)
# ----------------------------------------
if [ -f "/scripts/build-site.sh" ]; then
    /scripts/build-site.sh
fi

# ----------------------------------------
# 6. Start services
# ----------------------------------------
echo "[INFO] Starting services..."

# For M1: Just keep container running
# In M2: Will start nginx/openresty
# In M3: Will start OpenCode server + nginx

echo "============================================"
echo "  SkyNetCMS is running!"
echo "  Admin: $ADMIN_USER"
echo "  Title: ${SITE_TITLE:-SkyNetCMS}"
echo "============================================"

# Keep container running (will be replaced with nginx in M2)
tail -f /dev/null
