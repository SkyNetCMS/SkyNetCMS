#!/bin/bash
# ============================================
# SkyNetCMS - Authentication Setup
# ============================================
# Generates htpasswd file from environment variables
# ============================================

set -e

if [ -z "$ADMIN_USER" ] || [ -z "$ADMIN_PASS" ]; then
    echo "[ERROR] ADMIN_USER and ADMIN_PASS must be set"
    exit 1
fi

# Generate htpasswd file using bcrypt (-B flag)
# -c = create file
# -i = read password from stdin (avoids password in process list)
# -B = bcrypt hashing (secure)
echo "$ADMIN_PASS" | htpasswd -ciB /data/auth/.htpasswd "$ADMIN_USER"

echo "[OK] Authentication configured for user: $ADMIN_USER"
