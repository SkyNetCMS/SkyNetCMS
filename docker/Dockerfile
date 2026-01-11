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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------
# Install OpenCode via npm
# ----------------------------------------
RUN npm install -g opencode-ai@latest

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
ENV BUILD_CMD="/scripts/build-site.sh"

# ----------------------------------------
# Create directory structure
# ----------------------------------------
RUN mkdir -p /data/repo/src /data/repo/dist /data/admin /scripts /etc/nginx/conf.d /etc/nginx/lua /run

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
# Copy admin placeholder
# ----------------------------------------
COPY templates/admin-placeholder/ /opt/admin-placeholder/

# ----------------------------------------
# Copy admin registration page
# ----------------------------------------
COPY nginx/admin-registration/ /opt/admin-registration/

# ----------------------------------------
# Copy OpenCode system config (empty for now - M3)
# ----------------------------------------
# COPY opencode/config/ /root/.config/opencode/

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
