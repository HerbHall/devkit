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

Setup creates symlinks from `~/.claude/` to the DevKit clone (or copies files in legacy mode), installs workspace configs (`.editorconfig`, `.markdownlint.json`), and runs verification.

## What's Included

### Portable (works as-is)

| Component | Count | Location |
|-----------|-------|----------|
| Rules (auto-loaded every session) | 8 files | `claude/rules/` |
| Skills (invoke with `/skill-name`) | 18 skills | `claude/skills/` |
| Agent templates | 7 agents | `claude/agents/` |
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
| `claude/` | Global Claude Code config — CLAUDE.md, 8 rules files (135+ patterns), 18 skills, 7 agent templates, hooks |
| `devspace/` | Workspace shared configs — .editorconfig, .markdownlint.json, VS Code fragments |
| `docs/` | Human-readable guides — architecture decisions, profile format spec |
| `machine/` | Machine state snapshots — VS Code extensions, tool versions |
| `mcp/` | MCP server inventory, config templates (no secrets), Memory bootstrap guide |
| `profiles/` | Kit 2 stack profiles — project type definitions (Go, React, IoT, etc.) |
| `project-templates/` | Kit 3 scaffolding — workspace CLAUDE.md template, project starter files |
| `setup/` | Setup scripts — PowerShell stubs (`*.ps1`, `lib/*.ps1`) and `legacy/` bash scripts |
| `METHODOLOGY.md` | Development process — phases, gates, decision framework |

## Synchronization

DevKit uses **symlinks** instead of copies. Files in `~/.claude/` are symbolic links pointing back to the DevKit clone. Editing `~/.claude/rules/autolearn-patterns.md` actually edits `devkit/claude/rules/autolearn-patterns.md`, so `git diff` in the clone shows changes instantly.

### Quick setup

```bash
# Clone DevKit, then create symlinks
pwsh -File devkit/setup/sync.ps1 -Link
```

This backs up any existing files in `~/.claude/`, creates symlinks for all shared files, and generates a machine identity for multi-machine sync.

### Subcommands (`/devkit-sync`)

| Command | Purpose |
|---------|---------|
| `/devkit-sync status` | Show symlink health, git status, drift report |
| `/devkit-sync push` | Commit changes and push to `sync/<machine-id>` branch |
| `/devkit-sync pull` | Fetch and pull latest from main |
| `/devkit-sync init` | First-time setup: create symlinks and machine identity |
| `/devkit-sync diff` | Show detailed diff of local changes vs main |
| `/devkit-sync unlink` | Replace symlinks with copies (portable snapshot) |

### Multi-machine workflow

1. Clone DevKit on each machine and run `sync.ps1 -Link`
2. The `SessionStart.sh` hook auto-pulls main at the start of every session
3. New patterns and gotchas accumulate via symlinks -- `/devkit-sync push` commits and pushes to a `sync/<machine-id>` branch
4. PRs merge each machine's changes into main, where other machines pick them up on next session start

Local-only files (`*.local.md`, `settings.local.json`, `.credentials*`) are never synced. See [ADR-0011](docs/ADR-0011-sync-architecture.md) for the full rationale and alternatives considered.

### Project registry

DevKit can track which projects on a machine consume its configuration via a project registry (`~/.devkit-registry.json`). This enables querying which projects have local rules to promote and which need updating after a DevKit change. The registry is machine-local and never committed to DevKit. See [docs/project-registry-schema.md](docs/project-registry-schema.md) for the schema and field descriptions.

### Forge support

DevKit supports GitHub natively via the `gh` CLI. Gitea repositories are supported through `tea` CLI behind a forge-detection wrapper that parses `git remote get-url origin` to choose the right tool automatically. Configure `forge.giteaUrl` in `~/.devkit-config.json` for self-hosted Gitea instances. See [docs/forge-abstraction.md](docs/forge-abstraction.md) for the full design and CLI mapping.

## Local Overrides

Rules files ending in `.local.md` provide machine-specific overrides that complement the universal rules. Claude Code loads all `*.md` files from `~/.claude/rules/` automatically, so a file like `~/.claude/rules/my-machine.local.md` is picked up alongside the synced rules -- no extra configuration needed.

**How it works:** Universal rules (`autolearn-patterns.md`, `known-gotchas.md`, etc.) are symlinked from DevKit and shared across machines. Local rules (`*.local.md`) are real files that live only on one machine. The sync system never touches them -- `.local.md` files are excluded via `.sync-manifest.json` `local_only_patterns` and `.gitignore`.

**When to use local overrides:**

- Machine-specific paths or tool locations (e.g., Python at a non-standard path)
- OS-specific gotchas that only apply to one workstation
- Patterns discovered during project work that aren't yet promoted to universal rules
- Temporary notes or reminders for the current machine

A starter template is available at [`project-templates/rules-local-template.md`](project-templates/rules-local-template.md). Copy it to `~/.claude/rules/` and rename with a `.local.md` suffix.

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

With symlinks active, changes flow automatically:

- **Pull**: `SessionStart.sh` auto-pulls main at session start. Manual: `/devkit-sync pull`
- **Push**: After accumulating patterns, run `/devkit-sync push` to commit and open a PR
- **Legacy (copy-based)**: `bash setup/legacy/setup.sh` still works if symlinks are not set up

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
| `agent-team-coordination.md` | - | Multi-agent team coordination rules and anti-patterns |
| `autolearn-patterns.md` | 76 | Learned patterns: lint fixes, CI config, architecture, testing |
| `compaction-recovery.md` | - | Context compaction recovery rules and loop detection |
| `known-gotchas.md` | 60 | Platform issues: Windows, GitHub, Go, React, Docker |
| `markdown-style.md` | - | Markdownlint conventions |
| `review-policy.md` | - | Independent review policy: mandatory triggers and scope |
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
| code-review | Independent code review gate before commits | Code |
| plan-review | Independent plan review gate before implementation | Code |
| devkit-sync | Multi-machine DevKit sync: status, push, pull, init, diff | Code |

### Agent Templates

| Agent | Purpose |
|-------|---------|
| go-test-writer | Table-driven Go tests, benchmarks, mock interfaces |
| plan-reviewer | Adversarial plan review with fresh context |
| review-code | Security + quality review with verdict |
| security-analyzer | OWASP-focused vulnerability analysis |
| portfolio-analyzer | Scans all agent/skill locations for overlap and gaps |
| vscode-test-writer | VS Code extension test generation |
| vscode-translation-manager | VS Code extension localization management |

## License

MIT
