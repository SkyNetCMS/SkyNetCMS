#!/bin/bash
# Start Vite dev server
# This script is called by nginx/lua and runs as the root user
#
# Arguments:
#   $1 - Port number (e.g., 5173)
#   $2 - Base path (e.g., /sn_admin/dev/)
#   $3 - Working directory (optional, defaults to /data/website)

PORT="${1:-5173}"
BASE="${2:-/sn_admin/dev/}"
WORKDIR="${3:-/data/website}"

# Validate workdir exists
if [ ! -d "$WORKDIR" ]; then
    echo "Error: Working directory does not exist: $WORKDIR"
    exit 1
fi

# Check for package.json (indicates valid project)
if [ ! -f "$WORKDIR/package.json" ]; then
    echo "Error: No package.json found in: $WORKDIR"
    exit 1
fi

cd "$WORKDIR"
PATH=/usr/local/bin:$PATH
VITE_CJS_IGNORE_WARNING=true

echo "Starting Vite dev server in: $WORKDIR"
echo "Port: $PORT, Base: $BASE"

# Pre-flight: warn if the host inotify ceiling is low. Vite's watcher can exhaust
# it and crash with EMFILE. This is host-level (see README troubleshooting); we
# only surface a clear warning rather than a cryptic Node.js stack trace.
INOTIFY_FILE="/proc/sys/fs/inotify/max_user_instances"
if [ -r "$INOTIFY_FILE" ]; then
    INOTIFY_MAX="$(cat "$INOTIFY_FILE" 2>/dev/null || echo 0)"
    if [ "$INOTIFY_MAX" -lt 256 ] 2>/dev/null; then
        echo "[WARN] fs.inotify.max_user_instances is low ($INOTIFY_MAX); Vite may crash with EMFILE."
        echo "[WARN]   Fix on the host: sudo sysctl fs.inotify.max_user_instances=512"
    fi
fi

# Check if node_modules exists, run npm install if not
if [ ! -d "node_modules" ]; then
    echo "node_modules not found, running npm install..."
    npm install
fi

exec npx vite --host 127.0.0.1 --port "$PORT" --base "$BASE"
