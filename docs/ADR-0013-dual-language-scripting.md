# ADR-0013: Dual-Language Scripting Strategy

## Status

Accepted

## Date

2026-02-25

## Context

DevKit contains two categories of scripts:

1. **Setup and sync scripts** that install tools, create symlinks, manage machine config, and interact with the OS
2. **Hooks and shell functions** that integrate with Claude Code's runtime environment

These categories have different requirements. Setup scripts benefit from structured error handling, JSON parsing, and Windows API access (Credential Manager, registry). Hooks must execute in Claude Code's bash environment and be portable across operating systems.

The question is: should DevKit standardize on one language, or use each where it fits best?

## Decision

Use **PowerShell 7** for setup/sync scripts and **bash** for hooks and Claude Code integration. Each language owns a clear domain with no overlap.

### Language Boundaries

| Domain | Language | Rationale |
|--------|----------|-----------|
| Setup scripts (`setup/*.ps1`) | PowerShell 7 | Structured error handling, JSON parsing, Windows API access, cross-platform via `pwsh` |
| Setup libraries (`setup/lib/*.ps1`) | PowerShell 7 | Shared by setup scripts, same rationale |
| Hooks (`claude/hooks/*.sh`) | Bash | Claude Code requires bash for hooks |
| Shell functions (`claude/claude-functions.sh`) | Bash | Sourced in user's shell profile (bash/zsh) |
| Skill scripts (`claude/skills/*/scripts/*.ps1`) | PowerShell 7 | OS-specific automation (e.g., registry, context menus) |
| Legacy scripts (`setup/legacy/*.sh`) | Bash | Deprecated; kept for reference only |

### Requirements by Language

**PowerShell 7 scripts MUST:**

- Include `#Requires -Version 7.0` as the first executable statement
- Use `Set-StrictMode -Version Latest` after `param()` block
- Use `$ErrorActionPreference = 'Stop'` for setup scripts (not libraries)
- Use `Join-Path` for path construction (never string concatenation)
- Use `$HOME` for home directory (never `$env:USERPROFILE` or hardcoded paths)
- Use `[IO.Path]::GetTempFileName()` for temp files

**Bash scripts MUST:**

- Include `#!/usr/bin/env bash` shebang (or `#!/bin/bash` for hooks)
- Include `set -euo pipefail` for standalone scripts (not function-definition files)
- Use `$HOME` for home directory (never hardcoded paths)
- Use only POSIX-compatible commands: `grep`, `sed`, `git`, `timeout`
- Handle MSYS path translation where needed (`sed 's|\\\\|/|g'`)

### What MUST NOT happen

- No inline PowerShell in bash scripts
- No inline bash in PowerShell scripts
- No mixed-language wrapper scripts
- No `cmd.exe /c` invocations (use PowerShell or bash directly)

### Cross-Platform Scope

Not all PowerShell scripts are cross-platform, and that is intentional:

| Script | Windows | macOS | Linux | Notes |
|--------|:-------:|:-----:|:-----:|-------|
| `bootstrap.ps1` | Yes | No | No | Uses winget, Windows Credential Manager |
| `stack.ps1` | Yes | No | No | Installs via winget |
| `sync.ps1` | Yes | Future | Future | Symlink logic is portable; needs testing |
| `new-project.ps1` | Yes | Future | Future | Core logic is portable |
| `SessionStart.sh` | Yes | Yes | Yes | Portable bash |
| `claude-functions.sh` | Yes | Yes | Yes | Portable bash |

Cross-platform `bootstrap` and `stack` equivalents (using `apt`, `brew`, etc.) are future work tracked by issue #82.

## Alternatives Considered

### Bash only

Use bash for everything, including setup scripts.

**Rejected because:**

- Bash has no structured error handling (`set -e` is fragile and unintuitive for complex scripts)
- JSON parsing in bash requires `jq` (not always available) or Python (workaround-heavy)
- Windows Credential Manager, registry access, and winget integration are natural in PowerShell
- The legacy bash scripts (`setup/legacy/`) demonstrate the maintenance cost: 3 scripts doing what 1 PowerShell script handles with better error reporting

### PowerShell only

Use PowerShell for everything, including hooks.

**Rejected because:**

- Claude Code hooks MUST be bash. This is a hard runtime constraint.
- Shell functions sourced in `.bashrc`/`.zshrc` must be bash/zsh
- PowerShell is not a default shell on Linux/macOS (requires explicit `pwsh` install)

### Python

Use Python for setup scripts.

**Rejected because:**

- Python availability on Windows is unreliable (known gotcha #8: Windows Store aliases shadow real Python)
- Adds a bootstrapping dependency: need Python to install Python
- PowerShell is included with Windows and available cross-platform via `pwsh`

## Consequences

### Positive

- **Clear ownership**: Each file's language is determined by its domain, not by preference
- **No mixed-language debugging**: Errors are always in one language's stack
- **Leverage strengths**: PowerShell for OS integration, bash for portability
- **Claude Code compatibility**: Hooks always work because they're always bash

### Negative

- **Two languages to maintain**: Contributors need familiarity with both PowerShell and bash
- **Duplication potential**: Some logic (path resolution, config reading) exists in both languages
- **PowerShell install required**: Linux/macOS users must install `pwsh` for setup scripts (bash legacy scripts remain as fallback)

## References

- [ADR-0012: Three-Tier Architecture](ADR-0012-three-tier-architecture.md) -- defines which files are universal vs machine-specific
- [Issue #83: Dual-language scripting strategy](https://github.com/HerbHall/devkit/issues/83)
- [Issue #82: Cross-platform support](https://github.com/HerbHall/devkit/issues/82)
