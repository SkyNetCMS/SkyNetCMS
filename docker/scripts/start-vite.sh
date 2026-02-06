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

# Check if node_modules exists, run npm install if not
if [ ! -d "node_modules" ]; then
    echo "node_modules not found, running npm install..."
    npm install
fi

exec npx vite --host 127.0.0.1 --port "$PORT" --base "$BASE"
