---
name: go-cli
version: 1.0
description: Go CLI and daemon development (toolchain, linters, static analysis)
requires: []
winget:
  - id: GoLang.Go
    check: go
manual:
  - id: golangci-lint
    check: golangci-lint
    install: go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.1.6
    note: Pin version to avoid surprise breakage. Use go run ...@v2.1.6 for execution.
  - id: staticcheck
    check: staticcheck
    install: go install honnef.co/go/tools/cmd/staticcheck@latest
  - id: govulncheck
    check: govulncheck
    install: go install golang.org/x/vuln/cmd/govulncheck@latest
  - id: swag
    check: swag
    install: go install github.com/swaggo/swag/cmd/swag@latest
    note: Swagger spec generation -- see known-gotchas.md for drift issues
vscode-extensions:
  - golang.go
  - eamodio.gitlens
  - streetsidesoftware.code-spell-checker
claude-skills:
  - go-development
  - systematic-debugging
  - security-review
---

# Go CLI Profile

Use this profile for Go CLI tools, daemons, and background services. These are standalone binaries with no HTTP handlers or gRPC services.

## When to Use This

- Command-line tools (CLI arguments parsing, exit codes)
- System daemons (background processes, signal handling)
- Workers and job processors (batch operations, scheduling)
- Anything that compiles to a single binary without web endpoints

If your project has HTTP handlers or gRPC services, use the **go-web** profile instead.

## Windows Setup

### GOPATH

Go defaults to `%USERPROFILE%\go` (usually `C:\Users\YourName\go`) on Windows. Binaries install to `%GOPATH%\bin`.

Add `%GOPATH%\bin` to your PATH:

```powershell
[Environment]::SetEnvironmentVariable('Path', $env:Path + ';' + $env:USERPROFILE + '\go\bin', 'User')
# Restart terminal to pick up the change
```

Verify:

```bash
go env GOPATH
echo $env:Path | grep -o '[^;]*go[^;]*'
```

### Linter Configuration

Copy `project-templates/golangci.yml` to your project root as `.golangci.yml`. The template includes:

- `version: "2"` (required by golangci-lint v2; omitting this causes a silent config failure)
- A proven linter set: errcheck, gosec, gocritic, govet, staticcheck, ineffassign, unused, misspell, bodyclose, noctx, sqlclosecheck, durationcheck, exhaustive, nilerr, prealloc
- Test and cmd/ exclusion rules

```yaml
version: "2"

run:
  timeout: 5m

linters:
  enable:
    - errcheck
    - gosec
    - gocritic
    - govet
    - staticcheck
    - ineffassign
    - unused
    - misspell
    - bodyclose
    - noctx
    - sqlclosecheck
    - durationcheck
    - exhaustive
    - nilerr
    - prealloc
```

## Cross-Compilation

Go makes cross-compilation straightforward. Set `GOOS` and `GOARCH` to build for other platforms:

```bash
# Build for Linux on Windows
GOOS=linux GOARCH=amd64 go build ./...

# Build for macOS
GOOS=darwin GOARCH=arm64 go build -o dist/app-macos-arm64 ./cmd/app

# Windows: must include .exe
GOOS=windows GOARCH=amd64 go build -o dist/app.exe ./cmd/app
```

**Important gotcha**: On Windows, local `go build ./...` produces `.exe` files (e.g., `myapp.exe`). CI running on Linux will NOT produce `.exe`. If your tests or build scripts assume `.exe` exists, they will fail in CI. Always use `GOOS=linux GOARCH=amd64` for explicit Linux builds.

## Linter and Analysis Tools

### golangci-lint

Runs multiple linters in parallel. Configure which linters to use in `.golangci.yml`.

Prefer `go run` over a local binary -- this guarantees the exact version runs and avoids permission issues on Windows MSYS:

```bash
go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.1.6 run ./...
```

For CI, use `golangci-lint-action@v6` with a pinned version. The default install mode (binary) downloads pre-built binaries and handles v2 module paths correctly.

Common issues (see known-gotchas.md for detailed fixes):

- **G101** (gosec): Flags constants with "password", "credential", etc. in the name or value. Add `//nolint:gosec // G101: <reason>` on the line.
- **gocritic**: Catches code quality issues (paramTypeCombine, rangeValCopy, etc.). Fix individually per linter feedback.
- **staticcheck**: Static analysis for unreachable code, unused variables, logic errors.

### govulncheck

Scans for known vulnerabilities in dependencies:

```bash
go mod download
govulncheck ./...
```

### swag (Swagger)

Generates OpenAPI spec from Go handler comments. See known-gotchas.md sections 15-16 for drift issues.

```bash
swag init -g cmd/myapp/main.go -o api/swagger --parseDependency --parseInternal
```

## VS Code Extensions

- **golang.go** (official) — language server, debugging, test runner
- **eamodio.gitlens** — git blame, history, branches
- **streetsidesoftware.code-spell-checker** — catch typos in comments and strings

## Testing

```bash
go test ./...         # all tests in current package and subdirs
go test -race ./...   # with race detector (not available on Windows MSYS)
go test -v ./...      # verbose output
go test -cover ./...  # coverage report
```

## Build and Release

Use `Makefile` for common tasks. Copy `project-templates/Makefile.go` and customize. Key targets:

```text
build:          go build -o bin/app ./cmd/app/
test:           go test ./...
lint:           go run ...golangci-lint@v2.1.6 run ./...
ci:             build + test + lint + lint-md
hooks:          install pre-push git hook
```

Run `make hooks` after cloning to install the pre-push hook. The hook runs the same checks as CI before each push.

## Related Profiles

- **go-web** — if your project has HTTP handlers or gRPC services
