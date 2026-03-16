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
