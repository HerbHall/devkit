# devkit

Personal development methodology and Claude Code configuration. Clone this repo to replicate the full development environment on any machine.

## What's Inside

| Directory | Purpose |
|-----------|---------|
| `claude/` | Global Claude Code config — CLAUDE.md, 5 rules files (70+ patterns), 14 skills, 6 agent templates, hooks |
| `devspace/` | Workspace shared configs — .editorconfig, .markdownlint.json, project templates, VS Code fragments |
| `mcp/` | MCP server inventory, config templates (no secrets), Memory bootstrap guide |
| `setup/` | Automated setup scripts for new machines |
| `METHODOLOGY.md` | Development process — phases, gates, decision framework |

## Quick Setup

```bash
# 1. Clone the repo into your workspace root
cd /d/DevSpace  # or wherever your projects live
git clone https://github.com/HerbHall/devkit.git

# 2. Check prerequisites
bash devkit/setup/install-tools.sh

# 3. Run setup (installs Claude config + workspace configs)
bash devkit/setup/setup.sh
```

The setup script:

- Copies rules, skills, agents, and hooks to `~/.claude/`
- Installs `.editorconfig` and `.markdownlint.json` at the workspace root
- Copies project templates and VS Code setting fragments
- Creates `settings.json` from template (if none exists)
- Runs verification to confirm everything is in place

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

# Create settings from template
cp claude/settings.template.json ~/.claude/settings.json
# Then edit settings.json to add project-specific tool permissions
```

### MCP Servers

```bash
# Copy and customize the desktop config
cp mcp/claude-desktop.template.json "%APPDATA%/Claude/claude_desktop_config.json"
# Edit the file and replace all <PLACEHOLDER> values with your tokens/paths
```

See [mcp/servers.md](mcp/servers.md) for the full server inventory and install instructions.

### Workspace Configs

```bash
# These go at your workspace root (parent of all projects)
cp devspace/.editorconfig /d/DevSpace/.editorconfig
cp devspace/.markdownlint.json /d/DevSpace/.markdownlint.json
cp -r devspace/templates /d/DevSpace/.templates
cp -r devspace/shared-vscode /d/DevSpace/.shared-vscode
```

## Starting a New Project

```bash
# 1. Create the project directory
mkdir /d/DevSpace/my-project && cd /d/DevSpace/my-project
git init

# 2. Copy the CLAUDE.md template
cp /d/DevSpace/.templates/claude-md-template.md CLAUDE.md
# Edit CLAUDE.md with project-specific build commands and architecture

# 3. (Optional) Copy other templates as needed
cp /d/DevSpace/.templates/adr-template.md docs/decisions/ADR-001.md
cp /d/DevSpace/.templates/design-template.md docs/designs/DES-001.md

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
cd /d/DevSpace/devkit
git pull
bash setup/setup.sh  # Re-runs setup (safe, backs up existing files)
```

### Machine to repo (capture changes)

When you've accumulated new patterns, skills, or config changes:

```bash
# Copy updated rules back to repo
cp ~/.claude/rules/*.md /d/DevSpace/devkit/claude/rules/

# Copy new/updated skills
cp -r ~/.claude/skills/my-new-skill /d/DevSpace/devkit/claude/skills/

# Commit and push
cd /d/DevSpace/devkit
git add -A && git commit -m "chore: sync config from workstation"
git push
```

## What's NOT in This Repo

- **API keys and tokens** — Use placeholders in templates, fill in per machine
- **MCP Memory data** — Accumulates organically; see `mcp/memory-seeds.md` for bootstrap
- **Session state** — Debug logs, file history, task state (machine-specific, not portable)
- **Project-specific CLAUDE.md** — Each project has its own; only the template is here

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

| Skill | Purpose |
|-------|---------|
| autolearn | Session learning capture and reflection |
| dashboard | Session control station with project state |
| quality-control | CI verification and PR health checks |
| research-mode | Competitive analysis and market research |
| manage-github-issues | Issue generation, audit, and triage |
| requirements-generator | Requirements.md creation |
| setup-github-actions | CI/CD workflow generation |
| go-development | Go patterns and conventions |
| react-frontend-development | React + TypeScript patterns |
| docker-containerization | Docker best practices |
| windows-development | Windows-specific patterns |
| coordination-sync | Cross-project coordination |
| pm-view | Project management overview |
| dev-mode | Development session toggle |

## License

MIT
