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
    install: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
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

Create a `.golangci.yml` at the project root. Start with:

```yaml
run:
  timeout: 5m
  skip-dirs:
    - testdata

linters:
  enable:
    - gosimple
    - govet
    - gocritic
    - gosec
    - staticcheck
    - revive

issues:
  exclude-rules:
    - linters: [gosec]
      text: "G101"
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

Runs multiple linters in parallel. Configure which linters to use in `.golangci.yml`:

```bash
golangci-lint run ./...
```

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

Use `Makefile` or `just` for common tasks. Typical targets:

```makefile
build:
  go build -o dist/app ./cmd/app

test:
  go test -race ./...

lint:
  golangci-lint run ./...

clean:
  rm -rf dist/
```

## Related Profiles

- **go-web** — if your project has HTTP handlers or gRPC services
