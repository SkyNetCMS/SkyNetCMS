#!/bin/bash
# Start the OpenCode web server.
# This script is called by nginx/lua (ocserver.lua) via sudo and runs as root.
#
# OpenCode runs on port 3000 (localhost only); nginx proxies /sn_admin/oc/ to it.
# --base-path lets OpenCode work behind the reverse proxy.
#
# XDG_DATA_HOME is overridden to /data so worktrees land at
# /data/opencode/worktree/ — a location readable by both OpenCode (root) and
# the nginx worker (www-data) for dev server preview. The default
# (/root/.local/share) would not be readable by www-data.
set -e

# Ensure OpenCode XDG directories exist (data/state persist on the volume,
# cache is ephemeral in /tmp).
mkdir -p /data/opencode/data /data/opencode/state /tmp/opencode-cache
mkdir -p /data/opencode
chmod 755 /data/opencode

cd /data/website

exec env \
    XDG_DATA_HOME=/data \
    OPENCODE_TEST_HOME=/data/website \
    opencode web --port 3000 --hostname 127.0.0.1 --base-path /sn_admin/oc
