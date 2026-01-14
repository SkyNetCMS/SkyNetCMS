# OpenCode Patches

This directory contains patches applied to OpenCode during the Docker build process.

## Current Patches

### base-path.ts

**Status:** WORKAROUND - Remove when fixed upstream

**Issue:** OpenCode PR #7625 adds `--base-path` support for running behind a reverse proxy, but has a bug in the JavaScript rewrite function.

**Problem:** The `rewriteJsForBasePath()` function in `packages/opencode/src/util/base-path.ts` uses this regex:

```javascript
/:window\.location\.origin\)/g
```

This expects the minified JS to have `:window.location.origin)` (ending with parenthesis), but the actual minified output has `:window.location.origin;` (ending with semicolon).

**Result:** Without the patch, API calls from the OpenCode frontend go to `/global/health` instead of `/sn_admin/oc/global/health`, causing 404 errors and the error message:

```
Error: Could not connect to server. Is there a server running at `http://localhost:8080`?
```

**Fix:** We replace the entire `base-path.ts` file with a patched version that uses an updated regex matching both patterns:

```javascript
// Original (broken):
/:window\.location\.origin\)/g
`:window.location.origin+(window.__OPENCODE_BASE_PATH__||""))`

// Patched (fixed):
/:window\.location\.origin([);])/g
`:window.location.origin+(window.__OPENCODE_BASE_PATH__||"")$1`
```

The patched regex matches both `)` and `;` after `window.location.origin` and preserves the matched character in the replacement.

**References:**
- PR: https://github.com/anomalyco/opencode/pull/7625
- Fork: https://github.com/prokube/opencode/tree/feature/base-path-support

**When to remove:** Once PR #7625 is merged with this fix, or when SkyNetCMS switches to an official OpenCode release with base-path support, this patch can be removed and the build can switch to:

```dockerfile
RUN npm install -g opencode-ai@latest
```

## How Patches Are Applied

The patched file is copied over the original during the Docker build in `docker/Dockerfile`:

```dockerfile
COPY docker/patches/base-path.ts /tmp/base-path.ts
RUN git clone ... \
    && cp /tmp/base-path.ts packages/opencode/src/util/base-path.ts \
    && bun install ...
```

## Files

| File | Description |
|------|-------------|
| `base-path.ts` | Patched version of `packages/opencode/src/util/base-path.ts` |
| `README.md` | This documentation file |
