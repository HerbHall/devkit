# Claude Skills Ecosystem

How skills are organized across the three Claude surfaces.

## Surface Overview

| Surface | Skill Location | Install Method | Scope |
|---------|---------------|----------------|-------|
| **Claude Code** | `~/.claude/skills/` | `setup.ps1` or `setup/legacy/setup.sh` | Development sessions |
| **Cowork** | `~/.claude/skills/` | Same as Code (shared) | Task automation |
| **Chat (claude.ai)** | Anthropic cloud | Settings → Skills UI | Research / general |

Claude Code and Cowork share the same `~/.claude/skills/` directory.
Chat has its own separate skill store managed through the claude.ai UI.

## Intent by Surface

### Claude Code — deep development work

- Full tech stack context: Go, React, Docker, GitHub Actions
- Skills invoked with `/skill-name` in Code sessions
- Autolearn and quality-control integrate with the development loop

### Cowork — research and task automation

- Subset of skills that apply to file/research work
- Bash-linux, server-management, powershell-windows for infrastructure tasks
- Systematic-debugging for general troubleshooting outside a codebase

### Chat (claude.ai) — research and general use

- Skills installed separately via Settings → Skills in the UI
- Source files are the same SKILL.md files from this repo
- Useful set: requirements-generator, systematic-debugging, windows-development
- Research/planning oriented — not wired to the coding workflow

## Skill Classification

| Skill | Code | Cowork | Chat |
|-------|------|--------|------|
| autolearn | ✓ | — | — |
| quality-control | ✓ | — | — |
| manage-github-issues | ✓ | — | — |
| requirements-generator | ✓ | — | ✓ |
| setup-github-actions | ✓ | — | — |
| go-development | ✓ | — | — |
| react-frontend-development | ✓ | — | — |
| docker-containerization | ✓ | — | — |
| windows-development | ✓ | — | ✓ |
| bash-linux | ✓ | ✓ | — |
| powershell-windows | ✓ | ✓ | — |
| security-review | ✓ | — | — |
| server-management | ✓ | ✓ | — |
| systematic-debugging | ✓ | ✓ | ✓ |
| webapp-testing | ✓ | — | — |

## Adding a New Skill

1. Create `claude/skills/{name}/SKILL.md` in this repo
2. Run `setup/setup.ps1` (or `setup/legacy/setup.sh`) to deploy to `~/.claude/skills/`
3. For Chat: upload the skill folder via Settings → Skills in claude.ai
4. Update `setup/legacy/verify.sh` skill list
5. Update `README.md` skills table and `SKILLS-ECOSYSTEM.md` classification table

## Chat Skill Installation

Since Chat and Code/Cowork don't share skills, the SKILL.md files in this repo
serve as the single source of truth.

### Recommended Chat Skills

Install these in priority order based on research/general use pattern:

| Priority | Skill | Rationale |
|----------|-------|-----------|
| 1 | `requirements-generator` | Requirements gathering and MoSCoW prioritization -- useful for planning conversations |
| 2 | `systematic-debugging` | Problem-solving methodology that works without a codebase context |
| 3 | `windows-development` | Windows registry, shell patterns, and platform-specific guidance |
| 4 | `server-management` | UnRAID, Proxmox, infrastructure decision-making |
| 5 | `bash-linux` | Terminal patterns for remote server troubleshooting |

### Installation Steps

1. Go to claude.ai → Settings → Skills
2. Click "Add Skill" → "Upload folder"
3. Navigate to your local `devkit/claude/skills/` directory
4. Select a skill folder (e.g., `requirements-generator/`)
5. Upload -- the skill appears in the Skills list with green status
6. Repeat for each skill from the recommended list above

### Keeping Chat Skills in Sync

Chat skills do not auto-update when you pull new versions of devkit.
After updating the repo:

1. Check `claude/skills/` for modified SKILL.md files (`git diff --name-only`)
2. In claude.ai → Settings → Skills, remove the outdated version
3. Re-upload the updated skill folder
4. Verify the skill still appears with green status
