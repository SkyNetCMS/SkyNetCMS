#!/bin/bash
# Start Vite dev server
# This script is called by nginx/lua and runs as the root user

cd /data/website
PATH=/usr/local/bin:$PATH
VITE_CJS_IGNORE_WARNING=true

exec npx vite --host 127.0.0.1 --port "$1" --base "$2"
