#!/bin/bash
# ============================================
# SkyNetCMS - Container Initialization
# ============================================

set -e

echo "============================================"
echo "  SkyNetCMS - Starting Up"
echo "============================================"

# ----------------------------------------
# 1. Validate environment variables
# ----------------------------------------
# ADMIN_USER and ADMIN_PASS are now OPTIONAL
# - If BOTH provided: pre-configure admin (existing behavior)
# - If NEITHER provided: allow first-time registration flow
# - If only ONE provided: error (invalid configuration)

AUTH_MODE="registration"  # Default to registration flow

if [ -n "$ADMIN_USER" ] && [ -n "$ADMIN_PASS" ]; then
    AUTH_MODE="preconfigured"
    echo "[OK] Admin credentials provided via environment"
elif [ -n "$ADMIN_USER" ] && [ -z "$ADMIN_PASS" ]; then
    echo "[ERROR] ADMIN_USER provided but ADMIN_PASS is missing"
    echo "        Either provide both ADMIN_USER and ADMIN_PASS,"
    echo "        or omit both to use the registration flow."
    exit 1
elif [ -z "$ADMIN_USER" ] && [ -n "$ADMIN_PASS" ]; then
    echo "[ERROR] ADMIN_PASS provided but ADMIN_USER is missing"
    echo "        Either provide both ADMIN_USER and ADMIN_PASS,"
    echo "        or omit both to use the registration flow."
    exit 1
else
    echo "[INFO] No admin credentials provided"
    echo "[INFO] First-time registration will be required at /sn_admin/"
fi

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
    cd /
    
    echo "[OK] Repository initialized"
fi

# ----------------------------------------
# 3.5. Set permissions for nginx worker
# ----------------------------------------
# Ensure /data is writable by nginx worker (nobody:nogroup)
# This is needed for Lua scripts to create htpasswd file during registration
chown -R nobody:nogroup /data
chmod -R 755 /data

# ----------------------------------------
# 4. Setup admin placeholder if not exists
# ----------------------------------------
if [ ! -f "/data/admin/index.html" ]; then
    cp /opt/admin-placeholder/index.html /data/admin/index.html
    echo "[OK] Admin placeholder created"
fi

# ----------------------------------------
# 5. Run authentication setup (if credentials provided)
# ----------------------------------------
if [ "$AUTH_MODE" = "preconfigured" ]; then
    /scripts/setup-auth.sh
else
    # Check if htpasswd already exists (from previous registration)
    if [ -f "/data/.htpasswd" ]; then
        echo "[OK] Existing admin credentials found"
    else
        echo "[INFO] No admin credentials configured"
        echo "[INFO] Visit /sn_admin/ to create admin account"
    fi
fi

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
if [ "$AUTH_MODE" = "preconfigured" ]; then
    echo "  Admin user: $ADMIN_USER"
else
    if [ -f "/data/.htpasswd" ]; then
        echo "  Admin: Configured (via registration)"
    else
        echo "  Admin: NOT CONFIGURED - visit /sn_admin/ to setup"
    fi
fi
echo "  Site title: ${SITE_TITLE:-SkyNetCMS}"
echo "============================================"

# Start OpenResty in foreground (keeps container running)
exec openresty -g 'daemon off;'
