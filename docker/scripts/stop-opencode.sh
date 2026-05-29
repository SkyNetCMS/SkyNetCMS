#!/bin/bash
# Stop the OpenCode web server.
# Called by nginx/lua (serverlifecycle.lua) via sudo and runs as root, because
# the nginx worker (www-data) cannot signal the root-owned OpenCode process.
#
# Arguments:
#   $1 - PID
#   $2 - Signal name (e.g. TERM, KILL); defaults to TERM

PID="$1"
SIGNAL="${2:-TERM}"

# Validate PID is numeric
if ! [[ "$PID" =~ ^[0-9]+$ ]]; then
    echo "Error: invalid PID: $PID"
    exit 1
fi

# Signal the process group first (kills any children), then the PID.
kill "-${SIGNAL}" "-${PID}" 2>/dev/null || kill "-${SIGNAL}" "${PID}" 2>/dev/null
exit 0
