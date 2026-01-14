# OpenCode Patches

This directory contains patches applied to OpenCode during the Docker build process.

## Current Patches

### base-path.ts

**Status:** WORKAROUND - Remove when fixed upstream

**Issue:** OpenCode PR #7625 adds `--base-path` support for running behind a reverse proxy, but has bugs in the JavaScript rewrite function.

#### Problem #1: API URL regex mismatch

The `rewriteJsForBasePath()` function uses this regex:

```javascript
/:window\.location\.origin\)/g
```

This expects the minified JS to have `:window.location.origin)` (ending with parenthesis), but the actual minified output has `:window.location.origin;` (ending with semicolon).

**Result:** API calls go to `/global/health` instead of `/sn_admin/oc/global/health`, causing:

```
Error: Could not connect to server. Is there a server running at `http://localhost:8080`?
```

**Fix:** Updated regex to match both patterns:

```javascript
// Original (broken):
/:window\.location\.origin\)/g

// Patched (fixed):
/:window\.location\.origin([);])/g
```

#### Problem #2: Hardcoded asset paths not rewritten

The JavaScript contains hardcoded string literals for static assets:

```javascript
"/assets/inter-FIwubZjA.woff2"
"/assets/BlexMonoNerdFontMono-Regular-DSJ7IWr2.woff2"
"/assets/staplebops-01-UOWVxfVx.aac"
```

These are font files and audio files loaded dynamically by JavaScript, not referenced in CSS.

**Result:** Fonts and audio files return 404 because they're requested at `/assets/...` instead of `/sn_admin/oc/assets/...`

**Fix:** Added additional rewrite rule:

```javascript
// Rewrite hardcoded "/assets/..." paths
result = result.replace(/"\/assets\//g, `"${basePath}/assets/`)
```

### Summary of All Patches

| Patch | Problem | Fix |
|-------|---------|-----|
| #1 | Regex expects `)` but code has `;` | Match both `[);]` |
| #2 | Hardcoded `/assets/` paths | Rewrite `"/assets/` to `"${basePath}/assets/` |

**References:**
- PR: https://github.com/anomalyco/opencode/pull/7625
- Fork: https://github.com/prokube/opencode/tree/feature/base-path-support

**When to remove:** Once PR #7625 is merged with these fixes, or when SkyNetCMS switches to an official OpenCode release with proper base-path support, this patch can be removed and the build can switch to:

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
