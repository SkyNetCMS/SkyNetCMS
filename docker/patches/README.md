# OpenCode Patches

This directory previously contained patches applied to OpenCode during the Docker build process.

## Current Status: No Patches Required

SkyNetCMS uses a pre-built OpenCode binary from the **SkyNetCMS/opencode** fork's Docker image:

- **Image:** `ghcr.io/skynetcms/opencode`
- **Repository:** https://github.com/SkyNetCMS/opencode
- **Branch:** `skynetcms`
- **Available tags:** https://github.com/SkyNetCMS/opencode/pkgs/container/opencode/versions

### Features Included in the Fork

1. **`--base-path` support** - Allows OpenCode to run behind a reverse proxy at `/sn_admin/oc/`
2. **Embedded frontend app** - Web UI assets are bundled into the binary at build time (no runtime dependency on `app.opencode.ai`)
3. **All previous patches integrated** - No need for build-time file replacements

### Why We Maintain a Fork

The upstream OpenCode project (`anomalyco/opencode`) doesn't yet support:

1. Running behind a reverse proxy with a path prefix (`--base-path` flag)
2. Offline/self-hosted web UI (it proxies to `app.opencode.ai` at runtime)

The SkyNetCMS fork addresses both issues by:
- Integrating the `--base-path` PR with additional fixes
- Building and embedding the frontend app into the binary

### Build Process

SkyNetCMS no longer builds OpenCode from source. Instead, the Dockerfile pulls a pre-built
binary from the fork's published Docker image:

```dockerfile
ARG OPENCODE_VERSION=latest
FROM ghcr.io/skynetcms/opencode:${OPENCODE_VERSION} AS opencode
# ...
COPY --from=opencode /usr/local/bin/opencode /usr/local/bin/opencode
```

To pin a specific version:
```bash
docker build --build-arg OPENCODE_VERSION=1.2.10-sn -t skynetcms -f docker/Dockerfile .
```

The opencode fork's CI builds and publishes the Docker image automatically.

### Future: Returning to Upstream

When upstream OpenCode supports both `--base-path` and embedded/offline web UI, we can switch back to:

```dockerfile
RUN npm install -g opencode-ai@latest
```

Monitor these upstream issues/PRs:
- Base path support: https://github.com/anomalyco/opencode/pull/7625
- Embedded app: (no upstream issue yet)

---

## Historical Patches (Removed)

The following patches were previously maintained here but are now integrated into the SkyNetCMS/opencode fork:

| Patch | Issue | Resolution |
|-------|-------|------------|
| `base-path.ts` | Regex mismatch + hardcoded `/assets/` paths | Integrated into fork |
