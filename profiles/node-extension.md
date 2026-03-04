---
name: node-extension
version: 1.0
description: Docker Desktop extensions with Node.js/React frontend
requires: []
winget:
  - id: Docker.DockerDesktop
    check: docker
  - id: OpenJS.NodeJS.LTS
    check: node
manual:
  - id: pnpm
    check: pnpm
    install: npm install -g pnpm
vscode-extensions:
  - dbaeumer.vscode-eslint
  - esbenp.prettier-vscode
  - ms-azuretools.vscode-docker
claude-skills:
  - react-frontend-development
  - docker-containerization
---

# Node Extension Profile

Use this profile for Docker Desktop extensions with a Node.js/React frontend and no Go backend. These extensions run entirely in the Docker Desktop UI layer.

## When to Use This

- Docker Desktop extensions with React/TypeScript UI only
- Extensions that call Docker CLI or Docker Engine API from the frontend
- Extensions that use `@docker/extension-api-client` for Docker Desktop integration

If your extension also has a Go backend service, use the **go-extension** profile instead.

## Project Structure

A typical Node.js Docker Desktop extension:

```text
my-extension/
├── ui/                  # React frontend
│   ├── src/
│   ├── package.json
│   └── tsconfig.json
├── Dockerfile           # Extension image
├── metadata.json        # Extension metadata
├── docker.svg           # Extension icon (bundled in image)
├── Makefile
├── VERSION
└── CHANGELOG.md
```

## Makefile

Copy `project-templates/Makefile.node-extension` and replace the placeholders:

- `{{PROJECT_NAME}}` -- your extension name
- `{{DOCKER_IMAGE}}` -- your Docker Hub image (e.g., `username/my-extension`)

Key targets:

```text
build-extension:    Build Docker image locally
install-extension:  Install extension into Docker Desktop
update-extension:   Update running extension with local build
validate:           Run docker extension validate
fe-install:         Install frontend dependencies
fe-lint:            ESLint check
fe-typecheck:       TypeScript compilation check
fe-test:            Run Vitest unit tests
ci:                 Full CI pipeline (typecheck + lint + test + build)
```

Run `make hooks` after cloning to install the pre-push hook.

## Multi-Arch Builds

Docker Desktop runs on macOS (arm64 + amd64), Windows (amd64), and Linux (amd64/arm64). Extensions must provide multi-arch images:

```bash
docker buildx create --use  # one-time setup
make push-extension         # builds and pushes linux/amd64 + linux/arm64
```

Pure frontend extensions (no compiled backend binary) are inherently multi-arch since they only contain static files.

## Dockerfile Labels

Extension Dockerfiles require specific label formats for marketplace display. See the Makefile template for the standard set. Key labels:

- `com.docker.desktop.extension.api.version` -- API version
- `com.docker.desktop.extension.icon` -- local icon file reference
- `com.docker.extension.screenshots` -- JSON array (min 3, 2400x1600px recommended)
- `com.docker.extension.changelog` -- HTML-formatted changelog
- `com.docker.extension.additional-urls` -- JSON array with docs/support/bug links

**Hadolint gotchas**: Docker Desktop extension Dockerfiles use vendor-specific labels and COPY patterns that hadolint flags incorrectly. Create a `.hadolint.yaml` with DL3048 and DL3045 ignored (see known-gotchas KG#78).

## MUI v5 Constraint

Docker Desktop extensions use `@docker/docker-mui-theme` for consistent theming. This package pins MUI to v5. When looking up MUI documentation or examples, always specify MUI v5 -- current docs default to v6 syntax which is incompatible (see known-gotchas KG#85).

Key v5 patterns:

- TextField adornments: `InputProps={{ startAdornment }}` (not `slotProps.input`)
- Select: `SelectProps={{ ... }}` (not `slotProps.select`)

## Testing

Vitest with jsdom environment for unit tests. The `@docker/extension-api-client` package requires a resolve alias in `vitest.config.ts` due to CJS/ESM mismatch (see known-gotchas KG#81).

```bash
make fe-test       # run unit tests
make fe-typecheck  # TypeScript compilation
make fe-lint       # ESLint
```

## Related Profiles

- **go-extension** -- if your extension has a Go backend service
- **react-frontend** -- for standalone React apps (not Docker extensions)
