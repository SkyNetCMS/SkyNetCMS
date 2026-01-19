# SkyNetCMS

AI-Powered Conversational CMS - Build websites through chat.

## Quick Start

### Prerequisites

- Docker installed and running

### Build

```bash
./build.sh
```

### Run

**Option 1: With pre-configured admin (via environment variables)**

```bash
docker run -d \
  -p 8080:80 \
  -e ADMIN_USER=admin \
  -e ADMIN_PASS=your-secure-password \
  -v skynet-data:/data \
  --name skynetcms \
  skynetcms
```

**Option 2: First-time registration flow (no environment variables)**

```bash
docker run -d \
  -p 8080:80 \
  -v skynet-data:/data \
  --name skynetcms \
  skynetcms
```

Then visit http://localhost:8080/sn_admin/ to create your admin account.

### Access

- **Public site**: http://localhost:8080/
- **Admin panel**: http://localhost:8080/sn_admin/
- **Admin setup** (first-time only): http://localhost:8080/sn_admin/setup/
- **Health check**: http://localhost:8080/health

### Development (with docker-compose)

```bash
cd docker
docker-compose up --build
```

### View Logs

```bash
docker logs skynetcms
```

### Stop

```bash
docker stop skynetcms
docker rm skynetcms
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ADMIN_USER` | No* | - | Admin username |
| `ADMIN_PASS` | No* | - | Admin password |
| `SITE_TITLE` | No | SkyNetCMS | Site title |

*If both `ADMIN_USER` and `ADMIN_PASS` are provided, admin is pre-configured. If neither is provided, a registration form will be shown at first access to `/sn_admin/`. Providing only one will cause an error.

## Verification (after build)

```bash
# Build the image
./build.sh

# Run container
docker run -d -p 8080:80 -e ADMIN_USER=admin -e ADMIN_PASS=test --name skynet-test skynetcms

# Check container is running
docker ps

# View startup logs
docker logs skynet-test

# Test health endpoint
curl http://localhost:8080/health
# Expected: OK

# Test public site
curl http://localhost:8080/
# Expected: Welcome to SkyNetCMS HTML

# Test auth required (should return 401)
curl -I http://localhost:8080/sn_admin/
# Expected: HTTP/1.1 401 Unauthorized

# Test auth success
curl -u admin:test http://localhost:8080/sn_admin/
# Expected: Admin panel HTML

# Verify installations inside container
docker exec skynet-test openresty -v
docker exec skynet-test opencode --version

# Check repository was initialized
docker exec skynet-test ls /data/website/src
docker exec skynet-test git -C /data/website log --oneline

# Cleanup
docker rm -f skynet-test
```

## Status

**Milestone 2.5: First-Time Registration** - Complete

See [PLAN_v1.md](PLAN_v1.md) for full implementation plan.
