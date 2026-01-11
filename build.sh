#!/bin/bash
# ============================================
# SkyNetCMS Docker Build Script
# ============================================
set -e

echo "Building SkyNetCMS Docker image..."
docker build -t skynetcms -f docker/Dockerfile .

echo ""
echo "Build complete!"
echo ""
echo "Run with:"
echo "  docker run -d -p 8080:80 -e ADMIN_USER=admin -e ADMIN_PASS=secret -v skynet-data:/data --name skynetcms skynetcms"
echo ""
echo "Or use docker-compose:"
echo "  cd docker && docker-compose up -d"
