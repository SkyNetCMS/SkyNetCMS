#!/bin/bash
# ============================================
# SkyNetCMS - Container Initialization
# ============================================

set -e

echo "============================================"
echo "  SkyNetCMS - Starting Up"
echo "============================================"

# ----------------------------------------
# 1. Validate required environment variables
# ----------------------------------------
if [ -z "$ADMIN_USER" ]; then
    echo "[ERROR] ADMIN_USER environment variable is required"
    exit 1
fi

if [ -z "$ADMIN_PASS" ]; then
    echo "[ERROR] ADMIN_PASS environment variable is required"
    exit 1
fi

echo "[OK] Environment variables validated"

# ----------------------------------------
# 2. Initialize data directories
# ----------------------------------------
mkdir -p /data/repo/src /data/repo/dist /data/admin /run

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
# 4. Setup admin placeholder if not exists
# ----------------------------------------
if [ ! -f "/data/admin/index.html" ]; then
    cp /opt/admin-placeholder/index.html /data/admin/index.html
    echo "[OK] Admin placeholder created"
fi

# ----------------------------------------
# 5. Run authentication setup
# ----------------------------------------
/scripts/setup-auth.sh

# ----------------------------------------
# 6. Run initial build (copy src to dist)
# ----------------------------------------
/scripts/build-site.sh

# ----------------------------------------
# 7. Start OpenResty (nginx)
# ----------------------------------------
echo "[INFO] Starting OpenResty..."
echo "============================================"
echo "  SkyNetCMS is running!"
echo "  "
echo "  Public site:  http://localhost/"
echo "  Admin panel:  http://localhost/sn_admin/"
echo "  Health check: http://localhost/health"
echo "  "
echo "  Admin user: $ADMIN_USER"
echo "  Site title: ${SITE_TITLE:-SkyNetCMS}"
echo "============================================"

# Start OpenResty in foreground (keeps container running)
exec openresty -g 'daemon off;'
