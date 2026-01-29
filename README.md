# SkyNetCMS

AI-Powered Conversational CMS - Build websites through chat.

[![Build and Publish](https://github.com/SkyNetCMS/SkyNetCMS/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/SkyNetCMS/SkyNetCMS/actions/workflows/docker-publish.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- **Conversational website building** - Create and modify websites through natural language
- **Single Docker container** - Everything you need in one image
- **Choose your LLM** - Works with Claude, GPT-4, and other providers
- **No vendor lock-in** - Standard HTML/CSS/JS stored in a Git repository
- **Self-hosted** - Your data stays on your infrastructure

## Quick Start

Pull the image and run:

```bash
docker run -d \
  -p 8080:80 \
  -e ADMIN_USER=admin \
  -e ADMIN_PASS=changeme \
  -v skynetcms-data:/data \
  --name skynetcms \
  ghcr.io/skynetcms/skynetcms:latest
```

Then visit:
- **Admin panel**: http://localhost:8080/sn_admin/
- **Your website**: http://localhost:8080/

### First-Time Setup (Alternative)

Run without credentials to use the web-based registration:

```bash
docker run -d \
  -p 8080:80 \
  -v skynetcms-data:/data \
  --name skynetcms \
  ghcr.io/skynetcms/skynetcms:latest
```

Visit http://localhost:8080/sn_admin/ to create your admin account.

## Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ADMIN_USER` | No* | - | Admin username |
| `ADMIN_PASS` | No* | - | Admin password |
| `SITE_TITLE` | No | SkyNetCMS | Site title |

*If both `ADMIN_USER` and `ADMIN_PASS` are provided, admin is pre-configured. If neither is provided, a registration form will be shown at first access.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Docker Container                       │
│                                                          │
│   ┌──────────────────────────────────────────────────┐  │
│   │           OpenResty (Nginx + Lua)                │  │
│   │                                                  │  │
│   │    /              /sn_admin/       /sn_admin/oc/ │  │
│   │    │              │                │             │  │
│   │    ▼              ▼                ▼             │  │
│   │  Static       Dashboard        OpenCode         │  │
│   │  Website      (htpasswd)       (AI Chat)        │  │
│   └──────────────────────────────────────────────────┘  │
│                           │                              │
│                           ▼                              │
│                    ┌─────────────┐                       │
│                    │  Git Repo   │                       │
│                    │  /data/     │                       │
│                    └─────────────┘                       │
└─────────────────────────────────────────────────────────┘
```

**How it works:**
1. You chat with AI in the admin panel (`/sn_admin/oc/`)
2. AI generates/modifies website code
3. Changes are committed to the Git repository
4. Build process updates the live site
5. Visitors see updates at `/`

## Development

### Build from Source

```bash
git clone https://github.com/SkyNetCMS/SkyNetCMS.git
cd SkyNetCMS
./build.sh
```

### Run Local Build

```bash
docker run -d \
  -p 8080:80 \
  -e ADMIN_USER=admin \
  -e ADMIN_PASS=test \
  -v skynetcms-data:/data \
  --name skynetcms \
  skynetcms
```

### View Logs

```bash
docker logs -f skynetcms
```

### Stop and Remove

```bash
docker stop skynetcms && docker rm skynetcms
```

## Documentation

- [Product Requirements (PRD)](PRD_v1.md)
- [Implementation Plan](PLAN_v1.md)
- [Style Guide](STYLE_GUIDE.md)

## License

[MIT License](LICENSE) - Use it however you want.
