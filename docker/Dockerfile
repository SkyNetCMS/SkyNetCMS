# ============================================
# SkyNetCMS Dockerfile
# ============================================
# Base: Node.js 24 LTS on Debian Bookworm (slim)
# + OpenResty (nginx with Lua)
# + OpenCode (AI coding assistant)
# ============================================

FROM node:24-bookworm-slim

LABEL maintainer="SkyNetCMS"
LABEL description="AI-Powered Conversational CMS"

# ----------------------------------------
# Install prerequisites for OpenResty
# ----------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        gnupg \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------
# Install OpenResty (Debian packages)
# Note: arm64 packages are in a different URL
# ----------------------------------------
RUN wget -O - https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg \
    && ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "arm64" ]; then \
         echo "deb http://openresty.org/package/arm64/debian bookworm openresty" > /etc/apt/sources.list.d/openresty.list; \
       else \
         echo "deb http://openresty.org/package/debian bookworm openresty" > /etc/apt/sources.list.d/openresty.list; \
       fi \
    && apt-get update \
    && apt-get install -y --no-install-recommends openresty \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------
# Install additional dependencies
# ----------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    apache2-utils \
    ripgrep \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------
# Install Bun (required for building OpenCode)
# OpenCode requires specific version (1.3.5) per its package.json
# ----------------------------------------
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v1.3.5"
ENV PATH="/root/.bun/bin:${PATH}"

# ----------------------------------------
# Build OpenCode from source with base-path support
# This uses a fork with PR #7625 that adds --base-path flag
# PR: https://github.com/anomalyco/opencode/pull/7625
# TODO: Switch back to 'npm install -g opencode-ai@latest' when PR is merged
#
# WORKAROUND: The PR doesn't rewrite hardcoded "/assets/..." paths in JS
# (fonts like Inter, BlexMono load via string literals, not Vite's dynamic loader).
# We replace base-path.ts with a patched version before building.
# See: docker/patches/README.md for details
# TODO: Remove this patch when PR #7625 is fixed upstream
# ----------------------------------------
COPY docker/patches/base-path.ts /tmp/base-path.ts
RUN git clone --depth 1 --branch feature/base-path-support \
        https://github.com/prokube/opencode.git /tmp/opencode \
    && cd /tmp/opencode \
    && echo "Applying SkyNetCMS patch to fix hardcoded asset paths..." \
    && cp /tmp/base-path.ts packages/opencode/src/util/base-path.ts \
    && bun install --frozen-lockfile \
    && cd packages/opencode \
    && bun run build --single \
    && ARCH=$(uname -m) \
    && if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
         cp dist/opencode-linux-arm64/bin/opencode /usr/local/bin/opencode; \
       else \
         cp dist/opencode-linux-x64/bin/opencode /usr/local/bin/opencode; \
       fi \
    && chmod +x /usr/local/bin/opencode \
    && cd / \
    && rm -rf /tmp/opencode /tmp/base-path.ts

# ----------------------------------------
# Verify installations
# ----------------------------------------
RUN echo "Verifying installations..." && \
    openresty -v && \
    opencode --version && \
    bun --version && \
    git --version && \
    node --version

# ----------------------------------------
# Environment variables
# ----------------------------------------
ENV ADMIN_USER=""
ENV ADMIN_PASS=""
ENV SITE_TITLE="SkyNetCMS"
ENV BUILD_CMD="/scripts/build-site.sh"

# ----------------------------------------
# Create directory structure
# ----------------------------------------
RUN mkdir -p /data/repo/src /data/repo/dist /scripts /etc/nginx/conf.d /etc/nginx/lua /run

# ----------------------------------------
# Copy nginx configuration
# ----------------------------------------
COPY nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx/conf.d/ /etc/nginx/conf.d/

# ----------------------------------------
# Copy Lua scripts for authentication
# ----------------------------------------
COPY nginx/lua/ /etc/nginx/lua/

# ----------------------------------------
# Copy scripts
# ----------------------------------------
COPY docker/scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# ----------------------------------------
# Copy default template
# ----------------------------------------
COPY templates/default/ /opt/templates/default/

# ----------------------------------------
# Copy admin dashboard SPA
# ----------------------------------------
COPY nginx/admin-dashboard/ /opt/admin-dashboard/

# ----------------------------------------
# Copy admin registration page
# ----------------------------------------
COPY nginx/admin-registration/ /opt/admin-registration/

# ----------------------------------------
# Copy OpenCode system config
# ----------------------------------------
RUN mkdir -p /root/.config/opencode
COPY opencode/config/ /root/.config/opencode/

# ----------------------------------------
# Expose ports
# ----------------------------------------
EXPOSE 80

# ----------------------------------------
# Volume for persistent data
# ----------------------------------------
VOLUME ["/data"]

# ----------------------------------------
# Health check
# ----------------------------------------
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD curl -f http://localhost/health || exit 1

# ----------------------------------------
# Entrypoint
# ----------------------------------------
ENTRYPOINT ["/scripts/init.sh"]
