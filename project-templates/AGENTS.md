<!--
  Scope: AGENTS.md guides the Copilot coding agent and Copilot Chat.
  For code completion and code review patterns, see .github/copilot-instructions.md
  and .github/instructions/*.instructions.md
  For Claude Code, see CLAUDE.md
-->

# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Tech Stack

{{TECH_STACK_SECTION}}

## Build and Test Commands

```bash
# Build
make build          # or: go build ./...

# Test
make test           # or: go test ./...

# Lint
make lint           # or: golangci-lint run ./...

# Full verification (run before any PR)
make verify         # or: go build ./... && go test ./... && golangci-lint run ./...
```

## Project Structure

{{PROJECT_STRUCTURE}}

## Workflow Rules

### Always Do

- Create a feature branch for every change (`feature/issue-NNN-description`)
- Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- Run build, test, and lint before opening a PR
- Write table-driven tests with descriptive names
- Wrap errors with context: `fmt.Errorf("operation: %w", err)`
- Fix every error you find, regardless of who introduced it

### Ask First

- Adding new dependencies (check if stdlib covers the need)
- Architectural changes (new packages, major interface changes)
- Database schema migrations
- Changes to CI/CD workflows
- Removing or renaming public APIs

### Never Do

- Commit directly to `main` -- always use feature branches
- Skip tests or lint checks -- even for "small changes"
- Use `--no-verify` or `--force` flags
- Commit secrets, credentials, or API keys
- Add TODO comments without a linked issue number
- Mark work as complete when build, test, or lint failures remain

## Core Principles

These are unconditional -- no optimization or time pressure overrides them:

1. **Quality**: Once found, always fix, never leave. There is no "pre-existing" error.
2. **Verification**: Build, test, and lint must pass before any commit.
3. **Safety**: Never force-push `main`. Never skip hooks. Never commit secrets.
4. **Honesty**: Never mark work as complete when it is not.

## Error Handling

```go
// Wrap errors with context -- every return site should add meaning
if err != nil {
    return fmt.Errorf("load config: %w", err)
}

// Use sentinel errors for caller-distinguishable conditions
var ErrNotFound = errors.New("not found")
if errors.Is(err, ErrNotFound) { ... }
```

## Testing Conventions

```go
// Table-driven tests with descriptive names
func TestFunctionName(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    string
        wantErr bool
    }{
        {
            name:  "valid input returns expected output",
            input: "example",
            want:  "result",
        },
        {
            name:    "empty input returns error",
            input:   "",
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := FunctionName(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("FunctionName() error = %v, wantErr %v", err, tt.wantErr)
            }
            if got != tt.want {
                t.Errorf("FunctionName() = %v, want %v", got, tt.want)
            }
        })
    }
}
```

## Commit Format

```text
feat: add user authentication endpoint

Implements JWT-based login and token refresh. Tokens expire after 1h.

Closes #42
Co-Authored-By: GitHub Copilot <copilot@github.com>
```

Types: `feat` (new feature), `fix` (bug fix), `refactor` (no behavior change),
`docs` (documentation only), `test` (tests only), `chore` (build/tooling).
