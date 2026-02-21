# Stack Profiles

Reference for the Kit 2 profile format. Profiles live in `profiles/*.md` and are
installed via `setup/stack.ps1`.

> **Status:** Stub. Full content added by issue #14 (profile format spec and parser).
> This file exists so issue #14 can "update" it rather than create it from scratch.

---

## Profile Format

Profiles are Markdown files with YAML frontmatter. The frontmatter is parsed by
`setup/lib/` (no external YAML module); the body is passed to Claude as context.

```markdown
---
name: go-cli
version: 1.0
description: Go CLI tools — no HTTP, no web server
requires: []
winget:
  - id: GoLang.Go
    check: "go version"
manual:
  - id: golangci-lint
    install: "go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    check: "golangci-lint --version"
vscode-extensions:
  - golang.go
claude-skills:
  - go-development
---

# Profile Title

Markdown body — when to use this profile, post-install notes, known gotchas.
This section is read by Claude Code when generating project CLAUDE.md files.
```

## Frontmatter Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Machine identifier (kebab-case) |
| `version` | string | yes | Semver for the profile itself |
| `description` | string | yes | One-line human description |
| `requires` | string[] | no | Names of profiles this depends on |
| `winget` | object[] | no | Winget packages with `id` and `check` |
| `manual` | object[] | no | Go-install or other manual installs |
| `vscode-extensions` | string[] | no | VS Code extension IDs |
| `claude-skills` | string[] | no | Skill folder names from `claude/skills/` |

## Available Profiles

| Profile | Description | Requires |
|---------|-------------|----------|
| `go-cli` | Go CLI tools | — |
| `go-web` | Go web + gRPC | `go-cli` |
| `iot-embedded` | ESP32 / ESPHome | — |

## Parser Notes

- Parser lives in `setup/lib/` as part of issue #14 implementation
- No external YAML module — custom minimal parser for this schema
- Circular dependency detection: `go-web` → `go-cli` → (none) is valid; A → B → A is rejected
- Missing optional fields return empty arrays/strings, not errors

## Related

- `setup/stack.ps1` — installs selected profiles
- `docs/DECISIONS.md` — rationale for Markdown+YAML frontmatter format choice
- Issues: #14 (parser), #15 (go-cli + go-web), #16 (iot-embedded), #17 (stack.ps1)
