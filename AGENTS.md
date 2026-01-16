# SkyNetCMS - AI Development Guidelines

> Developing SkyNetCMS itself, NOT the AI that runs inside it for end-users.

## Architecture Overview

Single Docker container with OpenResty (Nginx + Lua) routing to:
- `/` → Static site from `/data/repo/dist/`
- `/sn_admin/` → Admin Dashboard (htpasswd auth)
- `/sn_admin/oc/` → OpenCode Web UI (htpasswd auth)

OpenCode server runs on port 3000, working directory `/data/repo/` (Git repo).

## Key Directories

```
docker/           # Dockerfile, scripts (init.sh)
nginx/            # nginx.conf, conf.d/, lua/ (auth logic)
opencode/config/  # → ~/.config/opencode/ in container
templates/default/ # Initial site template → /data/repo/
```

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

## Scope Boundaries

- **DO NOT** implement "Future Phase" features unless requested
- **AVOID** database dependencies, over-engineering, framework-specific code

## Build Pipeline

AI edits `/data/repo/src/` → build script copies to `/data/repo/dist/` → Nginx serves dist.
Build: `docker exec <container> npm run build` (runs in `/data/repo`)

## References

- Detailed docs: `README.md`, `PRD_v1.md`, `PLAN_v1.md`
- Environment variables: See `README.md`
- Testing/troubleshooting: See `README.md`


## Testing Rules

* Do not use "docker compose": use direct "docker"
* Start container with "--rm" so it will die at the exit and next test will be on fresh container
* If user testing is needed: in the ask specify login/password which was used for a container
* Always call container for testing "skynetcms-test"
