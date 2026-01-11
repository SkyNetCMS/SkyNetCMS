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
# -b = batch mode (password from command line)
# -B = bcrypt hashing (secure)
htpasswd -cbB /data/.htpasswd "$ADMIN_USER" "$ADMIN_PASS"

echo "[OK] Authentication configured for user: $ADMIN_USER"
