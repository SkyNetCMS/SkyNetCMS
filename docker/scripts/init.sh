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
# 2. First-run: Copy template if repo is empty
# ----------------------------------------
if [ ! -f "/data/website/src/index.html" ]; then
    echo "[INFO] First run detected - initializing from template..."
    cp -r /opt/templates/default/* /data/website/
    cp -r /opt/templates/default/.[!.]* /data/website/
fi
    
if [ ! -f "/data/website/dist/index.html" ]; then
    # Build site
    echo "[INFO] Running initial build..."
    cd /data/website
    npm run build
    
    # Initialize Git repository
    git init
    git config --global user.email "support@skynetcms.com"
    git config --global user.name "SkyNetCMS"
    git config --global --add safe.directory /data/website
    git add -A
    git commit -m "Initial commit from SkyNetCMS template"
    
    echo "[OK] Repository initialized"
fi

# ----------------------------------------
# 3.5. Set permissions for nginx worker
# ----------------------------------------
# Create /data/auth/ directory for htpasswd file
# This directory is owned by www-data so nginx worker can write to it
# (htpasswd command needs write access to the directory, not just the file)
# Note: We use www-data instead of nobody due to Docker Desktop restrictions
mkdir -p /data/auth
chown www-data:www-data /data/auth
chmod 755 /data/auth

# ----------------------------------------
# 3.6. Create OpenCode XDG directories
# ----------------------------------------
# Data and state persist in /data volume, cache is ephemeral in /tmp.
# Config stays read-only in image (/root/.config/opencode) for security.
# /data/opencode must be world-readable so the nginx worker (www-data) can
# reach the worktree directory for dev server preview.
mkdir -p /data/opencode/data /data/opencode/state /tmp/opencode-cache
chmod 755 /data/opencode

# ----------------------------------------
# 4. OpenCode web server (on-demand)
# ----------------------------------------
# OpenCode is NOT started here. It starts lazily on the first request to
# /sn_admin/oc/ (see nginx/lua/ocserver.lua) and auto-stops after 5 minutes of
# inactivity when no session is busy. This saves resources on idle containers.
echo "[INFO] OpenCode will start on-demand on first /sn_admin/oc/ access"

# ----------------------------------------
# 5. Run authentication setup (if credentials provided)
# ----------------------------------------
if [ "$AUTH_MODE" = "preconfigured" ]; then
    /scripts/setup-auth.sh
else
    # Check if htpasswd already exists (from previous registration)
    if [ -f "/data/auth/.htpasswd" ]; then
        echo "[OK] Existing admin credentials found"
    else
        echo "[INFO] No admin credentials configured"
        echo "[INFO] Visit /sn_admin/ to create admin account"
    fi
fi

# ----------------------------------------
# 6. Start OpenResty (nginx)
# ----------------------------------------
echo "[INFO] Starting OpenResty..."
echo "============================================"
echo "  SkyNetCMS is running!"
echo "  "
echo "  Public site:  http://localhost/"
echo "  Admin panel:  http://localhost/sn_admin/"
echo "  Health check: http://localhost/health"
echo "  OpenCode log: /tmp/opencode-dev.log (on-demand)"
echo "  "
if [ "$AUTH_MODE" = "preconfigured" ]; then
    echo "  Admin user: $ADMIN_USER"
else
    if [ -f "/data/auth/.htpasswd" ]; then
        echo "  Admin: Configured (via registration)"
    else
        echo "  Admin: NOT CONFIGURED - visit /sn_admin/ to setup"
    fi
fi
echo "  Site title: ${SITE_TITLE:-SkyNetCMS}"
echo "============================================"

# Start OpenResty in foreground (keeps container running)
# OpenCode starts on-demand when /sn_admin/oc/ is first accessed
exec openresty -g 'daemon off;'
