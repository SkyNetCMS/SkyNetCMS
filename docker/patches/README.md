# OpenCode Patches

This directory previously contained patches applied to OpenCode during the Docker build process.

## Current Status: No Patches Required

As of January 2026, SkyNetCMS uses the **SkyNetCMS/opencode** fork which includes all necessary modifications:

- **Repository:** https://github.com/SkyNetCMS/opencode
- **Branch:** `skynetcms`

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

The Dockerfile now simply clones and builds from the fork:

```dockerfile
RUN git clone --depth 1 --branch skynetcms \
        https://github.com/SkyNetCMS/opencode.git /tmp/opencode \
    && cd /tmp/opencode \
    && bun install --frozen-lockfile \
    && cd packages/opencode \
    && bun run build --single \
    ...
```

The build script automatically:
1. Builds `packages/app` (frontend) → `packages/app/dist/`
2. Generates `app-manifest.ts` with Bun file imports
3. Compiles `packages/opencode` with embedded assets

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

---

## Adding Future Patches

If new patches are needed:

1. Make changes in the SkyNetCMS/opencode fork (preferred)
2. Or, if temporary: add patch file here and update Dockerfile to apply it

The fork approach is preferred as it keeps all OpenCode modifications in one place.
