# devkit

Windows AI development platform — packages machine bootstrap, stack profiles, and new project scaffolding into a three-kit PowerShell automation suite.

**Current state:** Architecture designed, all GitHub issues created (#3–#24), implementation not yet started. The existing files in `setup/` and `claude/` are the v1.0 bash-based system — they still work but are being superseded by the PowerShell three-kit system described below.

## What This Project Does

Three kits, one entry point (`setup.ps1`):

- **Kit 1 — Bootstrap** (`setup/bootstrap.ps1`): Gets a bare Windows machine dev-ready. Installs tools via winget, configures git, creates devspace directory, stores credentials in Windows Credential Manager, deploys Claude skills.
- **Kit 2 — Stack** (`setup/stack.ps1`): Adds tooling for a specific project type using profile files in `profiles/`. Profiles are Markdown+YAML — machine-parseable frontmatter, Claude-readable body.
- **Kit 3 — New Project** (`setup/new-project.ps1`): Collects a concept brief, scaffolds a GitHub repo with directory structure, generates a project CLAUDE.md via Claude Code (falls back to template if not authenticated).

## Target Directory Structure (not yet built)

```text
devkit/
├── setup.ps1                    # Entry point menu — reads VERSION file
├── VERSION                      # Single line semver, e.g. 1.1.0
├── setup/
│   ├── bootstrap.ps1            # Kit 1
│   ├── stack.ps1                # Kit 2
│   ├── new-project.ps1          # Kit 3
│   ├── backup.ps1               # Refresh machine/ snapshots
│   ├── verify.ps1               # Standalone pass/fail table
│   └── lib/
│       ├── ui.ps1               # Console output: Write-OK/Warn/Fail, menus, tables
│       ├── checks.ps1           # Tool/feature detection: Test-Tool, Test-HyperV, etc.
│       ├── install.ps1          # Winget wrappers: Install-WingetPackage, etc.
│       └── credentials.ps1     # Windows Credential Manager: Set/Get/Test-DevkitCredential
├── profiles/                    # Kit 2 stack profiles (Markdown+YAML)
│   ├── go-cli.md
│   ├── go-web.md
│   └── iot-embedded.md
├── machine/                     # Kit 1 snapshots (committed, refreshed by backup.ps1)
│   ├── winget.json
│   ├── vscode-extensions.txt
│   ├── git-config.template
│   └── manual-requirements.md
├── project-templates/           # Kit 3 scaffolding templates
│   ├── concept-brief.md
│   ├── claude-md-template.md
│   └── github-labels.json
├── docs/
│   ├── BOOTSTRAP.md
│   ├── PROFILES.md
│   └── DECISIONS.md             # Design rationale — READ THIS before implementing
├── claude/                      # Claude Code config (unchanged from v1.0)
│   ├── CLAUDE.md                # Global instructions → installed to ~/.claude/CLAUDE.md
│   ├── skills/                  # Invokable skills
│   ├── rules/                   # Auto-loaded pattern files
│   └── agents/
└── setup/legacy/                # Original bash scripts (deprecated, not deleted)
    ├── setup.sh
    ├── install-tools.sh
    └── verify.sh
```

## Implementation Status

| Phase | Issues | Status |
|-------|--------|--------|
| 1 — Infrastructure | #3–#8 | Not started — implement first |
| 2 — Bootstrap | #9–#13 | Not started — depends on Phase 1 |
| 3 — Profiles + Kit 2 | #14–#17 | Not started — depends on Phase 1 |
| 4 — Kit 3 New Project | #18–#20 | Not started — depends on Phases 1–3 |
| 5 — Fixes + CI | #21–#24 | Not started — #21–#23 are standalone, do these first |

**Start here:** Issues #21–#23 are standalone fixes to existing files, no dependencies. Good first work. Then Phase 1 (#3 repo structure, then #4–#7 lib functions in parallel, then #8 menu).

## PowerShell Conventions

All new code is PowerShell. Bash scripts in `setup/legacy/` are deprecated — do not add new bash.

```powershell
# File header — every .ps1 file
#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Dot-source lib dependencies at top of each script
. "$PSScriptRoot\lib\ui.ps1"
. "$PSScriptRoot\lib\checks.ps1"
```

- Target **PowerShell 5.1** minimum (ships with Windows 10/11). Use PS7 features only if wrapped in a version check.
- Functions follow `Verb-Noun` naming: `Install-WingetPackage`, `Test-Tool`, `Write-OK`
- Functions return `@{ Success=$bool; ... }` objects rather than throwing on failure
- Never use `Write-Host` directly — always go through `ui.ps1` functions
- No external module dependencies in lib files. YAML frontmatter parsing is done with a custom minimal parser (see issue #14)
- Credential names prefixed `devkit/` to avoid collision with system credentials

## Profile Format (Kit 2)

Profiles are Markdown files with YAML frontmatter. The frontmatter is parsed by PowerShell; the body is passed to Claude as context.

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

# Go CLI Profile

Body content here — used by Claude as project context.
```

Parser lives in `setup/lib/` as part of the profile system (issue #14). No external YAML module.

## Template Tokens

Both `claude/CLAUDE.md` (global) and `project-templates/claude-md-template.md` use `{{TOKEN}}` placeholders substituted by `bootstrap.ps1` and `new-project.ps1`:

| Token | Source |
|-------|--------|
| `{{USERNAME}}` | `$env:USERNAME` |
| `{{PLATFORM}}` | WMI OS caption |
| `{{DEVSPACE}}` | `~/.devkit-config.json` |
| `{{MACHINE}}` | `$env:COMPUTERNAME` |
| `{{PROJECT_NAME}}` | Kit 3 Step 1 input |
| `{{PROJECT_DESCRIPTION}}` | Concept brief first sentence |
| `{{PROFILE}}` | Selected profile name |

## Critical Gotchas

- `claude/CLAUDE.md` is the **global** config installed to `~/.claude/CLAUDE.md` — it is NOT this project's CLAUDE.md. Do not confuse these.
- `devspace/CLAUDE.md` is a **template** for workspace roots — not used directly by this project.
- The `YOUR_PLATFORM` placeholder in `claude/CLAUDE.md` is a known bug — tracked in issue #21.
- `METHODOLOGY.md` recommends BMAD which hangs on Windows — issue #21 adds a warning.
- `claude/skills/go-development/SKILL.md` contains Subnetree-specific content that doesn't belong here — issue #21.
- `known-gotchas.md` has non-contiguous numbering — issue #21.
- `AGENT-WORKFLOW-GUIDE.md` has Python pseudo-code for agent definitions — issue #22 replaces with correct `.claude/agents/*.md` format.
- Skill SKILL.md files referenced in routing tables must exist on disk (CI validates).
- `settings.template.json` must be valid JSON — easy to break with missing commas.
- Rules files (`claude/rules/*.md`) are loaded every Claude Code session — keep them concise.
- Placeholders use `{{DOUBLE_BRACES}}` for bootstrap substitution, `UPPERCASE_WITH_UNDERSCORES` for human-filled template stubs.

## Key Decisions

Design rationale for non-obvious choices is in `docs/DECISIONS.md`. Read it before making architectural choices. Key points:

- Profile format is Markdown+YAML frontmatter (not JSON/TOML) — machine-parseable and Claude-readable in one file
- No external PowerShell modules in lib — minimal parser for the small YAML subset used
- Kit 3 CLAUDE.md generation: Claude Code → graceful template fallback (not a hard requirement)
- Secrets go to Windows Credential Manager via `cmdkey` + WinRT PasswordVault — never `.env` files
- `setup.ps1` is a menu that dispatches to scripts; each kit script is also independently invokable
- All phases planned as GitHub issues before any implementation (done — issues #3–#24 exist)

## Testing

```powershell
# Lint all markdown
npx markdownlint-cli2 "**/*.md"

# Validate JSON templates
python -c "import json; json.load(open('claude/settings.template.json'))"

# Check for user-specific path leakage
Select-String -Path "claude/**","devspace/**","setup/**" -Pattern "HerbHall|Subnetree|D:\\DevSpace" -Recurse

# After implementing: test a lib function
. .\setup\lib\checks.ps1
Test-Tool -Name "git" -Command "git --version"
```

## Existing Files (v1.0 — do not delete)

```text
setup/install-tools.sh   -- bash prereq checker
setup/setup.sh           -- bash installer
setup/verify.sh          -- bash verifier
claude/                  -- all Claude config (skills, rules, agents, hooks) — unchanged
METHODOLOGY.md           -- 6-phase dev process (needs BMAD warning per issue #21)
```

---

**Note:** Add personal machine overrides to `CLAUDE.local.md` (gitignored).
