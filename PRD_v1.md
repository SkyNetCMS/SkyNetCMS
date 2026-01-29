# Product Requirements Document (PRD) v1.0
## SkyNetCMS - AI-Powered Conversational CMS

---

## 1. Executive Overview

### 1.1 Product Vision

**SkyNetCMS** is a next-generation Content Management System that enables users to create, edit, and manage websites through conversational AI interactions. Users deploy a single Docker container, log in to an admin panel, and use AI chat to build and modify their website in real-time.

### 1.2 Product Summary

SkyNetCMS transforms website creation from traditional form-based interfaces to conversational interactions. The system wraps OpenCode (a multi-LLM AI assistant) in a Docker container with OpenResty handling routing and authentication. Users chat with AI to generate static websites, with changes immediately visible at the production URL.

### 1.3 Key Value Proposition

- **No coding required**: Build websites through natural language conversation
- **Instant deployment**: One Docker container = fully functional CMS
- **LLM flexibility**: Users choose their preferred AI provider (GPT-4, Claude, etc.)
- **No vendor lock-in**: Generated code is standard HTML/CSS/JS in a Git repo
- **Single-tenant simplicity**: One container, one website, one admin user

---

## 2. Target Audience

### 2.1 Primary Users

| Persona | Technical Level | Primary Need | Use Case |
|---------|----------------|--------------|----------|
| Small Business Owner | Low | Quick professional web presence | Restaurant, shop, or service website |
| Content Creator | Low-Medium | Portfolio or blog site | Photography showcase, writer portfolio |
| Freelance Developer | High | Rapid prototyping for clients | Quick mockups and landing pages |
| Marketing Team Member | Low-Medium | Landing pages without dev dependency | Campaign pages, product launches |

### 2.2 Deployment Model

**Single-Tenant Architecture**: Each SkyNetCMS instance serves one website with one admin user. This simplifies:
- Security (no multi-user permission complexity)
- Resource management (predictable container resources)
- Data isolation (each site is completely independent)

---

## 3. System Architecture

### 3.1 High-Level Architecture

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
│  │  (from master   │         │   (AI Chat UI   │            │
│  │   branch build) │         │    in iframe)   │            │
│  └─────────────────┘         └────────┬────────┘            │
│                                       │                      │
│                              ┌────────▼────────┐            │
│                              │   Git Repo      │            │
│                              │   (on volume)   │            │
│                              └─────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Core Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| Entry Point | OpenResty (Nginx + Lua) | Routing, authentication, static serving |
| AI Backend | OpenCode | Chat interface, code generation, session management |
| Authentication | htpasswd | Simple file-based auth for admin access |
| Storage | Git repository | Source of truth for all website content |
| Content Serving | Nginx static files | Serves built website from master branch |

### 3.3 Request Flow

**Public Access (`/`)**:
```
User → Nginx → Static files from /data/website/dist/
```

**Admin Access (`/sn_admin/`)**:
```
User → Nginx → htpasswd auth → OpenCode Web UI (iframe)
                                      ↓
                               AI generates code
                                      ↓
                               Git commit to master
                                      ↓
                               Build process runs
                                      ↓
                               Updated /data/website/dist/
```

---

## 4. MVP Scope

### 4.1 MVP Definition

The Minimum Viable Product delivers:

1. **Deployable Docker container** with all components pre-configured
2. **Public website access** at root URL (`/`)
3. **Protected admin panel** at `/sn_admin/` with htpasswd authentication
4. **OpenCode AI chat interface** embedded in admin panel
5. **Static site generation** through AI conversation
6. **Welcome template** displayed on first run
7. **Git-based storage** for all generated content

### 4.2 MVP User Flow

```
1. User deploys Docker container
   └── docker run -p 80:80 -v data:/data skynetcms

2. User visits / 
   └── Sees welcome page: "Welcome to SkyNetCMS - go to /sn_admin/ to start"

3. User visits /sn_admin/
   └── Prompted for htpasswd credentials
   └── Sees OpenCode AI chat interface

4. User chats with AI
   └── "Create a landing page for my coffee shop called Bean There"
   └── AI generates HTML/CSS/JS files
   └── AI commits to Git repo
   └── Build process runs

5. User visits /
   └── Sees generated coffee shop website

6. User continues editing via chat
   └── "Add a menu section with prices"
   └── Changes reflected at / after build
```

### 4.3 MVP Constraints

- **Single user only**: One admin per container
- **Static sites only**: No server-side rendering in MVP
- **No custom domains**: User handles DNS/reverse proxy externally
- **No SSL built-in**: Handled by external reverse proxy
- **Master branch only**: No branching workflow in MVP

---

## 5. Functional Requirements

### 5.1 Container & Deployment

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | Container must start with single `docker run` command | Must |
| FR-002 | Admin credentials configurable via environment variables | Must |
| FR-003 | Site data persisted via Docker volume | Must |
| FR-004 | Container must expose single HTTP port (80) | Must |

### 5.2 Routing & Authentication

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-010 | `/` serves static content from built site | Must |
| FR-011 | `/sn_admin/` requires htpasswd authentication | Must |
| FR-012 | Failed auth returns 401 with retry prompt | Must |
| FR-013 | Authenticated users see OpenCode UI in iframe | Must |

### 5.3 AI & Content Generation

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-020 | OpenCode UI allows LLM provider selection | Must |
| FR-021 | AI can create new files in site source directory | Must |
| FR-022 | AI can edit existing files | Must |
| FR-023 | AI can delete files | Must |
| FR-024 | AI auto-commits changes to Git | Must |
| FR-025 | AI can upload/handle user-provided images | Should |

### 5.4 Build & Serve Pipeline

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-030 | Build process triggered after Git commits | Must |
| FR-031 | Build output placed in nginx-served directory | Must |
| FR-032 | Build errors reported to user via AI chat | Should |

### 5.5 First-Run Experience

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-040 | Fresh container shows welcome page at `/` | Must |
| FR-041 | Welcome page directs user to `/sn_admin/` | Must |
| FR-042 | Welcome page is editable template (becomes first site content) | Must |

---

## 6. Non-Functional Requirements

### 6.1 Performance

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-001 | Static page load time | < 2 seconds |
| NFR-002 | OpenCode UI load time | < 5 seconds |
| NFR-003 | Build process completion | < 30 seconds for simple sites |

### 6.2 Security

| ID | Requirement |
|----|-------------|
| NFR-010 | Admin panel must not be accessible without authentication |
| NFR-011 | htpasswd file must use bcrypt hashing |
| NFR-012 | AI must not be able to modify nginx configuration |
| NFR-013 | AI must not expose secrets in generated code |

### 6.3 Reliability

| ID | Requirement |
|----|-------------|
| NFR-020 | Container must restart cleanly after crash |
| NFR-021 | Git repo must survive container restarts (volume) |
| NFR-022 | Corrupted build must not break existing site (atomic deploy) |

### 6.4 Usability

| ID | Requirement |
|----|-------------|
| NFR-030 | No technical knowledge required to use AI chat |
| NFR-031 | Error messages must be user-friendly |
| NFR-032 | README must enable deployment in < 15 minutes |

---

## 7. Technical Specifications

### 7.1 Container Contents

```
/
├── /usr/local/openresty/     # OpenResty installation
├── /app/opencode/            # OpenCode installation
├── ~/.config/opencode/       # System-level OpenCode config (copied from opencode/config/)
├── /data/                    # Mounted volume
│   ├── repo/                 # Git repository (copied from templates/default/)
│   │   ├── src/              # Source files (AI edits here)
│   │   ├── dist/             # Built output (served by nginx)
│   │   ├── .opencode/        # Repo-level OpenCode config
│   │   └── AGENTS.md         # AI context for site building
│   └── .htpasswd             # Authentication file
└── /etc/nginx/               # Nginx configuration
```

### 7.2 Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ADMIN_USER` | Yes | - | Admin username for htpasswd |
| `ADMIN_PASS` | Yes | - | Admin password for htpasswd |
| `SITE_TITLE` | No | "SkyNetCMS" | Default site title |
| `BUILD_CMD` | No | `./build.sh` | Custom build command |

### 7.3 Ports & Volumes

| Port | Purpose |
|------|---------|
| 80 | HTTP (nginx) |

| Volume | Mount Point | Purpose |
|--------|-------------|---------|
| `skynet-data` | `/data` | Persistent storage for Git repo and auth |

### 7.4 Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Base Image | Alpine Linux | 3.19+ |
| Web Server | OpenResty | 1.25+ |
| AI Platform | OpenCode | Latest |
| Runtime | Node.js | 20 LTS |
| Version Control | Git | 2.x |

---

## 8. Success Criteria

### 8.1 MVP Launch Criteria

- [x] User can deploy container with single command
- [x] User can access welcome page at `/`
- [x] User can authenticate at `/sn_admin/`
- [x] User can chat with AI to generate website (requires API key configuration)
- [x] Generated website visible at `/`
- [x] Changes persist across container restarts

### 8.2 Key Metrics (Post-Launch)

| Metric | Target |
|--------|--------|
| Time to first website | < 30 minutes |
| Deployment success rate | > 95% |
| User can modify site without help | > 80% |

---

## 9. Future Phase Backlog

Features explicitly deferred from MVP. This is the canonical list of future enhancements.

### 9.1 Git & Version Control
- [ ] Branch-per-session workflow (merge to master = publish)
- [ ] Rollback to previous versions via chat
- [ ] Push to external Git (GitHub, GitLab)
- [ ] Visual diff comparison in UI

### 9.2 User Interface Enhancements
- [ ] File browser in admin panel
- [ ] Visual element selection (service-injector integration)
- [ ] Side-by-side preview panel
- [ ] Slash commands (`/publish`, `/preview`, `/branch`)
- [ ] Drag-and-drop file upload UI

### 9.3 Framework Support
- [ ] Vue.js project scaffolding and build
- [ ] React project scaffolding and build
- [ ] Next.js/Nuxt.js SSR support
- [ ] Custom build pipeline configuration UI

### 9.4 Hosting & Deployment
- [ ] Custom domain configuration
- [ ] Built-in SSL/HTTPS (Let's Encrypt integration)
- [ ] Multi-site from single container
- [ ] CDN integration
- [ ] Automatic backup to cloud storage

### 9.5 Operations & Monitoring
- [ ] Logging and monitoring dashboard
- [ ] Usage analytics
- [ ] Error tracking integration

### 9.6 Authentication Enhancements
- [ ] Session-based authentication with custom login form (nicer UX)
- [ ] Logout functionality
- [ ] Password reset mechanism
- [ ] "Remember me" functionality
- [ ] Admin password change via admin panel UI

### 9.7 Collaboration
- [ ] Multiple admin users
- [ ] Role-based permissions
- [ ] Edit history / audit log
- [ ] Real-time collaboration

---

## 10. Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| OpenCode integration complexity | Medium | High | Start with iframe embed, minimal coupling |
| AI generates broken code | Medium | Medium | Build process validates output, atomic deploys |
| htpasswd security concerns | Low | Medium | Use bcrypt, document HTTPS requirement |
| Container size too large | Medium | Low | Multi-stage Docker build, Alpine base |
| User confusion with chat-only interface | Medium | Medium | Good welcome template, clear instructions |

---

## 11. Open Questions

1. **OpenCode Web UI**: How to embed? Iframe vs reverse proxy?
2. **Build Pipeline**: Watch for changes vs explicit trigger?
3. **Asset Handling**: Max file size for uploads? Image optimization?
4. **OpenCode Configuration**: What pre-configured agents/skills needed?

---

## 12. Glossary

| Term | Definition |
|------|------------|
| SkyNetCMS | The product being built - AI-powered conversational CMS |
| OpenCode | The embedded AI assistant platform |
| OpenResty | Nginx with Lua scripting support |
| htpasswd | Apache-style password file authentication |
| MCP | Model Context Protocol - OpenCode's tool interface |

---

## 13. Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-09 | AI Assistant | Initial version based on requirements gathering |

---

*This is a living document. Update as requirements evolve.*
