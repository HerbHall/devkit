---
name: setup-github-actions
description: Creates and configures GitHub Actions CI/CD workflows for Go, C#/.NET, Rust, and Node.js projects. Use when setting up automated builds, tests, linting, releases, or deployment pipelines using GitHub Actions.
---

<objective>
Creates production-ready GitHub Actions workflow files (.github/workflows/*.yml) for multi-language projects. Covers build, test, lint, release, and deployment workflows with security best practices and caching optimization.
</objective>

<quick_start>
Create a workflow file at `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and test
        run: |
          # Language-specific build/test commands here
```

Key principle: Start minimal, add complexity only when needed.
</quick_start>

<workflow_patterns>

<pattern name="go_ci">
```yaml
name: Go CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    name: Build (${{ matrix.os }}/${{ matrix.goarch }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            goarch: amd64
          - os: ubuntu-latest
            goarch: arm64
          - os: windows-latest
            goarch: amd64
          - os: macos-latest
            goarch: amd64
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - name: Build
        shell: bash
        env:
          CGO_ENABLED: '0'
          GOARCH: ${{ matrix.goarch }}
        run: go build -v ./...

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - name: Test
        run: >-
          go test -race -timeout=10m
          -coverprofile=coverage.out
          -covermode=atomic ./...

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - uses: golangci/golangci-lint-action@v6
        with:
          version: latest
          install-mode: binary

  vulncheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - name: Install govulncheck
        run: go install golang.org/x/vuln/cmd/govulncheck@latest

      - name: Run govulncheck
        run: govulncheck ./...
```

**Go CI Notes:**
- **`go vet` is redundant** if using golangci-lint with `govet` enabled (check `.golangci.yml`)
- **`CGO_ENABLED=0`** is required for cross-compilation even with pure-Go projects
- **`shell: bash`** ensures `date -u` and other Unix commands work on Windows runners
- **`-timeout=10m`** prevents tests from hanging indefinitely in CI
- **`install-mode: binary`** is faster than `goinstall` for golangci-lint
- **`govulncheck`** scans actual call graphs, not just dependency lists
</pattern>

<pattern name="dotnet_ci">
```yaml
name: .NET CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'

      - name: Restore
        run: dotnet restore

      - name: Build
        run: dotnet build --no-restore --configuration Release

      - name: Test
        run: dotnet test --no-build --configuration Release --verbosity normal
```
</pattern>

<pattern name="rust_ci">
```yaml
name: Rust CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

env:
  CARGO_TERM_COLOR: always

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy, rustfmt

      - uses: Swatinem/rust-cache@v2

      - name: Format check
        run: cargo fmt --all -- --check

      - name: Clippy
        run: cargo clippy --all-targets --all-features -- -D warnings

      - name: Test
        run: cargo test --all-features
```
</pattern>

<pattern name="node_ci">
```yaml
name: Node.js CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: npm

      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build
```
</pattern>

</workflow_patterns>

<release_patterns>

<pattern name="go_release">
Use GoReleaser for Go binary releases:

```yaml
name: Release
on:
  push:
    tags: ['v*']

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - uses: goreleaser/goreleaser-action@v6
        with:
          version: '~> v2'
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
</pattern>

<pattern name="tag_based_release">
Generic tag-based release workflow:

```yaml
name: Release
on:
  push:
    tags: ['v*']

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build release artifacts
        run: |
          # Build commands here

      - uses: softprops/action-gh-release@v2
        with:
          files: |
            dist/*
          generate_release_notes: true
```
</pattern>

<pattern name="goreleaser_config">
GoReleaser v2 config file (`.goreleaser.yaml`) for multi-binary projects:

```yaml
version: 2

builds:
  - id: server
    main: ./cmd/server/
    binary: server
    env:
      - CGO_ENABLED=0
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]
    ldflags:
      - -s -w
      - -X main.version={{.Version}}
      - -X main.commit={{.ShortCommit}}
      - -X main.date={{.Date}}

  - id: agent
    main: ./cmd/agent/
    binary: agent
    env:
      - CGO_ENABLED=0
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]
    ldflags:
      - -s -w
      - -X main.version={{.Version}}
      - -X main.commit={{.ShortCommit}}
      - -X main.date={{.Date}}

archives:
  - id: server
    ids:           # NOT "builds:" (deprecated)
      - server
    name_template: >-
      server_{{ .Version }}_{{ .Os }}_{{ .Arch }}
    format_overrides:
      - goos: windows
        formats:   # NOT "format:" (deprecated)
          - zip

checksum:
  name_template: 'checksums.txt'

changelog:
  sort: asc
  use: github

release:
  prerelease: auto
```

**GoReleaser v2 Gotchas:**
- Use `ids:` not `builds:` in archives (deprecated)
- Use `formats:` (list) not `format:` (string) in format_overrides (deprecated)
- Always validate with `goreleaser check` before committing
- `CGO_ENABLED=0` is critical for cross-compilation
- `version: 2` at top of file is required for GoReleaser v2
</pattern>

<pattern name="go_release_with_docker">
GoReleaser v2 release workflow with Docker images, SBOMs, and frontend embedding:

```yaml
name: Release
on:
  push:
    tags: ['v*']

permissions:
  contents: write
  packages: write    # Required for GHCR push
  id-token: write    # Required for OIDC/signing

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for GoReleaser changelog

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      # Frontend build (if applicable)
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - uses: pnpm/action-setup@v4
        with:
          version: 10
      - name: Build frontend
        working-directory: web
        run: |
          pnpm install --frozen-lockfile
          pnpm run build
      - name: Embed frontend
        run: |
          rm -rf internal/dashboard/dist
          cp -r web/dist internal/dashboard/dist
      - name: Clean build artifacts
        run: git checkout -- web/

      # Docker prerequisites
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # SBOM prerequisite
      - uses: anchore/sbom-action/download-syft@v0

      # Release
      - uses: goreleaser/goreleaser-action@v6
        with:
          version: '~> v2'
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**GoReleaser Docker config** (`.goreleaser.yaml`):
```yaml
dockers:
  - id: app-amd64
    ids: [app]
    goos: linux
    goarch: amd64
    use: buildx
    image_templates:
      - "ghcr.io/org/app:{{ .Tag }}-amd64"
      - "ghcr.io/org/app:latest-amd64"
    build_flag_templates:
      - "--platform=linux/amd64"
      - "--label=org.opencontainers.image.version={{ .Version }}"
      - "--label=org.opencontainers.image.source={{ .GitURL }}"
    dockerfile: Dockerfile.goreleaser

  - id: app-arm64
    ids: [app]
    goos: linux
    goarch: arm64
    use: buildx
    image_templates:
      - "ghcr.io/org/app:{{ .Tag }}-arm64"
      - "ghcr.io/org/app:latest-arm64"
    build_flag_templates:
      - "--platform=linux/arm64"
    dockerfile: Dockerfile.goreleaser

docker_manifests:
  - name_template: "ghcr.io/org/app:{{ .Tag }}"
    image_templates:
      - "ghcr.io/org/app:{{ .Tag }}-amd64"
      - "ghcr.io/org/app:{{ .Tag }}-arm64"
  - name_template: "ghcr.io/org/app:latest"
    image_templates:
      - "ghcr.io/org/app:latest-amd64"
      - "ghcr.io/org/app:latest-arm64"

sboms:
  - artifacts: archive
    documents:
      - "{{ .ArtifactName }}.sbom.json"
```

**Notes:**
- `docker/setup-buildx-action` is required when `use: buildx` in GoReleaser docker config
- `docker/login-action` is required for pushing to any container registry
- `anchore/sbom-action/download-syft` is required when `sboms:` section exists
- `git checkout -- web/` prevents dirty git state from frontend build artifacts
- `*.tsbuildinfo` and `coverage/` must be in `.gitignore` to avoid dirty state
</pattern>

</release_patterns>

<security_practices>
- **ALWAYS set explicit `permissions`** at workflow or job level. Never rely on defaults.
- **ALWAYS pin action versions** to full SHA or major version (`actions/checkout@v4`, not `@main`).
- **NEVER expose secrets in logs.** Use `${{ secrets.NAME }}` and mask outputs.
- **NEVER use `pull_request_target` with checkout of PR code** -- this allows arbitrary code execution with write permissions.
- **Use `contents: read`** as the default permission. Only escalate when needed (e.g., `contents: write` for releases).
- **Use OIDC** for cloud provider authentication instead of long-lived credentials.
- **Use Dependabot** or Renovate to keep action versions current.

```yaml
# Minimal permissions example
permissions:
  contents: read
  pull-requests: read
```
</security_practices>

<caching_optimization>
Use language-specific caching to speed up workflows:

| Language | Setup Action | Cache Method |
|----------|-------------|--------------|
| Go | `actions/setup-go@v5` | `cache: true` (built-in) |
| .NET | `actions/setup-dotnet@v4` | `actions/cache@v4` with NuGet paths |
| Rust | `dtolnay/rust-toolchain@stable` | `Swatinem/rust-cache@v2` |
| Node.js | `actions/setup-node@v4` | `cache: npm` (built-in) |

For custom caching:
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/custom-tool
    key: ${{ runner.os }}-custom-${{ hashFiles('**/lockfile') }}
    restore-keys: |
      ${{ runner.os }}-custom-
```
</caching_optimization>

<common_patterns>

<pattern name="matrix_builds">
Test across multiple OS/versions:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    go-version: ['1.21', '1.22']
  fail-fast: false

runs-on: ${{ matrix.os }}
steps:
  - uses: actions/setup-go@v5
    with:
      go-version: ${{ matrix.go-version }}
```
</pattern>

<pattern name="conditional_jobs">
Run jobs only when specific files change:

```yaml
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      go: ${{ steps.filter.outputs.go }}
    steps:
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            go:
              - '**/*.go'
              - go.mod
              - go.sum

  test:
    needs: changes
    if: needs.changes.outputs.go == 'true'
    runs-on: ubuntu-latest
    steps:
      # ...
```
</pattern>

<pattern name="reusable_workflows">
Define reusable workflows in `.github/workflows/`:

```yaml
# .github/workflows/reusable-go-ci.yml
name: Reusable Go CI
on:
  workflow_call:
    inputs:
      go-version:
        type: string
        default: '1.22'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: ${{ inputs.go-version }}
      - run: go test ./...
```

Call it from another workflow:
```yaml
jobs:
  ci:
    uses: ./.github/workflows/reusable-go-ci.yml
    with:
      go-version: '1.22'
```
</pattern>

</common_patterns>

<version_injection>
Inject version metadata at build time using ldflags:

```yaml
      - name: Build
        shell: bash
        env:
          CGO_ENABLED: '0'
          GOARCH: ${{ matrix.goarch }}
        run: |
          VERSION_PKG=github.com/org/repo/internal/version
          go build -v -ldflags "-s -w \
            -X ${VERSION_PKG}.Version=${{ github.ref_name }} \
            -X ${VERSION_PKG}.GitCommit=${GITHUB_SHA::7} \
            -X ${VERSION_PKG}.BuildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            ./cmd/server/...
```

**Notes:**
- `${GITHUB_SHA::7}` gives short commit hash (bash substring), matching `git rev-parse --short HEAD`
- `shell: bash` is required for `date -u` and `${VAR::N}` to work on Windows runners
- Use a `VERSION_PKG` variable to keep ldflags lines under 80 characters
- GoReleaser provides `{{.Version}}`, `{{.ShortCommit}}`, `{{.Date}}` template vars for the same purpose
</version_injection>

<critical_lessons>

Lessons learned from production CI/CD implementations:

<lesson name="windows_line_endings">
**Windows Line Endings in YAML**
On Windows development machines, file creation tools produce `\r\n` (CRLF) line endings.
GitHub Actions YAML files must use `\n` (LF). Always run `sed -i 's/\r$//'` on generated
YAML files, or configure `.gitattributes` to enforce LF for `*.yml` and `*.yaml`.
</lesson>

<lesson name="cgo_cross_compilation">
**CGO_ENABLED=0 for Cross-Compilation**
Even pure-Go projects (no C dependencies) should set `CGO_ENABLED=0` in CI build steps.
Without it, Go may attempt to use the system C compiler for certain stdlib packages,
which fails during cross-compilation (e.g., building linux/arm64 on ubuntu-latest/amd64).
</lesson>

<lesson name="golangci_lint_install_mode">
**golangci-lint Install Mode**
Use `install-mode: binary` (not `goinstall`) with `golangci/golangci-lint-action@v6`.
The `goinstall` mode compiles from source, which is slower and may fail with Go version
mismatches. The `binary` mode downloads a pre-built binary.
</lesson>

<lesson name="goreleaser_v2_deprecations">
**GoReleaser v2 Deprecated Fields**
- `archives.builds` is deprecated; use `archives.ids` instead
- `archives.format_overrides.format` is deprecated; use `formats` (a list) instead
- Always validate config with `goreleaser check` before committing
</lesson>

<lesson name="test_timeout">
**Always Set Test Timeout**
Add `-timeout=10m` (or appropriate value) to `go test` commands in CI.
Without it, a hanging test blocks the CI job until GitHub's 6-hour default timeout.
</lesson>

<lesson name="license_check_approach">
**License Checking: Use Allowed-List, Not Block-List**
Use `go-licenses check ./... --allowed_licenses=Apache-2.0,MIT,BSD-2-Clause,BSD-3-Clause,ISC,MPL-2.0`
instead of grepping for blocked license names. The allowed-list approach catches unexpected
licenses that weren't anticipated, while the block-list approach only catches known bad ones.
</lesson>

<lesson name="govet_redundancy">
**go vet is Redundant with golangci-lint**
If your `.golangci.yml` enables `govet` (it's enabled by default), don't add a separate
`go vet` CI job. golangci-lint already runs it. Check your config before adding duplicate steps.
</lesson>

<lesson name="goreleaser_release_prerequisites">
**GoReleaser Docker/SBOM Prerequisites**
The `goreleaser/goreleaser-action` does NOT install Docker buildx, registry auth, or syft.
You must add these steps explicitly before GoReleaser:
- `docker/setup-buildx-action@v3` -- required if `use: buildx` in docker config
- `docker/login-action@v3` -- required for pushing to GHCR/Docker Hub/ECR
- `anchore/sbom-action/download-syft@v0` -- required if `sboms:` section exists
Also add `packages: write` permission for container registry push.
</lesson>

<lesson name="goreleaser_dirty_git_state">
**GoReleaser Requires Clean Git State**
GoReleaser refuses to build if `git status` shows modifications. Common causes:
- Frontend builds regenerating `*.tsbuildinfo` files (tracked in git)
- Test coverage directories (`coverage/`) created during build
Fix: Add `*.tsbuildinfo`, `coverage/` to `.gitignore`. Add `git checkout -- web/` (or
equivalent) cleanup step after any build step that modifies tracked files.
</lesson>

</critical_lessons>

<anti_patterns>
- **Monolithic workflows**: Split build, test, lint into separate jobs for parallelism and clearer failure signals
- **Missing `fail-fast: false`**: Matrix builds default to cancelling all jobs if one fails. Set `fail-fast: false` for independent tests.
- **Hardcoded versions**: Use `go-version-file: go.mod` or `.nvmrc` instead of hardcoding language versions
- **Missing concurrency control**: Add `concurrency` to prevent redundant runs on rapid pushes:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```
</anti_patterns>

<success_criteria>
A well-configured GitHub Actions setup:
- Runs on every push to main and every PR
- Builds, tests, and lints the project
- Uses caching for fast execution
- Has explicit minimal permissions
- Uses pinned action versions
- Provides clear failure messages
- Handles releases via tags (if applicable)
</success_criteria>
