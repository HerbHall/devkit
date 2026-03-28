# Claude Code Settings Strategy

How DevKit manages Claude Code permissions across user, project, and local scopes using a two-layer template system.

## Three-Scope Hierarchy

Claude Code resolves settings from three scopes, merged in order. Later scopes add to earlier ones, and `deny` rules always take precedence over `allow`.

| Scope | Location | Committed | Applies to |
|-------|----------|-----------|------------|
| User | `~/.claude/settings.json` | No (machine-local) | Every project on the machine |
| Project | `<project>/.claude/settings.json` | Yes | Anyone who clones the repo |
| Local | `<project>/.claude/settings.local.json` | No (gitignored) | Current machine only |

Permission arrays **merge** across scopes. If the user scope allows `Bash` and the project scope allows `Bash(git:*)`, both rules are active. A `deny` at any scope blocks the permission regardless of `allow` entries elsewhere.

**Claude Code does NOT cascade settings from parent directories.** Placing a `settings.json` in `D:\DevSpace\.claude\` does NOT apply to `D:\DevSpace\ProjectA\`. Each project is an independent scope. Only the user-level file at `~/.claude/settings.json` provides cross-project defaults. See [KG#61](../claude/rules/known-gotchas.md) for the full gotcha.

## Two-Layer Template System

DevKit provides two templates for different scopes:

### Layer 1: User-level template

**File:** `claude/settings.template.json`
**Installs to:** `~/.claude/settings.json`

This template provides **broad wildcards** that serve as the machine owner's baseline. It includes:

- Unrestricted tool access: `Bash`, `Read`, `Edit`, `Write`, `WebFetch`, `WebSearch`, `Glob`, `Grep`, `Task`, `Skill`, `mcp__*`
- SessionStart hooks (autolearn prompts)
- Plugin configuration (Context7, code review, GitHub, etc.)

**When to use:** Apply once per machine during DevKit setup. This is your personal trust boundary -- you are granting Claude Code broad access to your development environment. Adjust permissions if you prefer tighter control.

### Layer 2: Project-level template

**File:** `project-templates/settings.json`
**Installs to:** `<project>/.claude/settings.json`

This template provides **tool-specific Bash wildcards** that are safe to commit to a shared repository. It includes:

- Scoped Bash commands: `Bash(git:*)`, `Bash(gh:*)`, `Bash(make:*)`, `Bash(go:*)`, `Bash(docker:*)`, and common utilities
- Standard tool access: `Read`, `Edit`, `Write`, `Glob`, `Grep`, `Task`, `Skill`
- A deny rule for destructive operations: `Bash(rm -rf /)`
- MCP server auto-enable

**When to use:** Copy into every new project at `<project>/.claude/settings.json` and commit it. Collaborators who clone the repo get these permissions without manual tool-by-tool approval. Customize the Bash wildcards for the project's toolchain (remove `cargo:*` if it is not a Rust project, add `pnpm:*` for frontend projects, etc.).

## How They Work Together

```text
User scope (~/.claude/settings.json)
  allow: [Bash, Read, Edit, Write, WebFetch, WebSearch, ...]
  hooks: { UserPromptSubmit: [...] }
  plugins: { context7, code-review, ... }

  + merges with

Project scope (<project>/.claude/settings.json)
  allow: [Bash(git:*), Bash(go:*), Bash(make:*), ...]
  deny: [Bash(rm -rf /)]

  + merges with

Local scope (<project>/.claude/settings.local.json)
  (accumulated per-session approvals, not managed by DevKit)
```

The user scope provides the broad baseline. The project scope adds tool-specific patterns and deny rules. The local scope accumulates one-off approvals during interactive sessions.

## Applying the Templates

### First-time machine setup

```bash
# Copy user-level template (do this once per machine)
cp devkit/claude/settings.template.json ~/.claude/settings.json
```

Or use the DevKit setup script, which handles this automatically:

```powershell
pwsh -File devkit/setup/setup.ps1
```

### New project scaffolding

```bash
# Copy project-level template into a new or existing project
mkdir -p my-project/.claude
cp devkit/project-templates/settings.json my-project/.claude/settings.json
git -C my-project add .claude/settings.json
```

### Customizing permissions

- **To restrict a tool globally:** Add a `deny` entry to `~/.claude/settings.json`
- **To restrict a tool per-project:** Add a `deny` entry to `<project>/.claude/settings.json`
- **To allow a new tool globally:** Add an `allow` entry to `~/.claude/settings.json`
- **To allow a project-specific tool:** Add an `allow` entry to `<project>/.claude/settings.json`

## Skills Placement

Skills follow the same scoping principle as settings: **generic skills at user level, project-specific skills at project level.**

| Scope | Location | Example Skills |
|-------|----------|---------------|
| User | `~/.claude/skills/` | autolearn, devkit-sync, code-review, simplify |
| Project | `<project>/.claude/skills/` | dashboard, dev-mode, coordination-sync, pm-view |

**Rule of thumb:** If a skill reads project-specific files (e.g., `.coordination/status.md`) or routes to project-specific workflows, it belongs in `<project>/.claude/skills/`. If it works identically across all projects, it belongs at the user level.

DevKit's `claude/skills/` directory contains user-level skills. When scaffolding a new project, create project-specific skills directly in `<project>/.claude/skills/`.

## Automated Reconciliation

The `SessionStart.sh` hook automatically merges structural keys from `settings.template.json` into the live `~/.claude/settings.json` on every session start. This closes the gap where template changes (new `deny` rules, new hooks) never reached machines because `settings.json` was a one-time copy.

**What gets reconciled:**

- `permissions.deny` entries from template are added if missing
- `allow` entries matching new deny wildcards are removed
- Missing hook event types (UserPromptSubmit, Stop, SubagentStop) are added
- Missing top-level keys (`enableAllProjectMcpServers`, `autoUpdatesChannel`) are added

**What is preserved:**

- All accumulated `allow` entries (interactive approvals)
- All `enabledPlugins` customizations
- All existing hooks (only missing event types are added)
- A `.bak` backup is created before any modification

**Propagation flow:** Template change committed to DevKit -> pulled on next session start -> reconciled into live settings automatically. Zero manual intervention.

## Background

- [KG#61](../claude/rules/known-gotchas.md) -- Discovery that Claude Code settings do not cascade from parent directories
- [AP#86](../claude/rules/autolearn-patterns.md) -- Archived pattern on linter/hook leaking cross-branch changes in settings files
