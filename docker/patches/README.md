# OpenCode Patches

This directory contains patches applied to OpenCode during the Docker build process.

## Patching Approach

SkyNetCMS builds OpenCode from source (from a fork with `--base-path` support) rather than using the npm package. This is because the upstream OpenCode doesn't yet support running behind a reverse proxy with a path prefix.

### Why We Patch

1. **PR #7625 not merged yet** - The `--base-path` feature exists only in a fork
2. **PR has bugs** - The implementation has issues that prevent it from working correctly
3. **We need it to work now** - SkyNetCMS embeds OpenCode at `/sn_admin/oc/`

### Patching Strategy

We use **file replacement** rather than `git apply` patches because:

- **Simpler**: No need to maintain unified diff format with correct line numbers
- **Readable**: The patched file is complete and self-documenting
- **Debuggable**: Easy to compare with upstream and identify our changes
- **Reliable**: Won't fail due to upstream changes in unrelated parts of the file

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                     Docker Build Process                         │
│                                                                  │
│  1. COPY docker/patches/base-path.ts /tmp/base-path.ts          │
│                                                                  │
│  2. git clone prokube/opencode (fork with --base-path PR)       │
│                                                                  │
│  3. cp /tmp/base-path.ts packages/opencode/src/util/base-path.ts│
│     ▲                                                            │
│     └── Our patched version replaces the original               │
│                                                                  │
│  4. bun install && bun run build                                │
│                                                                  │
│  5. Copy built binary to /usr/local/bin/opencode                │
└─────────────────────────────────────────────────────────────────┘
```

### Adding New Patches

To patch a different file:

1. Copy the original file from the OpenCode repo
2. Make your modifications
3. Add comments marked `SKYNETCMS PATCH` explaining the change
4. Save to `docker/patches/<filename>`
5. Update `docker/Dockerfile` to copy and replace the file
6. Document in this README

### Removing Patches

When the upstream PR is fixed/merged:

1. Test with unpatched OpenCode: `npm install -g opencode-ai@latest`
2. If it works, remove the patch from `docker/patches/`
3. Update `docker/Dockerfile` to use npm install instead of building from source
4. Update this README

---

## Current Patches

### base-path.ts

**Status:** WORKAROUND - Remove when fixed upstream

**Original file:** `packages/opencode/src/util/base-path.ts`

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

---

## Files

| File | Description |
|------|-------------|
| `base-path.ts` | Patched version of `packages/opencode/src/util/base-path.ts` |
| `README.md` | This documentation file |
