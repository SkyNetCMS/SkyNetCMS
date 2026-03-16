# SkyNetCMS - Product Requirements Document

## Overview

**SkyNetCMS** is a next-generation Content Management System that enables users to create, edit, and manage websites through conversational AI interactions. Users deploy a single Docker container, log in to an admin panel, and use AI chat to build and modify their website in real-time.

The system wraps OpenCode (a multi-LLM AI assistant) in a Docker container with OpenResty handling routing and authentication. Users chat with AI to generate static websites, with changes immediately visible at the production URL.

**Key Value Proposition**:
- **No coding required**: Build websites through natural language conversation
- **Instant deployment**: One Docker container = fully functional CMS
- **LLM flexibility**: Users choose their preferred AI provider (GPT-4, Claude, etc.)
- **No vendor lock-in**: Generated code is standard HTML/CSS/JS in a Git repo
- **Single-tenant simplicity**: One container, one website, one admin user

## Objectives

- Enable non-technical users to deploy a fully functional website through a single `docker run` command
- Provide a conversational AI interface for website creation and editing without coding knowledge
- Achieve time-to-first-website under 30 minutes for new users
- Maintain deployment success rate above 95%
- Ensure 80%+ of users can modify their site without external help
- Deliver a secure, single-tenant architecture with persistent storage across container restarts

## Target Audience

| Persona | Technical Level | Primary Need | Use Case |
|---------|----------------|--------------|----------|
| Small Business Owner | Low | Quick professional web presence | Restaurant, shop, or service website |
| Content Creator | Low-Medium | Portfolio or blog site | Photography showcase, writer portfolio |
| Freelance Developer | High | Rapid prototyping for clients | Quick mockups and landing pages |
| Marketing Team Member | Low-Medium | Landing pages without dev dependency | Campaign pages, product launches |

**Deployment Model**: Single-Tenant Architecture — each SkyNetCMS instance serves one website with one admin user. This simplifies security (no multi-user permission complexity), resource management (predictable container resources), and data isolation (each site is completely independent).

## Features

| Feature | Priority | Description |
|---------|----------|-------------|
| Docker single-command deployment | P0 | Container starts with `docker run`, exposes port 80, persists via volume |
| Public website serving | P0 | `/` serves static content from built site (main branch) |
| Admin panel with authentication | P0 | `/sn_admin/` requires htpasswd auth (bcrypt), serves dashboard |
| OpenCode AI chat interface | P0 | Embedded in admin panel, supports multi-LLM provider selection |
| AI file operations | P0 | Create, edit, delete files in site source directory via conversation |
| Git-based version control | P0 | Auto-commit changes, full history in Git repo |
| Vite build pipeline | P0 | `npm run build` compiles src/ to dist/, served by nginx |
| Welcome template | P0 | Fresh container shows welcome page directing to admin panel |
| First-time registration flow | P0 | Web-based admin setup when env vars not provided |
| Environment variable config | P0 | ADMIN_USER, ADMIN_PASS, SITE_TITLE, BUILD_CMD configurable |
| Draft/publish workflow | P1 | Git worktrees for isolated editing, dev preview at `/sn_admin/dev/` |
| Rollback capability | P1 | Auto-tagging on publish, reset to previous versions via chat |
| Image/asset handling | P1 | User-provided image uploads through AI conversation |
| Build error reporting | P1 | Build errors surfaced to user via AI chat |

## User Stories

As a **small business owner**, I want to deploy a website by running a single Docker command so that I don't need to hire a developer.
- Acceptance Criteria:
  - [x] `docker run -p 80:80 -v data:/data skynetcms` starts the system
  - [x] Welcome page appears at `/` on first visit
  - [x] Admin panel accessible at `/sn_admin/`

As a **content creator**, I want to describe my website in plain English so that the AI builds it for me.
- Acceptance Criteria:
  - [x] OpenCode chat interface loads in the admin panel
  - [x] AI can create HTML/CSS/JS files from natural language requests
  - [x] Changes appear at `/` after build

As a **first-time user**, I want to set up my admin credentials through a web form so that I don't need to use environment variables.
- Acceptance Criteria:
  - [x] Registration page appears when no credentials are configured
  - [x] Password validation (min 8 chars, confirmation match)
  - [x] After registration, admin panel requires Basic Auth

As a **site owner**, I want to preview changes before they go live so that visitors don't see unfinished work.
- Acceptance Criteria:
  - [x] Draft worktree isolates changes from live site
  - [x] Preview available at `/sn_admin/dev/`
  - [x] Publish merges draft to main and rebuilds

As a **site owner**, I want to roll back to a previous version if something goes wrong.
- Acceptance Criteria:
  - [x] Auto-tagging before each publish (`pre-publish-YYYYMMDD-HHMMSS`)
  - [x] AI can list and restore previous versions

## Functional Requirements

- FR-001: Container must start with single `docker run` command
- FR-002: Admin credentials configurable via environment variables
- FR-003: Site data persisted via Docker volume at `/data`
- FR-004: Container must expose single HTTP port (80)
- FR-010: `/` serves static content from built site (`/data/website/dist/`)
- FR-011: `/sn_admin/` requires htpasswd authentication
- FR-012: Failed auth returns 401 with retry prompt
- FR-013: Authenticated users see OpenCode UI in admin dashboard
- FR-020: OpenCode UI allows LLM provider selection
- FR-021: AI can create new files in site source directory
- FR-022: AI can edit existing files
- FR-023: AI can delete files
- FR-024: AI auto-commits changes to Git
- FR-025: AI can handle user-provided images
- FR-030: Build process triggered after Git commits
- FR-031: Build output placed in nginx-served directory (`/data/website/dist/`)
- FR-032: Build errors reported to user via AI chat
- FR-040: Fresh container shows welcome page at `/`
- FR-041: Welcome page directs user to `/sn_admin/`
- FR-042: Welcome page is editable template (becomes first site content)

## Non-functional Requirements

**Performance**:
- Static page load time: < 2 seconds
- OpenCode UI load time: < 5 seconds
- Build process completion: < 30 seconds for simple sites

**Security**:
- Admin panel must not be accessible without authentication
- htpasswd file must use bcrypt hashing
- AI must not be able to modify nginx configuration
- AI must not expose secrets in generated code

**Reliability**:
- Container must restart cleanly after crash
- Git repo must survive container restarts (volume)
- Corrupted build must not break existing site (atomic deploy)

**Usability**:
- No technical knowledge required to use AI chat
- Error messages must be user-friendly
- README must enable deployment in < 15 minutes

## Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Time to first website | < 30 minutes | From docker run to visible custom site |
| Deployment success rate | > 95% | Container starts and serves content without errors |
| User self-sufficiency | > 80% | Users can modify site without external help |
| Static page load time | < 2 seconds | Browser network tab measurement |
| Build process time | < 30 seconds | Timer from commit to dist/ update |

## Timeline

| Milestone | Status | Description |
|-----------|--------|-------------|
| M1: Project Foundation | Complete | Repository structure, Dockerfile, environment config |
| M2: OpenResty/Nginx Layer | Complete | Routing, static serving, htpasswd auth |
| M2.5: First-Time Registration | Complete | Lua auth, registration flow, rate limiting |
| M3: OpenCode Integration | Complete | Web UI proxy, admin dashboard SPA |
| M3.5: Branding & Styling | Complete | Style guide, logos, dark theme with cyan accent |
| M4: Template & Content Serving | Complete | Welcome template, Vite build pipeline |
| M5: Integration & E2E Testing | Complete | 36/37 tests passed |
| M6: Documentation & MVP Polish | Complete | README, security hardening, code cleanup |

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Container                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              OpenResty (Nginx + Lua)                 │    │
│  │  ┌─────────────┐         ┌────────────────────┐     │    │
│  │  │     /       │         │    /sn_admin/      │     │    │
│  │  │  (public)   │         │  (htpasswd auth)   │     │    │
│  │  └──────┬──────┘         └─────────┬──────────┘     │    │
│  └─────────┼──────────────────────────┼────────────────┘    │
│            ▼                          ▼                      │
│  ┌─────────────────┐         ┌─────────────────┐            │
│  │  Static Content │         │    OpenCode     │            │
│  │  (from main     │         │   (AI Chat UI   │            │
│  │   branch build) │         │    in iframe)   │            │
│  └─────────────────┘         └────────┬────────┘            │
│                                       │                      │
│                              ┌────────▼────────┐            │
│                              │   Git Repo      │            │
│                              │   (on volume)   │            │
│                              └─────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| Entry Point | OpenResty (Nginx + Lua) | Routing, authentication, static serving |
| AI Backend | OpenCode | Chat interface, code generation, session management |
| Authentication | htpasswd | Simple file-based auth for admin access |
| Storage | Git repository | Source of truth for all website content |
| Content Serving | Nginx static files | Serves built website from main branch |

### Request Flow

**Public Access (`/`)**:
```
User → Nginx → Static files from /data/website/dist/
```

**Admin Access (`/sn_admin/`)**:
```
User → Nginx → htpasswd auth → Admin Dashboard
                                      ↓
                               OpenCode AI Chat
                                      ↓
                               AI generates code
                                      ↓
                               Git commit
                                      ↓
                               Build process
                                      ↓
                               Updated /data/website/dist/
```

## Technical Specifications

### Container Contents

```
/
├── /usr/local/openresty/     # OpenResty installation
├── /app/opencode/            # OpenCode installation
├── ~/.config/opencode/       # System-level OpenCode config (from opencode/config/)
├── /data/                    # Mounted volume
│   ├── website/              # Git repository (from templates/default/)
│   │   ├── src/              # Source files (AI edits here)
│   │   ├── dist/             # Built output (served by nginx)
│   │   ├── .opencode/        # Repo-level OpenCode config
│   │   └── AGENTS.md         # AI context for site building
│   └── auth/                 # Authentication files (www-data owned)
│       └── .htpasswd         # htpasswd file
└── /etc/nginx/               # Nginx configuration
```

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ADMIN_USER` | No | - | Admin username (optional if using registration flow) |
| `ADMIN_PASS` | No | - | Admin password (optional if using registration flow) |
| `SITE_TITLE` | No | "SkyNetCMS" | Default site title |
| `BUILD_CMD` | No | `npm run build` | Custom build command |

### Ports & Volumes

| Port | Purpose |
|------|---------|
| 80 | HTTP (nginx) |

| Volume | Mount Point | Purpose |
|--------|-------------|---------|
| `skynet-data` | `/data` | Persistent storage for Git repo and auth |

### Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Base Image | Alpine Linux | 3.19+ |
| Web Server | OpenResty | 1.25+ |
| AI Platform | OpenCode | Latest (SkyNetCMS fork) |
| Runtime | Node.js | 24 LTS |
| Version Control | Git | 2.x |

## MVP Scope

### Definition

The Minimum Viable Product delivers:

1. Deployable Docker container with all components pre-configured
2. Public website access at root URL (`/`)
3. Protected admin panel at `/sn_admin/` with htpasswd authentication
4. OpenCode AI chat interface embedded in admin panel
5. Static site generation through AI conversation
6. Welcome template displayed on first run
7. Git-based storage for all generated content

### Constraints

- Single user only: One admin per container
- Static sites only: No server-side rendering
- No custom domains: User handles DNS/reverse proxy externally
- No SSL built-in: Handled by external reverse proxy

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| OpenCode integration complexity | Medium | High | Start with iframe embed, minimal coupling |
| AI generates broken code | Medium | Medium | Build process validates output, atomic deploys |
| htpasswd security concerns | Low | Medium | Use bcrypt, document HTTPS requirement |
| Container size too large | Medium | Low | Multi-stage Docker build, Alpine base |
| User confusion with chat-only interface | Medium | Medium | Good welcome template, clear instructions |

## Future Phase Backlog

Features explicitly deferred from MVP. This is the canonical list of future enhancements.

### Git & Version Control
- [x] **Draft/Publish workflow with git worktrees** (implemented v1.1)
- [x] **Rollback to previous versions via chat** (implemented v1.1)
- [ ] Push to external Git (GitHub, GitLab)
- [ ] Visual diff comparison in UI
- [ ] "Publish" button in dashboard (currently AI-only)

### User Interface Enhancements
- [ ] File browser in admin panel
- [ ] Visual element selection (service-injector integration)
- [ ] Side-by-side preview panel
- [ ] Slash commands (`/publish`, `/preview`, `/branch`)
- [ ] Drag-and-drop file upload UI

### Framework Support
- [ ] Vue.js project scaffolding and build
- [ ] React project scaffolding and build
- [ ] Next.js/Nuxt.js SSR support
- [ ] Custom build pipeline configuration UI

### Hosting & Deployment
- [ ] Custom domain configuration
- [ ] Built-in SSL/HTTPS (Let's Encrypt integration)
- [ ] Multi-site from single container
- [ ] CDN integration
- [ ] Automatic backup to cloud storage

### Operations & Monitoring
- [ ] Logging and monitoring dashboard
- [ ] Usage analytics
- [ ] Error tracking integration

### Authentication Enhancements
- [ ] Session-based authentication with custom login form
- [ ] Logout functionality
- [ ] Password reset mechanism
- [ ] "Remember me" functionality
- [ ] Admin password change via admin panel UI

### Collaboration
- [ ] Multiple admin users
- [ ] Role-based permissions
- [ ] Edit history / audit log
- [ ] Real-time collaboration

## Glossary

| Term | Definition |
|------|------------|
| SkyNetCMS | The product being built — AI-powered conversational CMS |
| OpenCode | The embedded AI assistant platform |
| OpenResty | Nginx with Lua scripting support |
| htpasswd | Apache-style password file authentication |
| MCP | Model Context Protocol — OpenCode's tool interface |

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-09 | AI Assistant | Initial version based on requirements gathering |
| 1.1 | 2026-02-06 | AI Assistant | Added draft/publish workflow with git worktrees |
| 1.2 | 2026-03-15 | AI Assistant | Restructured to /prd command format; added Objectives, User Stories, Success Metrics, Timeline sections |
