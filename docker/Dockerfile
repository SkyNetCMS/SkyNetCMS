# ============================================
# SkyNetCMS Dockerfile
# ============================================
# Uses pre-built OpenCode binary from ghcr.io/skynetcms/opencode
# Runtime image: OpenResty + Node.js
# ============================================
# OpenCode version - override with: docker build --build-arg OPENCODE_VERSION=1.2.10-sn
# Available tags: https://github.com/SkyNetCMS/opencode/pkgs/container/opencode/versions
ARG OPENCODE_VERSION=latest
FROM ghcr.io/skynetcms/opencode:${OPENCODE_VERSION} AS opencode

# ============================================
# Runtime Image
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
# Install runtime dependencies
# ----------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    apache2-utils \
    ripgrep \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Allow www-data to run start-vite.sh as root without password
# This is needed because nginx worker (www-data) spawns vite dev server
# which needs write access to /data/website/node_modules
RUN echo "www-data ALL=(root) NOPASSWD: /scripts/start-vite.sh" > /etc/sudoers.d/vite-dev \
    && chmod 440 /etc/sudoers.d/vite-dev

# ----------------------------------------
# Copy OpenCode binary from pre-built image
# ----------------------------------------
COPY --from=opencode /usr/local/bin/opencode /usr/local/bin/opencode

# ----------------------------------------
# Verify installations
# ----------------------------------------
RUN echo "Verifying installations..." && \
    openresty -v && \
    opencode --version && \
    git --version && \
    node --version

# ----------------------------------------
# Environment variables
# ----------------------------------------
ENV ADMIN_USER=""
ENV ADMIN_PASS=""
ENV SITE_TITLE="SkyNetCMS"

# XDG directories for OpenCode
# Config stays in image (/root/.config/opencode) - read-only for security
ENV XDG_DATA_HOME=/data/opencode/data
ENV XDG_STATE_HOME=/data/opencode/state
ENV XDG_CACHE_HOME=/tmp/opencode-cache

# ----------------------------------------
# Create directory structure
# ----------------------------------------
RUN mkdir -p /data/website/src /data/website/dist /scripts /etc/nginx/conf.d /etc/nginx/lua /run

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
# Pre-install template dependencies
# ----------------------------------------
RUN cd /opt/templates/default && npm install

# ----------------------------------------
# Build admin UI (dashboard + registration pages)
# ----------------------------------------
COPY admin-ui/ /tmp/admin-ui/
RUN cd /tmp/admin-ui \
    && npm install \
    && npm run build \
    && cp -r /tmp/admin-ui/dist /opt/admin-ui \
    && rm -rf /tmp/admin-ui

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
# Working directory
# ----------------------------------------
WORKDIR /data/website

# ----------------------------------------
# Entrypoint
# ----------------------------------------
ENTRYPOINT ["/scripts/init.sh"]
