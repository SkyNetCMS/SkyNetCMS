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

```bash
docker run -d \
  -p 8080:80 \
  -e ADMIN_USER=admin \
  -e ADMIN_PASS=your-secure-password \
  -v skynet-data:/data \
  --name skynetcms \
  skynetcms
```

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
| `ADMIN_USER` | Yes | - | Admin username |
| `ADMIN_PASS` | Yes | - | Admin password |
| `SITE_TITLE` | No | SkyNetCMS | Site title |

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

# Verify installations inside container
docker exec skynet-test openresty -v
docker exec skynet-test opencode --version
docker exec skynet-test git --version

# Check repository was initialized
docker exec skynet-test ls /data/repo/src
docker exec skynet-test git -C /data/repo log --oneline

# Cleanup
docker rm -f skynet-test
```

## Status

**Milestone 1: Project Foundation** - Complete

See [PLAN_v1.md](PLAN_v1.md) for full implementation plan.
