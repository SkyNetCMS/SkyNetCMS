---
id: AGENTS
aliases: []
tags: []
---
# AGENTS.md - AI Development Guidelines for SkyNetCMS

This document provides guidelines for AI assistants (OpenCode, Claude, etc.) working on the **SkyNetCMS** project development.

> **Important**: This document is about developing SkyNetCMS itself, NOT about the AI that will run inside SkyNetCMS to help end-users build websites.

---

## 1. Project Overview

**SkyNetCMS** is a next-generation CMS that enables users to create, edit, and manage websites through conversational AI interactions. The system embeds OpenCode as its AI backbone, wrapped in a Docker container with OpenResty (Nginx + Lua) handling routing and authentication.

### Core Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Docker Container                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │               OpenResty (Nginx + Lua)                      │  │
│  │  ┌─────────────┐    ┌──────────────┐   ┌───────────────┐  │  │
│  │  │     /       │    │ /sn_admin/   │   │ /sn_admin/oc/ │  │  │
│  │  │  (static)   │    │ (dashboard)  │   │  (OpenCode)   │  │  │
│  │  └──────┬──────┘    └──────┬───────┘   └───────┬───────┘  │  │
│  └─────────┼─────────────────┼───────────────────┼───────────┘  │
│            ▼                 ▼                   ▼               │
│  ┌─────────────────┐  ┌─────────────────────────────────────┐   │
│  │  Built site     │  │      Admin Dashboard (SPA)          │   │
│  │  /data/repo/    │  │  ┌─────────────────────────────┐    │   │
│  │  dist/          │  │  │   Main IFRAME: /            │    │   │
│  └─────────────────┘  │  │   (website preview)         │    │   │
│                       │  └─────────────────────────────┘    │   │
│                       │  ┌─────────────────┐                │   │
│                       │  │ Floating Window │ ← OpenCode     │   │
│                       │  │ /sn_admin/oc/   │   Web UI       │   │
│                       │  └─────────────────┘                │   │
│                       └────────────────────────────┬────────┘   │
│                                                    │            │
│                       ┌────────────────────────────▼────────┐   │
│                       │  OpenCode Server (port 3000)        │   │
│                       │  Working dir: /data/repo/           │   │
│                       └────────────────────────────┬────────┘   │
│                                                    │            │
│                       ┌────────────────────────────▼────────┐   │
│                       │          Git Repo                   │   │
│                       │          /data/repo/                │   │
│                       └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Admin Dashboard Architecture

The admin panel uses [service-injector](https://github.com/OrienteerBAP/service-injector) in **wrapper mode**:

- **Main IFRAME**: Displays the live website (`/`) for real-time preview
- **Floating Window**: Contains OpenCode AI interface (`/sn_admin/oc/`)
- **Features**: Draggable, resizable, dockable to screen edges
- **Toolbar**: Refresh preview button, future element selector

### Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| AI Backend | OpenCode | Multi-LLM support, sessions, agents/skills built-in |
| Web Server | OpenResty | Nginx performance + Lua for auth logic |
| Authentication | htpasswd | Simple, no database needed for MVP |
| Database | None | Git repo is source of truth |
| Container | Single Dockerfile | One container = one website = one admin |
| Framework Support | Static first | Vue/React supported but static is MVP focus |

---

## 2. Repository Structure

```
SkyNetCMS/
├── AGENTS.md              # This file - AI development guidelines
├── PRD_v1.md              # Product requirements document
├── PLAN_v1.md             # Implementation plan with milestones
├── Idea.md                # Original idea document
├── PRD_Initial.md         # Initial PRD draft
├── README.md              # Deployment documentation
├── build.sh               # Simple wrapper to build Docker image
│
├── docker/
│   ├── Dockerfile         # Main container definition
│   ├── docker-compose.yml # For local development/testing
│   └── scripts/           # Scripts that run INSIDE container
│       ├── init.sh        # Container startup/initialization
│       ├── setup-auth.sh  # htpasswd generation
│       └── build-site.sh  # Trigger site build
│
├── nginx/
│   ├── nginx.conf         # Main nginx configuration
│   ├── admin-dashboard/   # Admin SPA with service-injector
│   │   └── index.html     # Dashboard with iframe + floating window
│   ├── admin-registration/ # First-time admin setup page
│   │   └── index.html     # Registration form
│   ├── conf.d/
│   │   └── default.conf   # Site routing rules
│   └── lua/
│       ├── auth.lua       # Auth helper module
│       └── registration.lua # Registration POST handler
│
├── opencode/
│   └── config/            # → Copied to ~/.config/opencode/ in container
│       ├── opencode.json  # Minimal server configuration
│       ├── agent/         # System-level agent definitions (future)
│       └── skill/         # System-level custom skills (future)
│
└── templates/
    └── default/           # Default static template (MVP)
        ├── src/           # Source files for initial site
        │   └── index.html # Welcome page
        ├── .opencode/     # Repo-level OpenCode config (CWD context)
        │   └── ...        # Per-site agent configs
        └── AGENTS.md      # AI instructions for site building
```

### OpenCode Configuration Hierarchy

| Location | Copied To (in container) | Purpose |
|----------|--------------------------|---------|
| `opencode/config/` | `~/.config/opencode/` | System-level OpenCode config (global settings, platform agents) |
| `templates/default/.opencode/` | `/data/repo/.opencode/` | Repo-level config (site-specific AI context, CWD) |

OpenCode reads both: system config from `~/.config/opencode/` and repo-level from `.opencode/` in its working directory (`/data/repo/`).

---

## 3. Development Guidelines

### 3.1 Code Style & Conventions

- **JavaScript/Node.js**: Use ES modules, async/await, consistent formatting
- **Nginx configs**: Use clear comments, group related directives
- **Lua**: Follow OpenResty best practices, minimal dependencies
- **Shell scripts**: Use `#!/bin/bash`, include error handling (`set -e`)
- **Documentation**: Keep README.md updated with any deployment changes
- **Planning**: Keep PLAN_v1.md updated for tactical MVP implementation. Future phase features are tracked in PRD_v1.md (Section 9)

### 3.2 File Naming

- Use lowercase with hyphens for files: `build-site.sh`, `default.conf`
- Use PascalCase for documentation: `AGENTS.md`, `README.md`
- Configuration files: use standard names expected by tools

### 3.3 Git Practices

- Commit messages: Clear, descriptive, present tense ("Add nginx configuration")
- Keep commits atomic - one logical change per commit
- The `master` branch should always be deployable

### 3.4 Docker Guidelines

- Minimize layers in Dockerfile
- Use multi-stage builds if needed
- Document all exposed ports and volumes
- Use environment variables for configuration that may change

---

## 4. Key Components to Understand

### 4.1 OpenResty/Nginx

**Purpose**: Entry point for all requests, handles routing and authentication.

**Key files**:
- `nginx/nginx.conf` - Main configuration
- `nginx/conf.d/default.conf` - Site routing rules

**Routing logic**:
- `/` → Serve static content from `/data/repo/dist/`
- `/sn_admin/setup/` → First-time registration (when no admin configured)
- `/sn_admin/register` → POST handler for registration
- `/sn_admin/oc/` → htpasswd auth → Proxy to OpenCode Web UI
- `/sn_admin/` → htpasswd auth → Admin Dashboard SPA (catch-all, MUST BE LAST)

**IMPORTANT - Nginx Location Order**:
The `/sn_admin/` location uses prefix matching and must be the LAST `/sn_admin/*` 
location block in the config. More specific locations must come before it:
```
1. /sn_admin/setup/   - registration page (Lua access control)
2. /sn_admin/register - POST handler (Lua content handler)
3. /sn_admin/oc/      - OpenCode proxy (auth_basic)
4. /sn_admin/         - dashboard catch-all (auth_basic) - MUST BE LAST
```

### 4.2 OpenCode Integration

**Purpose**: AI chat interface for website editing.

**Key points**:
- OpenCode runs as a service inside the container
- Web UI is embedded in an iframe at `/sn_admin/`
- User selects their LLM provider through OpenCode UI
- OpenCode sessions persist work in the Git repo

**Configuration needed**:
- Pre-configured agents/skills for website building
- MCP tools for file operations, git, build triggers
- System prompts tailored for SkyNetCMS context

### 4.3 Git Repository

**Purpose**: Source of truth for all website content.

**MVP behavior**:
- AI works directly on `master` branch
- Changes auto-committed by AI
- Build process generates `dist/` from source

**Future behavior**:
- Session-linked branches
- Merge to `master` = publish

### 4.4 Build Pipeline

**Purpose**: Transform source files into servable content.

**MVP approach**:
- Simple script that copies/processes files
- Triggered after AI commits changes
- Output to `/data/repo/dist/` directory

### 4.5 Authentication Flow

**Purpose**: Secure admin access with optional first-time registration.

#### First-Time Setup Flow (No Admin Configured)

```
User visits /sn_admin/
       │
       ▼
Nginx Lua: is_admin_configured()? → NO (no /data/.htpasswd)
       │
       ▼
Redirect 302 → /sn_admin/setup/
       │
       ▼
User sees registration form (username, password, confirm password)
       │
       ▼
User submits form → POST /sn_admin/register
       │
       ▼
Lua validates: non-empty username, password >= 8 chars, passwords match
       │
       ▼
Lua creates /data/.htpasswd using htpasswd command
       │
       ▼
JSON response: { "success": true, "redirect": "/sn_admin/" }
       │
       ▼
JavaScript redirects to /sn_admin/
```

#### Subsequent Visits Flow (Admin Configured)

```
User visits /sn_admin/
       │
       ▼
Nginx Lua: is_admin_configured()? → YES (/data/.htpasswd exists)
       │
       ▼
Nginx: auth_basic "SkyNetCMS Admin"
       │
       ▼
Browser prompts for Basic Auth credentials
       │
       ▼
User enters username + password
       │
       ▼
Nginx validates against /data/.htpasswd → SUCCESS
       │
       ▼
Admin Dashboard SPA loads (service-injector wrapper mode)
       │
       ├── Main iframe loads: /  (public website, no auth needed)
       │
       └── Floating window iframe loads: /sn_admin/oc/
              │
              ▼
       Browser automatically sends same Authorization header
       (same origin, same realm "SkyNetCMS Admin")
              │
              ▼
       Nginx validates at /sn_admin/oc/ → SUCCESS
              │
              ▼
       OpenCode Web UI loads in floating window
```

#### Key Authentication Points

| Endpoint | Auth Type | When Protected |
|----------|-----------|----------------|
| `/` | None | Never (public website) |
| `/sn_admin/setup/` | Lua check | Only when admin NOT configured |
| `/sn_admin/register` | Lua check | Only when admin NOT configured |
| `/sn_admin/oc/` | htpasswd | Always when admin IS configured |
| `/sn_admin/` | htpasswd | Always when admin IS configured |

#### Browser Auth Header Propagation

When the admin dashboard loads at `/sn_admin/`, it embeds OpenCode via iframe at 
`/sn_admin/oc/`. The browser automatically sends the `Authorization` header to the
iframe request because:

1. **Same Origin**: Both URLs are on the same domain
2. **Same Realm**: Both locations use `auth_basic "SkyNetCMS Admin"`
3. **Same htpasswd**: Both validate against `/data/.htpasswd`

This means the user only enters credentials ONCE when accessing `/sn_admin/`.
The iframe to `/sn_admin/oc/` receives the same credentials automatically.

---

## 5. What NOT to Do

### Security Boundaries

- **NEVER** expose OpenCode UI without authentication
- **NEVER** allow AI to modify nginx configuration at runtime
- **NEVER** store secrets in Git repository
- **NEVER** run arbitrary user commands outside of sandboxed context

### Development Anti-patterns

- **AVOID** adding database dependencies for MVP
- **AVOID** over-engineering - keep it simple
- **AVOID** framework-specific code in core infrastructure
- **AVOID** breaking the single-container model

### Scope Boundaries

- **DO NOT** implement features marked as "Future Phase" unless explicitly requested
- **DO NOT** add monitoring/logging infrastructure (Future Phase)
- **DO NOT** implement multi-user/collaboration features (Future Phase)
- **DO NOT** add external Git push functionality (Future Phase)

---

## 6. Testing Approach

### Local Development Testing

1. Build Docker container: `docker build -t skynetcms .`
2. Run container: `docker run -p 8080:80 -v skynet-data:/data skynetcms`
3. Access `/` - should see welcome page
4. Access `/sn_admin/` - should prompt for auth, then show OpenCode UI
5. Chat with AI to modify site - changes should reflect at `/`

### Verification Checklist

- [ ] Container builds without errors
- [ ] Nginx starts and serves content
- [ ] htpasswd authentication works at `/sn_admin/`
- [ ] OpenCode UI loads in iframe
- [ ] AI can read/write files in Git repo
- [ ] Changes to source files reflect at `/` after build

---

## 7. Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ADMIN_USER` | No* | - | htpasswd username |
| `ADMIN_PASS` | No* | - | htpasswd password |
| `SITE_TITLE` | No | SkyNetCMS | Default site title |
| `BUILD_CMD` | No | `./build.sh` | Custom build command |

*`ADMIN_USER` and `ADMIN_PASS` are optional. If both are provided, admin is pre-configured. If neither is provided, a first-time registration form will be shown at `/sn_admin/`. Providing only one will cause an error.

---

## 8. Common Tasks

### Adding a New Nginx Route

1. Edit `nginx/conf.d/default.conf`
2. Add location block with appropriate proxy/static config
3. Test with `nginx -t` inside container
4. Document the route in README.md

### Modifying OpenCode Configuration

1. Edit files in `opencode/config/`
2. Agents go in `opencode/config/agents/`
3. Skills go in `opencode/config/skills/`
4. Restart OpenCode service to apply changes

### Updating Welcome Template

1. Edit files in `templates/default/`
2. These are copied to `/data/repo/` on first run
3. Ensure template includes link to `/sn_admin/`

---

## 9. Troubleshooting

### Nginx won't start
- Check logs: `docker logs <container>`
- Validate config: `nginx -t`
- Common issue: missing semicolons in config

### OpenCode not accessible
- Verify it's running: `ps aux | grep opencode`
- Check proxy configuration in nginx
- Verify authentication is working

### Changes not appearing at `/`
- Check if build process ran
- Verify `dist/` directory contents
- Check nginx is serving from correct directory

### Git issues
- Verify repo initialized: `git status` in `/data/repo`
- Check file permissions
- Ensure AI has write access to repo directory

---

## 10. References

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenResty Documentation](https://openresty.org/en/docs.html)
- [service-injector Library](https://github.com/OrienteerBAP/service-injector) (admin dashboard wrapper)

---

*This document should be updated as the project evolves. When making significant architectural changes, update this file accordingly.*
