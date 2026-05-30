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

## Phase 8: On-Demand OpenCode Lifecycle

> FR-070 through FR-074: OpenCode currently starts eagerly at container boot and runs forever.
> Mirror the Vite dev server's on-demand model — lazy start on first `/sn_admin/oc/` access,
> auto-stop when idle — but query OpenCode's `/session/status` API before stopping so an
> in-progress AI generation is never killed. Shares process-management fixes with Phase 9.

- [x] Extract shared lifecycle base module `nginx/lua/serverlifecycle.lua`
  - Common logic: PID/dir file management, shared-dict status tracking, start via sudo wrapper, `wait_for_ready`, `/proc/<pid>/status` liveness check, generic idle check with a pluggable "is-busy" predicate
  - Parameterized per service (port, PID file, dir file, shared dict name, start command, readiness check)
- [x] Refactor `nginx/lua/devserver.lua` to use the shared base module
  - Preserve current Vite behavior (port 5173, `dev_server` dict, 5-min idle, worktree restart)
- [x] Create `nginx/lua/ocserver.lua` using the shared base
  - Port 3000, `oc_server` shared dict, 5-min idle timeout
  - Implement `is_busy()` — query `http://127.0.0.1:3000/sn_admin/oc/session/status` via raw socket, return true if any session is `busy`/`retry`; treat 404 as not-busy (older builds) and other errors as fail-safe busy
  - Idle check stops OpenCode only when no session is active; otherwise reset the activity timer
- [x] Create `docker/scripts/start-opencode.sh` wrapper
  - Move the `XDG_DATA_HOME=/data OPENCODE_TEST_HOME=/data/website opencode web --port 3000 --hostname 127.0.0.1 --base-path /sn_admin/oc` invocation out of `init.sh`
- [x] Create `docker/scripts/stop-opencode.sh` wrapper (accepts PID and signal); also added `stop-vite.sh`
- [x] Add `start-opencode.sh` and `stop-opencode.sh` (and `stop-vite.sh`) to sudoers in `docker/Dockerfile`
- [x] Remove eager OpenCode startup block from `docker/scripts/init.sh` (kept XDG dir creation)
- [x] Add `access_by_lua_block` to the `/sn_admin/oc/` location in `nginx/conf.d/default.conf`
  - Start OpenCode if not running, wait up to 30s for readiness, update activity timestamp
  - Keep WebSocket proxying and existing headers/timeouts intact
- [x] Add `lua_shared_dict oc_server 64k;` and an OpenCode idle-check timer to `nginx/nginx.conf` `init_worker_by_lua_block`
- [x] Bump OpenCode to `1.15.12-sn` (the `/session/status` route required by the busy-check is not present in `1.14.23-sn`)
- [x] Test end-to-end: cold container → first `/sn_admin/oc/` hit starts OpenCode → AI works → idle 5 min with no active session stops it → idle during an active generation does NOT stop it

## Phase 9: Dev Server Resilience

> Discovered in production: Vite dev server fails on resource-constrained hosts due to
> exhausted inotify instances, and nginx worker (www-data) cannot manage root-owned Vite processes.
>
> Note: The `/proc`-based liveness check and sudo stop-wrapper below were shared with Phase 8's
> `serverlifecycle.lua` and landed there first — those two tasks are now complete (see Phase 8).
> The remaining work is the inotify/EMFILE handling, scoped lean: best-effort detection + docs
> only, since `max_user_instances` is a host kernel setting the container cannot reliably raise.

- [x] Add inotify `max_user_instances` check (best-effort) in `docker/scripts/init.sh`
  - Read current value from `/proc/sys/fs/inotify/max_user_instances`
  - If below 256, attempt to write 512 (silently fails without `--privileged` / `SYS_ADMIN`)
  - If still low, print `[WARN]` with host-level sysctl fix command (non-fatal)
- [x] Add inotify pre-flight WARN in `docker/scripts/start-vite.sh`
  - Surface a clear `[WARN]` + host fix if the ceiling is below 256, instead of a cryptic EMFILE crash
  - Dropped: counting in-use inotify instances (fragile `/proc/*/fd` walk, low value)
- [x] Fix `is_process_running()` — use `/proc/<pid>/status` instead of `kill -0` (done in Phase 8, `serverlifecycle.lua`)
- [x] Fix `stop_server()` — sudo `stop-vite.sh` wrapper + sudoers entry (done in Phase 8)
- [x] Add troubleshooting section to `README.md`
  - Document EMFILE / inotify issue with host-level sysctl fix
  - Document persistent fix via `/etc/sysctl.d/99-inotify.conf`

## Phase 10: AI Page/URL Awareness

> FR-050 through FR-053: AI knows which page the user is viewing in the
> preview iframe, without requiring manual selection.

- [ ] Dashboard JS: track current preview iframe URL, page title, and view mode (draft/live)
  - Listen for iframe `load` events and navigation changes
  - Store state in a known location accessible outside the browser (e.g., write to `/data/website/.opencode/current-page.json` via API endpoint)
- [ ] Create nginx endpoint to receive and serve page context
  - `POST /sn_admin/page-context` — dashboard JS writes current state
  - `GET /sn_admin/page-context` — MCP tool reads current state
  - Store in nginx shared dict or temp file (Lua)
- [ ] Create MCP tool for page context query
  - Tool name: `get_current_page` (returns URL path, query string, page title, draft/live mode)
  - Register via project-level OpenCode config (`templates/default/opencode.json`)
  - MCP server reads from the page-context endpoint
- [ ] Update end-user AGENTS.md (`templates/default/AGENTS.md`) with page awareness instructions
  - Instruct AI to check page context when user requests page-specific edits
  - Document the `get_current_page` tool and when to use it
- [ ] Test end-to-end: navigate in preview → AI queries current page → edits correct file

## Phase 11: Build Error Reporting

> P1: Build errors surfaced to user via AI chat (FR-032).

- [ ] Capture build stdout/stderr in a structured log file (`/data/website/.opencode/build-log.json`)
  - Include exit code, timestamp, truncated output
- [ ] Surface build errors to AI context
  - MCP tool or file-based approach so AI can read last build result
  - AI AGENTS.md instructions to check build status after triggering builds
- [ ] User-friendly error formatting in AI responses
  - AI should summarize the error, suggest fixes, and offer to retry

## Phase 12: Image & Asset Handling

> P1: User-provided image uploads through AI conversation (FR-025).

- [ ] Define asset storage convention (`/data/website/src/assets/` or `public/`)
  - Document in end-user AGENTS.md
- [ ] Ensure AI can reference and place user-provided images in site source
  - Test with common image formats (PNG, JPG, SVG, WebP)
- [ ] Add image optimization guidance to AI context
  - Responsive images, lazy loading, alt text best practices

## Phase 13: Visual Element Selection

> FR-060 through FR-063: Click any element in the preview to give AI precise
> editing context. Depends on Phase 10 (AI Page/URL Awareness).

- [ ] Enable the existing toolbar "Select" button (remove `disabled` attribute)
  - `admin-ui/src/pages/dashboard/index.html` line 84
  - Update tooltip from "coming soon" to active description
- [ ] Implement selection mode in dashboard JS
  - Inject highlight overlay into preview iframe (CSS injection via `contentDocument`)
  - Listen for hover events to highlight elements
  - Listen for click to capture selected element
- [ ] Extract element context on selection
  - Capture: tag name, CSS selector path, text content, bounding box, computed styles
  - Write to page-context endpoint (extend `/sn_admin/page-context` from Phase 9)
- [ ] Extend MCP tool to include element context
  - Extend `get_current_page` or add `get_selected_element` tool
  - Return element details alongside page URL context
- [ ] Update end-user AGENTS.md with element selection instructions
  - Instruct AI to use element context for precise edits
- [ ] Test end-to-end: select element → AI identifies correct file/line → applies targeted edit

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
