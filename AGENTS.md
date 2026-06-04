# SkyNetCMS - AI Development Guidelines

> Developing SkyNetCMS itself, NOT the AI that runs inside it for end-users.

## Architecture Overview

Single Docker container with OpenResty (Nginx + Lua) routing to:
- `/` → Static site from `/data/website/dist/` (main branch = LIVE)
- `/sn_admin/` → Admin Dashboard (htpasswd auth)
- `/sn_admin/oc/` → OpenCode Web UI (htpasswd auth)
- `/sn_admin/dev/` → Vite dev server preview (draft worktree)

OpenCode server runs on port 3000, working directory `/data/website/` (Git repo).

## Draft/Publish Workflow

SkyNetCMS uses git worktrees to separate draft changes from the live site:

- **Main worktree** (`/data/website/`): The `main` branch, serves live site at `/`
- **Draft worktrees** (`/data/opencode/worktree/<project-id>/`): OpenCode creates these for isolated editing
- **Dev preview** (`/sn_admin/dev/`): Vite dev server runs in the active draft worktree

### Key Points

- OpenCode's UI has built-in worktree management (create, switch, delete, reset)
- The dev server auto-detects the most recently modified worktree
- Override via query param: `/sn_admin/dev/?worktree=brave-falcon`
- Publish = merge draft branch to main + `npm run build` in main worktree
- Auto-tagging on publish enables rollback (`pre-publish-YYYYMMDD-HHMMSS`)

## Key Directories

```
docker/           # Dockerfile, scripts (init.sh)
nginx/            # nginx.conf, conf.d/, lua/ (auth logic, worktree detection)
opencode/config/  # → ~/.config/opencode/ in container
templates/default/ # Initial site template → /data/website/
```

## Docker Runtime Notes

- **Nginx worker user**: `www-data` (not `nobody` - Docker Desktop macOS has I/O issues with UID 65534)
- **Auth files**: `/data/auth/` (www-data owned) - separate from `/data/website/` (root owned)
- **OpenCode binary**: Pre-built from `ghcr.io/skynetcms/opencode` Docker image (SkyNetCMS fork with embedded web app, `--base-path` support). Version controlled via `OPENCODE_VERSION` build arg in `docker/Dockerfile` (defaults to `1.15.12-sn`).

## On-Demand Server Lifecycle

Both the Vite dev server and the OpenCode backend start lazily and stop when idle,
driven by the shared `nginx/lua/serverlifecycle.lua` controller:

- **Pattern**: lazy start on first request to the proxied location, auto-stop after
  5 min idle. Activity = any HTTP request OR persistent SSE/WebSocket connection.
- **OpenCode** (`ocserver.lua`, port 3000): before stopping, `is_busy()` polls
  `GET /session/status`; a `busy`/`retry` session keeps it alive (never killed
  mid-generation). A 404 (older builds) is treated as not-busy.
- **Vite** (`devserver.lua`, port 5173): pure idle timeout, restarts on worktree change.

### Process management (www-data → root)

The nginx worker runs as `www-data` but these servers run as root, so:

- **Liveness**: check `/proc/<pid>/status`, NOT `kill -0` (which returns a false
  "not running" via EPERM when www-data probes a root-owned PID).
- **Signals**: www-data cannot signal a root process directly — use the sudo
  wrapper scripts (`start-vite.sh`, `stop-vite.sh`, `start-opencode.sh`,
  `stop-opencode.sh`) listed in the `/etc/sudoers.d/skynet-servers` allowlist.

### Probing OpenCode directly

- API is reachable directly on `127.0.0.1:3000`; the app is mounted at BOTH `/`
  and the `--base-path` prefix (`/sn_admin/oc`), so the prefix is optional when
  testing internally.
- The `ghcr.io/skynetcms/opencode` image entrypoint is `opencode` — run standalone
  with `docker run ... <image> web --port ...` (pass `web ...`, not `opencode web ...`).
- The OpenCode image has **no `curl`** — probe from the host via a published port,
  or exec inside the full SkyNetCMS image (which has curl).

### Custom tools / plugins (fork gotcha)

- Do **NOT** `import { tool } from "@opencode-ai/plugin"` (as the upstream docs
  show). The fork tries to `npm install @opencode-ai/plugin@<fork-version>`
  (e.g. `1.15.12-sn`), which is not published to npm. The install fails, the
  import can't resolve, and that one bad tool file **breaks the entire tool
  registry** (even built-in `read`/`write`/`bash` disappear;
  `/experimental/tool/ids` returns `UnknownError`).
- Define tools as a **plain object** with no import:
  `export default { description, args: {}, async execute() { ... } }`. The
  `tool()` helper only adds zod/type sugar and is not required.
- Global tools live in `opencode/config/tools/` (→ read-only image
  `~/.config/opencode/tools/`); verify they load via
  `GET 127.0.0.1:3000/experimental/tool/ids`.

## Code Conventions

- **Shell**: `#!/bin/bash`, use `set -e`
- **Files**: lowercase-kebab-case (`init.sh`)
- **Docs**: PascalCase (`README.md`)
- **Commits**: Present tense ("Add nginx configuration")
- **Before committing**: Verify `git status` shows only expected changes. If there are unrelated uncommitted changes, flag them to the user before proceeding.

## Nginx Location Order (Critical)

Locations must be ordered most-specific first:
1. `/sn_admin/setup/` - registration (Lua)
2. `/sn_admin/register` - POST handler (Lua)
3. `/sn_admin/oc/` - OpenCode proxy
4. `/sn_admin/` - dashboard catch-all (MUST BE LAST)

## Security Boundaries

- **NEVER** expose OpenCode UI without authentication
- **NEVER** allow AI to modify nginx config at runtime
- **NEVER** store secrets in Git repository
- **OpenCode config**: Kept read-only in image (`/root/.config/opencode/`), not in `/data/` volume, to prevent AI/users from modifying behavior at runtime

## Scope Boundaries

- **DO NOT** implement "Future Phase" features unless requested
- **AVOID** database dependencies, over-engineering, framework-specific code

## Build Pipeline

AI edits `/data/website/src/` → build script copies to `/data/website/dist/` → Nginx serves dist.
Build: `docker exec <container> npm run build` (runs in `/data/website`)

## References

- Detailed docs: `README.md`, `PRD.md`, `PLAN.md`
- Environment variables: See `README.md`
- Testing/troubleshooting: See `README.md`


## Testing Rules

* Do not use "docker compose": use direct "docker"
* Start container with "--rm" so it will die at the exit and next test will be on fresh container
* If user testing is needed: in the ask specify login/password which was used for a container
* Always call container for testing "skynetcms-test"
* **Use `agent-browser` skill for UI testing** - automates browser interactions, screenshots, form filling
* Test checklist: See `TESTING.md` for comprehensive E2E test cases
