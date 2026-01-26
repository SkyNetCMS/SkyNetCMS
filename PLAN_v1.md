# SkyNetCMS Implementation Plan v1.0

This document outlines the step-by-step implementation plan for SkyNetCMS MVP. 

**Execution Model**: Complete features sequentially within each milestone. Move to next milestone only when current is complete.

---

## Progress Overview

| Milestone | Status | Features |
|-----------|--------|----------|
| M1: Project Foundation | **Complete** | 4 features |
| M2: OpenResty/Nginx Layer | **Complete** | 4 features |
| M2.5: First-Time Registration | **Complete** | 7 features |
| M3: OpenCode Integration | **Complete** | 6 features |
| M3.5: Initial Branding & Styling | **Complete** | 6 features |
| M4: Initial Template & Content Serving | **Complete** | 4 features |
| M5: Integration & E2E Testing | **Complete** | 3 features |
| M6: Documentation & MVP Polish | Not Started | 3 features |

> **Note**: Future phase features are tracked in [PRD_v1.md](PRD_v1.md#9-future-phase-backlog), not in this tactical plan.

---

## Milestone 1: Project Foundation

**Goal**: Set up repository structure, tooling, and basic Docker skeleton.

### Feature 1.1: Repository Structure
- [x] Create folder structure as defined in AGENTS.md
  - [x] `docker/` - Dockerfile and compose
  - [x] `docker/scripts/` - Scripts that run inside container
  - [x] `nginx/` - nginx configs (empty, for M2)
  - [-] `nginx/conf.d/` - site configs (skipped for M1, created in M2)
  - [-] `nginx/lua/` - Lua scripts for authentication (skipped for M1, created in M2)
  - [x] `opencode/` - OpenCode system-level configuration
  - [-] `opencode/config/agents/` - System-level agent definitions (created in M3)
  - [-] `opencode/config/skills/` - System-level custom skills (created in M3)
  - [-] `opencode/config/mcp/` - System-level MCP configurations (created in M3)
  - [x] `templates/default/` - Default static template
  - [x] `templates/default/src/` - Template source files
  - [x] `templates/default/.opencode/` - Repo-level OpenCode config (empty, for M3)
- [x] Create placeholder README.md
- [x] Create build.sh wrapper script at root
- [x] Create .gitignore with appropriate entries
- [x] Initialize Git repository (already initialized)

### Feature 1.2: Dockerfile Skeleton
- [x] Create `docker/Dockerfile` with:
  - [x] Node.js 24 Alpine base image
  - [x] OpenResty installation (via Alpine packages)
  - [x] Node.js included in base image
  - [x] Git installation
  - [x] Basic directory structure creation
  - [x] OpenCode installation (via npm)
- [x] Create `docker/docker-compose.yml` for local development
- [x] Document exposed ports (80)
- [x] Document volume mounts (/data)

### Feature 1.3: Environment Configuration
- [x] Define environment variables in Dockerfile
  - [x] `ADMIN_USER`
  - [x] `ADMIN_PASS`
  - [x] `SITE_TITLE`
  - [x] `BUILD_CMD`
- [x] Create `docker/scripts/init.sh` for container startup
  - [x] Environment variable validation
  - [x] Directory initialization
  - [x] Service startup orchestration (stubs for M2+)

### Feature 1.4: Verification
- [x] Docker container builds without errors (ready to test)
- [x] Container starts and stays running (ready to test)
- [x] Environment variables are accessible (ready to test)
- [x] Volume mount works correctly (ready to test)

---

## Milestone 2: OpenResty/Nginx Layer

**Goal**: Configure nginx for routing and authentication.

### Feature 2.1: Basic Nginx Configuration
- [x] Create `nginx/nginx.conf` with:
  - [x] Worker processes configuration
  - [x] Error logging
  - [x] Include directive for conf.d/
- [x] Create `nginx/conf.d/default.conf` with:
  - [x] Server block listening on port 80
  - [x] Root location `/` serving static files
  - [x] Location for `/sn_admin/` with auth
- [x] Verify nginx starts correctly in container (ready to test)

### Feature 2.2: Static File Serving
- [x] Configure `/` location to serve from `/data/website/dist/`
  - [x] index.html as default
  - [x] Proper MIME types (via OpenResty defaults)
  - [-] Caching headers (deferred - not critical for MVP)
- [x] Test static file exists (templates/default/src/index.html)
- [x] Verify static files are served correctly (ready to test)

### Feature 2.3: htpasswd Authentication
- [x] Create `docker/scripts/setup-auth.sh` to generate htpasswd file
  - [x] Use bcrypt hashing (-B flag)
  - [x] Read from `ADMIN_USER` and `ADMIN_PASS` env vars
  - [x] Write to `/data/.htpasswd`
- [x] Configure `/sn_admin/` location with:
  - [x] `auth_basic` directive
  - [x] `auth_basic_user_file` pointing to htpasswd
- [x] Update `docker/scripts/init.sh` to run auth setup on startup
- [x] Verify authentication works (ready to test)

### Feature 2.4: Verification
- [x] Nginx starts without errors (ready to test)
- [x] `/` serves static content (ready to test)
- [x] `/sn_admin/` prompts for authentication (ready to test)
- [x] Valid credentials grant access (ready to test)
- [x] Invalid credentials return 401 (ready to test)
- [x] Health check endpoint `/health` returns OK (ready to test)

---

## Milestone 2.5: First-Time Registration & Dynamic Authentication

**Goal**: Allow first-time admin setup via registration form when env vars not provided, while maintaining backward compatibility with env var approach.

### Feature 2.5.1: Lua Auth Infrastructure
- [x] Create `nginx/lua/` directory
- [x] Create `nginx/lua/auth.lua` module with helper functions:
  - [x] `is_admin_configured()` - checks if `/data/.htpasswd` exists
  - [x] `get_client_ip()` - for rate limiting
- [x] Add `lua_shared_dict` to nginx.conf for rate limiting state
- [x] Update nginx.conf to set `lua_package_path` for custom modules

### Feature 2.5.2: Registration Page
- [x] Create `nginx/admin-registration/` directory
- [x] Create `nginx/admin-registration/index.html` with:
  - [x] Clean, simple registration form
  - [x] Username field
  - [x] Password field (min 8 characters)
  - [x] Confirm password field
  - [x] Client-side validation (password match, min length)
  - [x] SkyNetCMS branding
  - [x] Error message display area
- [x] Create `templates/admin-registration/style.css` (inline or embedded)
- [x] Copy to `/opt/admin-registration/` in Dockerfile

### Feature 2.5.3: Registration Handler (Lua)
- [x] Create `nginx/lua/registration.lua` module:
  - [x] Parse POST form data
  - [x] Validate: non-empty username, password min 8 chars, passwords match
  - [x] Rate limit: max 5 attempts per minute per IP
  - [x] Generate htpasswd entry via `os.execute("htpasswd -cbB ...")` 
  - [x] Write to `/data/.htpasswd`
  - [x] Return JSON success/error response
- [x] Create location `/sn_admin/register` in nginx config:
  - [x] POST only
  - [x] `content_by_lua_file` pointing to registration handler
  - [x] Only accessible when admin not configured

### Feature 2.5.4: Dynamic Auth Routing
- [x] Update `nginx/conf.d/default.conf` for `/sn_admin/` location:
  - [x] Use `rewrite_by_lua_block` to check admin state (runs before auth_basic)
  - [x] If NOT configured: redirect to registration
  - [x] If configured: enforce `auth_basic`
- [x] Create location `/sn_admin/setup/` to serve registration page:
  - [x] Only accessible when admin not configured
  - [x] Redirects to /sn_admin/ when already configured
- [x] Ensure `/sn_admin/` (main admin) still uses auth_basic when configured

### Feature 2.5.5: Update init.sh for Optional Credentials
- [x] Make `ADMIN_USER` and `ADMIN_PASS` environment variables optional
- [x] Update validation logic:
  - [x] If BOTH env vars provided → run `setup-auth.sh` (pre-configured)
  - [x] If NEITHER provided → skip auth setup, log "First-time setup required"
  - [x] If only ONE provided → error and exit (invalid state)
- [x] Update startup messages to reflect auth state
- [x] Set proper permissions on /data for nginx worker (nobody:nogroup)

### Feature 2.5.6: Dockerfile Updates
- [x] Copy `nginx/lua/` to `/etc/nginx/lua/` in container
- [x] Copy `nginx/admin-registration/` to `/opt/admin-registration/`
- [x] Ensure lua modules are accessible

### Feature 2.5.7: Verification
- [x] Test: Container WITH env vars → htpasswd pre-created, auth works immediately
- [x] Test: Container WITHOUT env vars → registration page at `/sn_admin/setup/`
- [x] Test: Registration with valid input → htpasswd created, redirected to admin
- [x] Test: Registration with mismatched passwords → error shown
- [x] Test: Registration with short password (<8) → error shown
- [x] Test: After registration, `/sn_admin/setup/` redirects to `/sn_admin/`
- [x] Test: After registration, `/sn_admin/` requires Basic Auth
- [x] Test: Rate limiting prevents >5 attempts per minute
- [x] Test: Container restart → credentials persist, auth works
- [x] Test: Volume persistence across container recreate

---

## Milestone 3: OpenCode Integration

**Goal**: Embed OpenCode web UI in admin panel using service-injector wrapper mode.

### Feature 3.1: OpenCode Service Setup
- [x] Update `docker/scripts/init.sh` to start `opencode web` in background
- [x] Configure to run in `/data/website/` directory
- [x] Health check loop (max 30s, proceeds when ready)
- [x] Port 3000, localhost only (nginx proxies to it)

### Feature 3.2: Nginx Proxy Configuration
- [x] Add `/sn_admin/oc/` location with proxy to OpenCode
- [x] WebSocket support (`Upgrade`, `Connection` headers)
- [x] Extended timeouts (300s for AI responses)
- [x] Update `/sn_admin/` to serve admin dashboard SPA

### Feature 3.3: Admin Dashboard SPA
- [x] Create `nginx/admin-dashboard/` directory
- [x] Implement wrapper mode with service-injector (CDN)
- [x] Main iframe: `/` (website preview)
- [x] Floating window: `/sn_admin/oc/` (OpenCode UI)
- [x] Open by default, dockable, resizable
- [x] Custom toolbar in floating window header (refresh button, future element selector)

### Feature 3.4: Minimal OpenCode Config
- [x] Create `opencode/config/opencode.json`
- [x] Server settings only (port 3000, hostname 127.0.0.1)
- [x] Disable autoupdate and sharing for container environment

### Feature 3.5: Dockerfile Updates
- [x] Copy `opencode/config/` to `/root/.config/opencode/`
- [x] Copy `nginx/admin-dashboard/` to `/opt/admin-dashboard/`
- [x] Remove old `templates/admin-placeholder/` handling

### Feature 3.6: Verification
- [x] Container builds successfully
- [x] OpenCode starts and health check passes
- [x] Admin dashboard loads with iframe + floating window
- [x] Website preview visible in main iframe
- [x] OpenCode UI functional in floating window
- [x] Drag, resize, dock work as expected

---

## Milestone 3.5: Initial Branding & Styling

**Goal**: Establish foundational branding for SkyNetCMS admin interface.

**Reference**: See [STYLE_GUIDE.md](STYLE_GUIDE.md) for complete branding specification.

**Key Decisions**:
- **Aesthetic**: Dark & Techy (fits "SkyNet" name)
- **Primary Accent**: Cyan `#00d4ff` (replacing original red `#e94560`)
- **Logo**: Hexagonal neural network icon + "SkyNetCMS" text

### Feature 3.5.1: Style Guide Documentation
- [x] Create STYLE_GUIDE.md with complete specification
- [x] Define CSS custom properties (variables)
- [x] Document color palette (dark theme, cyan accent)
- [x] Document typography (system fonts, sizes, weights)
- [x] Document spacing and border radius scales
- [x] Document component patterns (buttons, inputs, cards)

### Feature 3.5.2: Logo Assets
- [x] Create hexagonal neural network SVG icon (`nginx/assets/logo-icon.svg`)
- [x] Create full logo (icon + text) SVG (`nginx/assets/logo.svg`)
- [x] Create compact logo for toolbar (`nginx/assets/logo-compact.svg`)
- [x] Create favicon SVG (`nginx/assets/favicon.svg`)
- [x] Place in `nginx/assets/` directory
- [x] Update Dockerfile to copy assets to `/opt/admin-assets/`
- [x] Add nginx location `/sn_admin/assets/` to serve assets

### Feature 3.5.3: Apply Styles to Admin Dashboard
- [x] Update `nginx/admin-dashboard/index.html` with new color scheme
- [x] Replace red accent (`#e94560`) with cyan (`#00d4ff`)
- [x] Apply CSS custom properties from style guide
- [x] Update floating window header with inline SVG logo
- [x] Add favicon reference

### Feature 3.5.4: Apply Styles to Registration Page
- [x] Update `nginx/admin-registration/index.html` with new color scheme
- [x] Replace red accent with cyan throughout
- [x] Apply CSS custom properties from style guide
- [x] Add inline SVG logo to registration form
- [x] Add favicon reference

### Feature 3.5.5: Floating Window Styling
- [x] Custom header bar with SkyNetCMS logo (inline SVG)
- [x] Action buttons using style guide patterns (ghost buttons)
- [x] Border radius, shadows per style guide
- [x] Tab styling when window collapsed
- [x] SVG icons for refresh/select/minimize buttons

### Feature 3.5.6: Verification
- [x] Admin dashboard renders with new branding
- [x] Registration page renders with new branding
- [x] Logo displays correctly at all sizes
- [x] Assets served correctly at `/sn_admin/assets/`
- [x] Favicon loads correctly
- [x] Manual verification: interactive hover/focus states work
- [x] Manual verification: color contrast meets accessibility standards

---

## Milestone 4: Initial Template & Content Serving

**Goal**: Create welcome template and establish build pipeline.

### Feature 4.1: Welcome Template
- [x] Create `templates/default/src/index.html` with:
  - [x] Clean, simple design
  - [x] "Welcome to SkyNetCMS" heading
  - [x] "Go to /sn_admin/ to start building" call-to-action
  - [x] Basic styling (inline or minimal CSS)
- [x] Create `templates/default/AGENTS.md` for site-building AI context
- [x] Create `templates/default/.opencode/` with repo-level config
- [x] Template should be a good starting point for customization
- [x] Include link to admin panel

### Feature 4.2: First-Run Initialization
- [x] Update `docker/scripts/init.sh` to:
  - [x] Check if `/data/website/` exists
  - [x] If not, initialize Git repo
  - [x] Copy entire `templates/default/` contents to `/data/website/`
  - [-] Copy `opencode/config/` to `~/.config/opencode/` (done in Dockerfile for security)
  - [x] Run initial build
  - [x] Create initial Git commit
- [x] Ensure idempotent (safe to run multiple times)

### Feature 4.3: Build Pipeline
- [-] Create `docker/scripts/build-site.sh` - Obsolete: using Vite (`npm run build`) instead
- [x] Build mechanism via Vite:
  - [x] `vite.config.js` configured (src/ → dist/)
  - [x] `npm run build` command available
  - [-] Auto-trigger (git hook/watcher) - Skipped: manual build sufficient for MVP
- [x] Verify changes in src/ appear in dist/

### Feature 4.4: Verification
- [x] Fresh container shows welcome page at `/`
- [x] Welcome page links to `/sn_admin/`
- [x] Build pipeline runs correctly
- [x] Built content is served by nginx

---

## Milestone 5: Integration & End-to-End Testing

**Goal**: Verify complete user flow works end-to-end.

### Feature 5.1: Full Docker Build
- [x] Finalize Dockerfile with all components
- [x] Optimize image size (multi-stage if needed) - 710MB achieved
- [x] Verify clean build from scratch
- [-] Test with docker-compose - Skipped: direct docker run sufficient for MVP

### Feature 5.2: End-to-End User Flow Testing
- [x] Test: Deploy container with docker run
  - [x] `-p 8080:80`
  - [x] `-v skynetcms-test:/data`
  - [x] `-e ADMIN_USER=admin`
  - [x] `-e ADMIN_PASS=testpass123`
- [x] Test: Visit `/` - see welcome page
- [x] Test: Visit `/sn_admin/` - prompted for auth
- [x] Test: Login with credentials - see OpenCode UI
- [-] Test: Chat with AI - Skipped: requires API key configuration
- [x] Test: Container restart - data persists

### Feature 5.3: Edge Cases & Error Handling
- [x] Test: Invalid credentials - 401 Unauthorized
- [x] Test: Missing environment variables - registration flow works
- [x] Test: Invalid config (partial env vars) - exits with error
- [-] Test: Corrupted Git repo recovery - Deferred: edge case
- [-] Test: Build failure handling - Deferred: edge case
- [-] Test: Large file upload - Not applicable for MVP

> **Note**: Full test results documented in [TESTING.md](TESTING.md) - 36/37 tests passed (1 skipped for API key)

---

## Milestone 6: Documentation & MVP Polish

**Goal**: Prepare for release with documentation and final cleanup.

### Feature 6.1: README Documentation
- [ ] Create comprehensive README.md with:
  - [ ] Project description
  - [ ] Quick start guide (< 5 minutes)
  - [ ] Docker deployment instructions
  - [ ] Environment variables reference
  - [ ] Troubleshooting section
- [ ] Add architecture diagram
- [ ] Add screenshots (welcome page, admin panel)

### Feature 6.2: Code Cleanup
- [ ] Remove debug logging
- [ ] Remove commented-out code
- [ ] Ensure consistent formatting
- [ ] Add code comments where needed
- [ ] Review security settings

### Feature 6.3: Final Verification
- [ ] Fresh deployment test (new machine/environment)
- [ ] All success criteria from PRD met:
  - [ ] User can deploy container with single command
  - [ ] User can access welcome page at `/`
  - [ ] User can authenticate at `/sn_admin/`
  - [ ] User can chat with AI to generate website
  - [ ] Generated website visible at `/`
  - [ ] Changes persist across container restarts
- [ ] Update PLAN_v1.md with completion status

---

## Implementation Notes

### Working with this Plan

1. **Starting a feature**: Mark the feature checkbox as in-progress by adding `[~]`
2. **Completing a task**: Mark with `[x]`
3. **Blocked task**: Add `[BLOCKED: reason]` after the task
4. **Skipped task**: Mark with `[-]` and add reason

### Dependencies

- **M2 depends on M1**: Need Dockerfile before configuring nginx
- **M2.5 depends on M2**: Need nginx/OpenResty working before adding Lua auth
- **M3 depends on M2.5**: Need auth infrastructure before OpenCode integration
- **M3.5 depends on M3**: Need OpenCode dashboard working before branding
- **M4 depends on M3.5**: Need branded dashboard before testing content pipeline
- **M5 depends on M4**: Need all components for E2E testing
- **M6 depends on M5**: Need working system before documentation

### Estimated Effort

| Milestone | Estimated Effort |
|-----------|------------------|
| M1: Project Foundation | 2-4 hours |
| M2: OpenResty/Nginx Layer | 4-6 hours |
| M2.5: First-Time Registration | 3-5 hours |
| M3: OpenCode Integration | 6-10 hours |
| M3.5: Initial Branding | 2-3 hours |
| M4: Initial Template & Content | 4-6 hours |
| M5: Integration & Testing | 4-6 hours |
| M6: Documentation & Polish | 2-4 hours |
| **Total MVP** | **27-44 hours** |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-01-09 | Initial plan created |
| 2026-01-10 | M1 Complete: Project foundation with Node.js 24 Alpine + OpenResty + OpenCode |
| 2026-01-10 | M2 Complete: OpenResty/Nginx layer with routing, static serving, htpasswd auth |
| 2026-01-10 | M2.5 Planned: First-time registration flow with optional env vars |
| 2026-01-11 | M2.5 Complete: First-time registration with Lua auth, rate limiting |
| 2026-01-11 | M3 Complete: OpenCode integration with service-injector wrapper mode dashboard |
| 2026-01-11 | M3.5 Added: New milestone for initial branding & styling |
| 2026-01-20 | M3.5 Complete: Full branding implementation (style guide, logo, dashboard, registration) |
| 2026-01-22 | M4 Complete: Template already implemented with Vite; marked build-site.sh obsolete |
| 2026-01-25 | M5 Complete: Full E2E testing with TESTING.md checklist; 36/37 tests passed |

---

*Update this document as implementation progresses.*
