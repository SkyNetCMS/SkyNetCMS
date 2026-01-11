# ============================================
# SkyNetCMS Dockerfile
# ============================================
# Base: Node.js 24 LTS on Alpine
# + OpenResty (nginx with Lua)
# + OpenCode (AI coding assistant)
# ============================================

FROM node:24-alpine

LABEL maintainer="SkyNetCMS"
LABEL description="AI-Powered Conversational CMS"

# ----------------------------------------
# Install dependencies
# ----------------------------------------
RUN apk add --no-cache \
    bash \
    curl \
    git \
    apache2-utils \
    ripgrep \
    libgcc \
    libstdc++ \
    wget \
    gnupg

# ----------------------------------------
# Install OpenResty
# Note: Using OpenResty's Alpine packages
# ----------------------------------------

# Add OpenResty's public key
RUN wget -O /etc/apk/keys/admin@openresty.com-5ea678a6.rsa.pub \
    'http://openresty.org/package/admin@openresty.com-5ea678a6.rsa.pub'

# Add OpenResty repository (using v3.18 packages - most recent officially supported)
RUN echo "http://openresty.org/package/alpine/v3.18/main" >> /etc/apk/repositories

# Install OpenResty
RUN apk add --no-cache openresty

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
RUN mkdir -p /data/repo/src /data/repo/dist /scripts

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
