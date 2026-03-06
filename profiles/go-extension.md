---
name: go-extension
version: 1.0
description: Docker Desktop extensions with Go backend and React frontend
requires:
  - go-cli
winget:
  - id: Docker.DockerDesktop
    check: docker
vscode-extensions:
  - ms-azuretools.vscode-docker
claude-skills:
  - go-development
  - react-frontend-development
  - docker-containerization
---

# Go Extension Profile

Use this profile for Docker Desktop extensions that combine a Go backend service with a React/TypeScript frontend. The Go backend runs as a container inside Docker Desktop and communicates with the frontend via the extension API.

## When to Use This

- Docker Desktop extensions with a Go backend (HTTP service, CLI helper, or socket listener)
- Extensions that need server-side logic beyond what the Docker CLI provides
- Extensions that interact with Docker Engine API from a Go service

If your extension has no Go backend (frontend only), use the **node-extension** profile instead.

## Prerequisites

This profile requires the **go-cli** profile. All Go tooling (golangci-lint, govulncheck, etc.) comes from that profile. This profile adds Docker-specific tooling on top.

## Project Structure

A typical Go + React Docker Desktop extension:

```text
my-extension/
├── backend/             # Go backend service
│   ├── cmd/
│   │   └── main.go
│   ├── internal/
│   ├── go.mod
│   └── go.sum
├── ui/                  # React frontend
│   ├── src/
│   ├── package.json
│   └── tsconfig.json
├── Dockerfile           # Multi-stage: Go build + frontend build + final image
├── metadata.json        # Extension metadata
├── docker.svg           # Extension icon
├── Makefile
├── VERSION
└── CHANGELOG.md
```

## Dockerfile

The Dockerfile uses a multi-stage build:

1. **Go build stage** -- compiles the backend binary for the target platform
2. **Frontend build stage** -- builds the React app with pnpm
3. **Final stage** -- copies both artifacts into a minimal image

For multi-arch builds, use `BUILDPLATFORM` and `TARGETPLATFORM` args:

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.23 AS builder
ARG TARGETOS TARGETARCH
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /backend ./cmd/

FROM --platform=$BUILDPLATFORM node:22-alpine AS frontend
WORKDIR /ui
COPY ui/package.json ui/pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY ui/ .
RUN pnpm run build

FROM alpine:3.21
COPY --from=builder /backend /backend
COPY --from=frontend /ui/dist /ui
COPY docker.svg metadata.json ./
```

## Development Workflow

Use both go-cli and node-extension patterns together:

```bash
# Backend
cd backend && go build ./...
cd backend && go test ./...
cd backend && go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.10.1 run ./...

# Frontend
cd ui && pnpm install
cd ui && npx tsc --noEmit
cd ui && npx eslint src/

# Full extension
make build-extension    # Docker build
make install-extension  # Install into Docker Desktop
make validate           # Extension metadata validation
```

## Multi-Arch Builds

Go extensions require explicit cross-compilation in the Dockerfile. The `GOOS` and `GOARCH` build args handle this automatically when using `docker buildx`:

```bash
docker buildx create --use  # one-time setup
docker buildx build --push \
  --platform=linux/amd64,linux/arm64 \
  --tag=IMAGE:VERSION .
```

## Testing

- **Backend**: Standard Go testing with `go test ./...`
- **Frontend**: Vitest with jsdom (see node-extension profile for `@docker/extension-api-client` mock setup)
- **Integration**: `docker extension install` and manual verification in Docker Desktop

## Related Profiles

- **go-cli** -- base Go toolchain (required dependency)
- **node-extension** -- frontend-only Docker Desktop extensions
