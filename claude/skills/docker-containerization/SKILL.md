---
name: docker-containerization
description: Docker and container best practices for production workloads. Covers multi-stage Dockerfiles, base image selection, security hardening, BuildKit caching, docker-compose patterns, health checks, multi-arch builds, size optimization, and CI/CD integration. Use when writing Dockerfiles, setting up docker-compose, optimizing container images, or building CI/CD pipelines with containers.
---

<essential_principles>

**Core Philosophy**

- Containers are immutable artifacts. Build once, run anywhere.
- Minimal images reduce attack surface and startup time.
- Every layer matters. Order instructions by change frequency (least → most).
- Security is non-negotiable: non-root users, read-only filesystems, no secrets in images.
- Dev/prod parity: use the same image, different config via environment variables.

**Decision Matrix: Base Image Selection**

| Use Case | Base Image | Size | Notes |
|----------|-----------|------|-------|
| Go / Rust (static binary) | `scratch` or `gcr.io/distroless/static-debian12` | ~2-5 MB | No shell, no package manager -- most secure |
| Go / Rust (needs CA certs, tzdata) | `gcr.io/distroless/base-debian12` | ~20 MB | Includes glibc, CA certs, tzdata |
| Node.js / Python | `node:22-slim` / `python:3.13-slim` | ~150-200 MB | Slim variants strip dev tools |
| .NET | `mcr.microsoft.com/dotnet/aspnet:9.0` | ~220 MB | Runtime-only image |
| Need a shell for debugging | `alpine:3.21` | ~7 MB | Use only when shell access required |
| General purpose with tooling | `debian:bookworm-slim` | ~80 MB | When you need apt-get |

**Never use `latest` tag in production.** Always pin to specific version + digest for reproducibility.

</essential_principles>

<multi_stage_builds>

**Every production Dockerfile should use multi-stage builds.** Separate build dependencies from runtime.

### Go Application

```dockerfile
# syntax=docker/dockerfile:1

# ── Build stage ──────────────────────────────────────────
FROM golang:1.24-bookworm AS builder

WORKDIR /src

# Cache dependencies separately from source code
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Copy source and build
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w -X main.version=${VERSION}" \
    -o /bin/app ./cmd/app/

# ── Runtime stage ────────────────────────────────────────
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /bin/app /app

EXPOSE 8080
ENTRYPOINT ["/app"]
```

### Node.js Application

```dockerfile
# syntax=docker/dockerfile:1

# ── Dependencies stage ───────────────────────────────────
FROM node:22-slim AS deps

WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --production=false

# ── Build stage ──────────────────────────────────────────
FROM deps AS builder

COPY . .
RUN npm run build

# ── Production dependencies ──────────────────────────────
FROM node:22-slim AS prod-deps

WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

# ── Runtime stage ────────────────────────────────────────
FROM node:22-slim

RUN groupadd -r appuser && useradd -r -g appuser -d /app appuser
WORKDIR /app

COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package.json ./

USER appuser
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### React SPA (Vite)

```dockerfile
# syntax=docker/dockerfile:1

# ── Build stage ──────────────────────────────────────────
FROM node:22-slim AS builder

WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY . .
RUN npm run build

# ── Runtime stage (static files served by nginx) ────────
FROM nginx:1.27-alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
```

**Key Principles:**

- Always start with `# syntax=docker/dockerfile:1` to enable BuildKit features
- Copy dependency manifests first, then source (maximizes cache hits)
- Use `--mount=type=cache` for package manager caches
- Strip debug symbols in Go builds: `-ldflags="-s -w"`
- Set `CGO_ENABLED=0` for Go when targeting scratch/distroless

</multi_stage_builds>

<security>

**Non-Negotiable Security Practices:**

1. **Run as non-root:**

```dockerfile
# For distroless: use the nonroot tag
FROM gcr.io/distroless/static-debian12:nonroot

# For other images: create a dedicated user
RUN groupadd -r appuser && useradd -r -g appuser -s /usr/sbin/nologin appuser
USER appuser
```

1. **Never embed secrets in images:**

```dockerfile
# WRONG -- secret baked into layer history
COPY .env /app/.env
ENV DATABASE_PASSWORD=hunter2

# RIGHT -- use build secrets (never persisted in image)
RUN --mount=type=secret,id=db_password \
    cat /run/secrets/db_password > /dev/null

# RIGHT -- pass at runtime via environment or mounted secrets
# docker run -e DATABASE_PASSWORD=... app
# docker run -v /secrets/db_password:/run/secrets/db_password:ro app
```

1. **Read-only root filesystem:**

```yaml
# docker-compose.yml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

1. **Drop all capabilities, add only what's needed:**

```yaml
services:
  app:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # only if binding to ports < 1024
```

1. **Pin image digests for reproducibility:**

```dockerfile
FROM golang:1.24-bookworm@sha256:abc123...
```

1. **Scan images for vulnerabilities:**

```bash
# Trivy (recommended)
trivy image myapp:latest

# Docker Scout
docker scout cves myapp:latest

# Snyk
snyk container test myapp:latest
```

1. **Use `.dockerignore`:**

```text
.git
.env
.env.*
node_modules
*.md
LICENSE
.github
.vscode
__pycache__
*.pyc
```

**Security Checklist:**

- [ ] Non-root user in runtime image
- [ ] No secrets in Dockerfile or image layers
- [ ] `.dockerignore` excludes sensitive files
- [ ] Base image pinned to specific version (+ digest for production)
- [ ] Image scanned with Trivy or equivalent
- [ ] Read-only root filesystem where possible
- [ ] Capabilities dropped

</security>

<buildkit_caching>

**BuildKit cache mounts eliminate redundant downloads and compilations.**

### Package Manager Caches

```dockerfile
# Go modules
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /bin/app ./cmd/app/

# npm
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# pip
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

# apt
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y --no-install-recommends curl
```

### Layer Ordering (Critical for Cache Hits)

```dockerfile
# GOOD: dependency manifests change less often than source code
COPY go.mod go.sum ./          # Layer 1: rarely changes
RUN go mod download             # Layer 2: cached when go.mod unchanged
COPY . .                        # Layer 3: changes frequently
RUN go build ./cmd/app/         # Layer 4: rebuilds when source changes

# BAD: any source change invalidates dependency cache
COPY . .                        # Every change busts all subsequent layers
RUN go mod download && go build ./cmd/app/
```

### CI Cache Export/Import

```bash
# Build with cache exported to registry
docker buildx build \
  --cache-from type=registry,ref=ghcr.io/org/app:buildcache \
  --cache-to type=registry,ref=ghcr.io/org/app:buildcache,mode=max \
  -t ghcr.io/org/app:latest .

# Build with local cache directory
docker buildx build \
  --cache-from type=local,src=/tmp/.buildx-cache \
  --cache-to type=local,dest=/tmp/.buildx-cache-new,mode=max \
  -t app:latest .
```

</buildkit_caching>

<docker_compose>

**Use Compose for local development and single-host deployments.**

### Production-Ready Compose File

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: ghcr.io/org/app:${VERSION:-latest}
    ports:
      - "${APP_PORT:-8080}:8080"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/appdb?sslmode=disable
      - LOG_LEVEL=${LOG_LEVEL:-info}
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    healthcheck:
      test: ["CMD", "/app", "healthcheck"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s

  db:
    image: postgres:17-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: appdb
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  pgdata:
```

### Dev Override Pattern

```yaml
# docker-compose.override.yml (auto-loaded in dev)
services:
  app:
    build:
      target: builder  # Use build stage with dev tools
    volumes:
      - .:/app         # Live reload via bind mount
      - /app/node_modules  # Preserve container's node_modules
    environment:
      - LOG_LEVEL=debug
      - NODE_ENV=development
    ports:
      - "9229:9229"    # Debugger port
    command: ["npm", "run", "dev"]

  db:
    ports:
      - "5432:5432"    # Expose DB port in dev
```

### Production Override

```yaml
# docker-compose.prod.yml
# Usage: docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
services:
  app:
    image: ghcr.io/org/app:${VERSION}  # Use pre-built image
    build: !reset null                   # Don't build in prod
    restart: always
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

**Conventions:**

- Always define `healthcheck` for services with `depends_on`
- Use `depends_on.condition: service_healthy` instead of bare `depends_on`
- Use named volumes for persistent data, never bind mounts in production
- Set `restart: unless-stopped` for production services
- Use environment variables with defaults: `${VAR:-default}`
- Override files for environment-specific config (dev, staging, prod)

</docker_compose>

<health_checks>

**Every containerized service must have a health check.**

### Patterns by Language

```dockerfile
# Go -- use a dedicated healthcheck subcommand or endpoint
HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=10s \
  CMD ["/app", "healthcheck"]

# Node.js -- lightweight HTTP check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD ["node", "-e", "fetch('http://localhost:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]

# Python -- use curl or a script
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]

# Generic -- curl (requires curl in image)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD ["curl", "-f", "http://localhost:8080/health"]
```

### Health Endpoint Implementation (Go)

```go
// Keep health checks fast and dependency-aware
func healthHandler(w http.ResponseWriter, r *http.Request) {
    checks := map[string]string{
        "status": "ok",
    }

    // Check critical dependencies
    if err := db.PingContext(r.Context()); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        checks["status"] = "unhealthy"
        checks["database"] = err.Error()
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(checks)
}
```

**Health Check Guidelines:**

- `start_period`: time to wait before first check (allow startup)
- `interval`: time between checks (30s is a good default)
- `timeout`: max time for a single check (5s)
- `retries`: failures before marking unhealthy (3)
- Health endpoints should check critical dependencies (DB, cache) but not external services
- Return fast -- health checks should complete in < 1 second
- For distroless images without a shell, build health check into the binary

</health_checks>

<multi_arch>

**Build for multiple architectures when distributing images.**

### buildx Multi-Architecture Build

```bash
# One-time setup: create a multi-arch builder
docker buildx create --name multiarch --driver docker-container --use

# Build and push for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag ghcr.io/org/app:1.2.3 \
  --tag ghcr.io/org/app:latest \
  --push .
```

### Dockerfile Considerations for Multi-Arch

```dockerfile
# Use platform-aware base images (most official images support multi-arch)
FROM --platform=$BUILDPLATFORM golang:1.24-bookworm AS builder

# Use TARGETARCH for cross-compilation
ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -o /bin/app ./cmd/app/

# Runtime image auto-selects correct architecture
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /bin/app /app
```

**Key Variables:**

- `BUILDPLATFORM`: Platform of the build host (e.g., `linux/amd64`)
- `TARGETPLATFORM`: Platform being built for (e.g., `linux/arm64`)
- `TARGETOS` / `TARGETARCH`: OS and architecture components
- Use `--platform=$BUILDPLATFORM` on build stages to run natively (faster)
- Use `TARGETOS`/`TARGETARCH` for cross-compilation flags

</multi_arch>

<size_optimization>

**Smaller images = faster pulls, less storage, reduced attack surface.**

### Techniques (Ordered by Impact)

1. **Use multi-stage builds** (covered above) -- biggest win
2. **Choose minimal base images** (scratch/distroless for compiled languages)
3. **Combine RUN commands** to reduce layers:

```dockerfile
# GOOD: single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# BAD: three layers, intermediate layers persist
RUN apt-get update
RUN apt-get install -y curl ca-certificates
RUN rm -rf /var/lib/apt/lists/*
```

1. **Use `--no-install-recommends`** with apt-get
2. **Clean up in the same layer** (apt lists, temp files, caches)
3. **Strip binaries:**

```dockerfile
# Go: strip debug symbols
RUN go build -ldflags="-s -w" -o /bin/app ./cmd/app/

# Further compression with UPX (optional, increases startup time slightly)
RUN upx --best /bin/app
```

1. **Use `.dockerignore`** to exclude unnecessary context files

### Analyzing Image Size

```bash
# Inspect layers and sizes
docker history myapp:latest

# Dive -- interactive layer explorer
dive myapp:latest

# Compare image sizes
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | sort -k2 -h
```

</size_optimization>

<ci_cd>

**GitHub Actions Docker Workflow**

```yaml
name: Build and Push

on:
  push:
    branches: [main]
    tags: ["v*"]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Scan image for vulnerabilities
        if: github.event_name != 'pull_request'
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
          format: sarif
          output: trivy-results.sarif

      - name: Upload scan results
        if: github.event_name != 'pull_request'
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif
```

**CI/CD Conventions:**

- Use `docker/build-push-action` with `cache-from: type=gha` for GitHub Actions cache
- Use `docker/metadata-action` for consistent tagging (semver, SHA, branch)
- Scan images with Trivy in CI before deployment
- Build multi-arch on push to main/tags, single-arch on PRs (faster)
- Push to registry only on main/tags, never on PRs
- Use GitHub Container Registry (`ghcr.io`) -- free for public repos

</ci_cd>

<anti_patterns>

- **Running as root** -- always set `USER` in the final stage
- **Using `latest` tag** in production -- pin versions for reproducibility
- **Secrets in Dockerfiles** -- use build secrets or runtime env vars
- **`COPY . .` before dependency install** -- busts cache on every source change
- **Installing dev dependencies in production images** -- use multi-stage or `--omit=dev`
- **One `RUN` per command** -- combine with `&&` to reduce layers
- **Ignoring `.dockerignore`** -- large contexts slow builds and leak files
- **Bare `EXPOSE` without documentation** -- always comment what the port is for
- **`docker-compose up` in production** -- use orchestrators for multi-host; Compose is fine for single-host
- **Mounting host paths in production** -- use named volumes for data persistence
- **`apt-get upgrade` in Dockerfiles** -- pin base image version instead; upgrades make builds non-reproducible
- **Ignoring health checks** -- always define them for services with dependencies

</anti_patterns>

<success_criteria>
A well-containerized application:

- Multi-stage Dockerfile with build and runtime stages separated
- Minimal runtime image (scratch/distroless for compiled, slim for interpreted)
- Non-root user in final stage
- No secrets in image or Dockerfile
- Health check defined in Dockerfile or Compose
- `.dockerignore` excludes unnecessary files
- BuildKit cache mounts for package managers
- Image scanned for vulnerabilities in CI
- Consistent tagging strategy (semver + SHA)
- docker-compose with health-dependent service startup
</success_criteria>
