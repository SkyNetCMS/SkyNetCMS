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
- **OpenCode source**: Built from `SkyNetCMS/opencode` fork (branch: `skynetcms`) with embedded web app (no runtime dependency on `app.opencode.ai`)

## Code Conventions

- **Shell**: `#!/bin/bash`, use `set -e`
- **Files**: lowercase-kebab-case (`init.sh`)
- **Docs**: PascalCase (`README.md`)
- **Commits**: Present tense ("Add nginx configuration")

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

- Detailed docs: `README.md`, `PRD_v1.md`, `PLAN_v1.md`
- Environment variables: See `README.md`
- Testing/troubleshooting: See `README.md`


## Testing Rules

* Do not use "docker compose": use direct "docker"
* Start container with "--rm" so it will die at the exit and next test will be on fresh container
* If user testing is needed: in the ask specify login/password which was used for a container
* Always call container for testing "skynetcms-test"
* **Use `agent-browser` skill for UI testing** - automates browser interactions, screenshots, form filling
* Test checklist: See `TESTING.md` for comprehensive E2E test cases
