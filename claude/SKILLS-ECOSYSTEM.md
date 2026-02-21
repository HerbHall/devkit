# Claude Skills Ecosystem

How skills are organized across the three Claude surfaces.

## Surface Overview

| Surface | Skill Location | Install Method | Scope |
|---------|---------------|----------------|-------|
| **Claude Code** | `~/.claude/skills/` | `setup.sh` (auto) | Development sessions |
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
2. Run `setup/setup.sh` to deploy to `~/.claude/skills/`
3. For Chat: upload the skill folder via Settings → Skills in claude.ai
4. Update `setup/verify.sh` skill list
5. Update `README.md` skills table and `SKILLS-ECOSYSTEM.md` classification table

## Chat Skill Installation

Since Chat and Code/Cowork don't share skills, the SKILL.md files in this repo
serve as the single source of truth. To install in Chat:

1. Go to claude.ai → Settings → Skills
2. Click "Add Skill" → "Upload folder"
3. Upload the relevant skill folder from `claude/skills/`
4. Repeat for each skill you want available in Chat

Recommended Chat skills based on research/general use pattern:
`requirements-generator`, `systematic-debugging`, `windows-development`,
`server-management`, `bash-linux`
