# devkit

Personal development methodology and Claude Code configuration. Clone this repo to replicate the full development environment on any machine.

## Quick Start

**Primary (PowerShell):**

```powershell
# 1. Clone into your workspace root
cd ~/workspace  # or wherever your projects live
git clone https://github.com/HerbHall/devkit.git

# 2. Install everything
pwsh -File devkit/setup/setup.ps1
```

**Legacy (Git Bash):**

```bash
bash devkit/setup/legacy/install-tools.sh
bash devkit/setup/legacy/setup.sh
bash devkit/setup/legacy/verify.sh
```

Setup copies rules, skills, agents, and hooks to `~/.claude/`, installs workspace configs (`.editorconfig`, `.markdownlint.json`), and runs verification.

## What's Included

### Portable (works as-is)

| Component | Count | Location |
|-----------|-------|----------|
| Rules (auto-loaded every session) | 5 files | `claude/rules/` |
| Skills (invoke with `/skill-name`) | 17 skills | `claude/skills/` |
| Agent templates | 6 agents | `claude/agents/` |
| SessionStart hook | 1 | `claude/hooks/` |
| Setup + verification scripts | 3 | `setup/legacy/` |

### Templates (customize per user/machine)

| File | Purpose |
|------|---------|
| `claude/settings.template.json` | Claude Code settings — adjust permissions and plugins |
| `project-templates/workspace-claude-md-template.md` | Workspace CLAUDE.md template — fill in your projects |
| `mcp/memory-seeds.md` | MCP Memory bootstrap — replace with your profile |
| `mcp/claude-desktop.template.json` | MCP server config — fill in tokens and paths |

### Methodology (opinionated process guide)

`METHODOLOGY.md` — 6-phase development process (Concept, Research, Specification, Prototype, Implementation, Release) with gates, templates, and a decision framework. Use as-is or adapt to your workflow.

## What's Inside

| Directory | Purpose |
|-----------|---------|
| `claude/` | Global Claude Code config — CLAUDE.md, 5 rules files (70+ patterns), 17 skills, 6 agent templates, hooks |
| `devspace/` | Workspace shared configs — .editorconfig, .markdownlint.json, VS Code fragments |
| `docs/` | Human-readable guides — architecture decisions, profile format spec |
| `machine/` | Machine state snapshots — VS Code extensions, tool versions |
| `mcp/` | MCP server inventory, config templates (no secrets), Memory bootstrap guide |
| `profiles/` | Kit 2 stack profiles — project type definitions (Go, React, IoT, etc.) |
| `project-templates/` | Kit 3 scaffolding — workspace CLAUDE.md template, project starter files |
| `setup/` | Setup scripts — PowerShell stubs (`*.ps1`, `lib/*.ps1`) and `legacy/` bash scripts |
| `METHODOLOGY.md` | Development process — phases, gates, decision framework |

## Manual Setup

If you prefer to set things up yourself:

### Claude Code Configuration

```bash
# Copy global instructions
cp claude/CLAUDE.md ~/.claude/CLAUDE.md

# Copy rules (auto-loaded every session)
cp claude/rules/*.md ~/.claude/rules/

# Copy skills (available as /skill-name in sessions)
cp -r claude/skills/* ~/.claude/skills/

# Copy agent templates
cp claude/agents/*.md ~/.claude/agents/

# Copy hooks
cp claude/hooks/* ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# Create settings from template (only if none exists)
cp claude/settings.template.json ~/.claude/settings.json
# Then edit settings.json to adjust permissions and plugins
```

### MCP Servers

```bash
# Copy and customize the desktop config
cp mcp/claude-desktop.template.json "$HOME/.config/Claude/claude_desktop_config.json"
# Edit the file and replace all <PLACEHOLDER> values with your tokens/paths
```

See [mcp/servers.md](mcp/servers.md) for the full server inventory and install instructions.

### Workspace Configs

```bash
# These go at your workspace root (parent of all projects)
WORKSPACE="$HOME/workspace"  # adjust to your path
cp devspace/.editorconfig "$WORKSPACE/.editorconfig"
cp devspace/.markdownlint.json "$WORKSPACE/.markdownlint.json"
cp -r devspace/templates "$WORKSPACE/.templates"
cp -r devspace/shared-vscode "$WORKSPACE/.shared-vscode"
```

## Starting a New Project

```bash
# 1. Create the project directory
mkdir ~/workspace/my-project && cd ~/workspace/my-project
git init

# 2. Copy the CLAUDE.md template
cp ~/workspace/.templates/claude-md-template.md CLAUDE.md
# Edit CLAUDE.md with project-specific build commands and architecture

# 3. (Optional) Copy other templates as needed
cp ~/workspace/.templates/adr-template.md docs/decisions/ADR-001.md
cp ~/workspace/.templates/design-template.md docs/designs/DES-001.md

# 4. Follow the methodology (see METHODOLOGY.md)
# Phase 0: Write a concept brief
# Phase 1: Research the landscape
# Phase 2: Specification (requirements + decisions)
# ...
```

## Updating

Changes flow in two directions:

### Repo to machine (pull updates)

```bash
cd ~/workspace/devkit
git pull
bash setup/legacy/setup.sh  # Re-runs setup (safe, backs up existing files)
```

### Machine to repo (capture changes)

When you've accumulated new patterns, skills, or config changes:

```bash
# Copy updated rules back to repo
cp ~/.claude/rules/*.md ~/workspace/devkit/claude/rules/

# Copy new/updated skills
cp -r ~/.claude/skills/my-new-skill ~/workspace/devkit/claude/skills/

# Commit and push
cd ~/workspace/devkit
git add -A && git commit -m "chore: sync config from workstation"
git push
```

## What's NOT in This Repo

- **API keys and tokens** — Use placeholders in templates, fill in per machine
- **MCP Memory data** — Accumulates organically; see `mcp/memory-seeds.md` for bootstrap
- **Session state** — Debug logs, file history, task state (machine-specific, not portable)
- **Project-specific CLAUDE.md** — Each project has its own; only the template is here
- **Project-specific skills** — Skills tied to specific projects (dashboards, coordination, research workflows) belong in those projects' `.claude/` directories, not here

## File Inventory

### Rules (auto-loaded every Claude Code session)

| File | Entries | Purpose |
|------|---------|---------|
| `autolearn-patterns.md` | 70+ | Learned patterns: lint fixes, CI config, architecture, testing |
| `known-gotchas.md` | 47+ | Platform issues: Windows, GitHub, Go, React, Docker |
| `markdown-style.md` | - | Markdownlint conventions |
| `subagent-ci-checklist.md` | - | Pre-commit CI validation checklists |
| `workflow-preferences.md` | 11 | Established conventions: git, commits, testing |

### Skills (invoke with /skill-name)

Skills live in `claude/skills/` and install globally to `~/.claude/skills/` for Claude Code and Cowork.
Claude.ai Chat uses a separate skill store - install via Settings > Skills in the UI.

| Skill | Purpose | Best In |
|-------|---------|---------|
| autolearn | Session learning capture and reflection | Code |
| quality-control | CI verification and PR health checks | Code |
| manage-github-issues | Issue generation, audit, and triage | Code |
| requirements-generator | Requirements.md creation | Code/Chat |
| setup-github-actions | CI/CD workflow generation | Code |
| go-development | Go patterns and conventions | Code |
| react-frontend-development | React + TypeScript patterns | Code |
| docker-containerization | Docker best practices | Code |
| windows-development | Windows registry and shell integration | Code |
| bash-linux | Bash/Linux terminal patterns (UnRAID, Proxmox, Debian) | Code/Cowork |
| powershell-windows | PowerShell syntax, pitfalls, error handling | Code/Cowork |
| security-review | Security checklist: auth, input validation, secrets | Code |
| server-management | Process management, monitoring, scaling decisions | Code/Cowork |
| systematic-debugging | 4-phase debugging with root cause analysis | Code/Chat |
| webapp-testing | E2E testing, Playwright, deep audit strategies | Code |

### Agent Templates

| Agent | Purpose |
|-------|---------|
| go-test-writer | Table-driven Go tests, benchmarks, mock interfaces |
| review-code | Security + quality review with verdict |
| security-analyzer | OWASP-focused vulnerability analysis |
| portfolio-analyzer | Scans all agent/skill locations for overlap and gaps |
| vscode-test-writer | VS Code extension test generation |
| vscode-translation-manager | VS Code extension localization management |

## License

MIT
