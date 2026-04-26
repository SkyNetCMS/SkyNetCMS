# SkyNetCMS - Implementation Plan

## Incoming

> Unscheduled items. Add new work here; `/plan` will triage on next run.

## Phase 1: Project Foundation

- [x] Repository structure (docker/, nginx/, opencode/config/, templates/default/)
- [x] Dockerfile with Node.js 24 Alpine, OpenResty, Git, OpenCode
- [x] Environment configuration (ADMIN_USER, ADMIN_PASS, SITE_TITLE, BUILD_CMD)
- [x] Container startup orchestration via init.sh
- [x] Docker build and startup verification

## Phase 2: Nginx Routing & Static Serving

- [x] Nginx configuration with port 80, worker processes, error logging
- [x] Static file serving from /data/website/dist/ at `/`
- [x] htpasswd authentication for `/sn_admin/` with bcrypt hashing
- [x] Health check endpoint at `/health`

## Phase 3: First-Time Registration

- [x] Lua auth infrastructure with shared dict rate limiting
- [x] Registration page with username/password form, client-side validation, SkyNetCMS branding
- [x] Lua registration handler (POST validation, bcrypt htpasswd generation, rate limiting)
- [x] Dynamic auth routing (redirect to registration when unconfigured, enforce auth_basic when configured)
- [x] Optional ADMIN_USER/ADMIN_PASS env vars (pre-configured mode or interactive registration)

## Phase 4: OpenCode Integration

- [x] OpenCode web server on port 3000 with startup health check (max 30s)
- [x] Nginx reverse proxy at `/sn_admin/oc/` with WebSocket support and extended timeouts
- [x] Admin dashboard SPA with service-injector wrapper (main iframe + floating OpenCode window)
- [x] OpenCode config (autoupdate disabled, sharing disabled, localhost-only)

## Phase 5: Branding & Styling

- [x] Style guide (STYLE_GUIDE.md) with CSS custom properties, dark theme, cyan accent (#00d4ff)
- [x] Logo assets (hexagonal neural network SVG icon, full logo, compact logo, favicon)
- [x] Apply branding to admin dashboard (color scheme, floating window header, tab styling)
- [x] Apply branding to registration page (color scheme, inline SVG logo)

## Phase 6: Template & Content Pipeline

- [x] Welcome template (src/index.html) with Vite build system (src/ to dist/)
- [x] First-run initialization (Git repo init, template copy, initial build, initial commit)
- [x] AGENTS.md for site-building AI context (draft/publish workflow, build commands, rollback)

## Phase 7: Integration Testing & Documentation

- [x] End-to-end user flow testing (deploy, auth, registration, persistence) — 36/37 passed
- [x] Security hardening (security headers, server_tokens off, client_max_body_size)
- [x] README documentation with quick start guide, architecture diagram, environment reference
- [x] Code cleanup (removed debug logging, consistent formatting, code comments)

## Phase 8: Dev Server Resilience

> Discovered in production: Vite dev server fails on resource-constrained hosts due to
> exhausted inotify instances, and nginx worker (www-data) cannot manage root-owned Vite processes.

- [ ] Add inotify `max_user_instances` check and best-effort raise in `docker/scripts/init.sh`
  - Read current value from `/proc/sys/fs/inotify/max_user_instances`
  - If below 512, attempt to write 8192 (requires `--privileged` or `--cap-add SYS_ADMIN`)
  - If write fails, print `[WARN]` with host-level sysctl fix command
- [ ] Add inotify pre-check in `docker/scripts/start-vite.sh`
  - Before starting Vite, compare in-use inotify instances vs max
  - Exit with actionable error message instead of letting Node.js crash with raw EMFILE stack trace
- [ ] Fix `is_process_running()` in `nginx/lua/devserver.lua`
  - Replace `kill -0` with `/proc/<pid>/status` file check
  - `kill -0` fails with EPERM when www-data checks root-owned process, returning false positive "not running"
  - This causes wait_for_ready() to exit in ~1s instead of waiting 30s, masking real startup errors
- [ ] Fix `stop_server()` in `nginx/lua/devserver.lua`
  - www-data cannot send signals to root-owned Vite process
  - Create `docker/scripts/stop-vite.sh` wrapper (accepts PID and signal)
  - Add `stop-vite.sh` to sudoers in `docker/Dockerfile` alongside `start-vite.sh`
  - Update `stop_server()` to use `sudo /scripts/stop-vite.sh` instead of direct `kill`
- [ ] Add troubleshooting section to `README.md`
  - Document EMFILE / inotify issue with host-level sysctl fix
  - Document persistent fix via `/etc/sysctl.d/99-inotify.conf`

## Future

> Items outside current scope. See PRD.md "Future Phase Backlog" for the full list.

- [ ] Push to external Git (GitHub, GitLab)
- [ ] Visual diff comparison in UI
- [ ] "Publish" button in dashboard (currently AI-only)
- [ ] Slash commands for end-users (/publish, /preview, /branch)
- [ ] File browser in admin panel
- [ ] Custom domain configuration and built-in SSL
- [ ] Session-based authentication with logout
- [ ] Multiple admin users and role-based permissions
- [ ] Framework support (Vue, React, Next.js)
- [ ] CDN integration and cloud backup
