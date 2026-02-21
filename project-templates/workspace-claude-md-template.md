# Workspace CLAUDE.md Template

> **Template**: Customize this file for your workspace. Replace `WORKSPACE_ROOT`
> with your actual path (e.g., `D:\DevSpace`, `~/workspace`, `/home/user/projects`).
> Replace the example project inventory with your own projects.

Primary development workspace at `WORKSPACE_ROOT`. All active projects live here.

## Settings Philosophy: Three-Tier Consistency

Consistency across projects without bloat. Settings live at the **highest level where they're universal**, and only push down what's specific. Three tiers:

### Tier 1: VS Code User Settings (global, automatic)

Location: VS Code User Settings (platform-dependent: `%APPDATA%\Code\User\settings.json` on Windows, `~/Library/Application Support/Code/User/settings.json` on macOS, `~/.config/Code/User/settings.json` on Linux).

Things that are truly universal -- theme, font, tab size, format-on-save, git autofetch. These apply to every project automatically with zero duplication.

### Tier 2: Workspace shared configs (automatic for some, reference for others)

Location: `WORKSPACE_ROOT` (this directory)

Two categories -- understand the difference:

**Auto-cascading files** -- these tools walk up parent directories by spec, so every project under the workspace inherits them automatically:

| File | Tool | How It Cascades |
|------|------|----------------|
| `.editorconfig` | EditorConfig spec | Editors walk up directories until `root = true` |
| `.markdownlint.json` | markdownlint | Walks up directories to find config |

Projects can override with a local copy. For `.editorconfig`, use `root = false` or omit `root` to inherit, or `root = true` to stop the walk.

**Reference resources** -- these do NOT auto-apply. Projects copy or reference what they need:

| Directory | Purpose |
|-----------|---------|
| `.templates/` | Starter files for new projects (ADRs, design docs, CLAUDE.md boilerplate) |
| `.shared-vscode/` | Reusable VS Code setting fragments -- copy into project workspace files |

### Tier 3: Project-level settings (scoped, intentional)

Location: `WORKSPACE_ROOT/{Project}/`

Each project has its own workspace file that defines only the **delta** from Tiers 1 and 2. The workspace file adds project-specific things like TypeScript SDK paths, project-specific extension recommendations, or folder exclusions unique to that project.

Within a multi-root workspace, settings cascade: **User -> Workspace -> Folder** (folder wins). Each folder in a workspace can have `.vscode/settings.json` for folder-specific overrides.

### What does NOT cascade

**VS Code workspace settings do not inherit from parent directories.** Each workspace file is independent. Shared VS Code patterns go in `.shared-vscode/` as copyable fragments.

## Directory Structure

```text
WORKSPACE_ROOT/
├── CLAUDE.md                  # This file — workspace-wide conventions
├── .editorconfig              # Tier 2: auto-cascading editor config
├── .markdownlint.json         # Tier 2: auto-cascading markdown rules
├── .claude/                   # Claude Code settings for workspace scope
│   └── settings.local.json
│
├── .templates/                # Tier 2: starter files for new projects
│   ├── README.md              #   Usage guide
│   ├── adr-template.md        #   Architecture Decision Record template
│   ├── design-template.md     #   Design doc / lightweight RFC template
│   ├── test-plan-template.md  #   Test plan template
│   └── claude-md-template.md  #   CLAUDE.md boilerplate for new projects
│
├── .shared-vscode/            # Tier 2: copyable VS Code fragments
│   ├── README.md              #   How to use these fragments
│   ├── typescript.jsonc       #   TypeScript/React project settings
│   ├── go.jsonc               #   Go project settings
│   └── extensions.jsonc       #   Common extension recommendations
│
├── project-alpha/             # Example: your first project
├── project-beta/              # Example: your second project
└── devkit/                    # This repo (cloned into workspace)
```

## Conventions

- Every project has its own `CLAUDE.md` with build commands and architecture
- Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- Always cite sources in code and documentation
- Maintain `README.md` for GitHub with credits section

## Adding a New Project

1. Create a folder under `WORKSPACE_ROOT`
2. Copy `CLAUDE.md` boilerplate from `.templates/claude-md-template.md`
3. Copy relevant VS Code fragments from `.shared-vscode/` into your workspace file
4. `.editorconfig` and `.markdownlint.json` apply automatically -- no action needed
5. Give each project its own workspace file

## Optional: Coordination System

For multi-project workflows, you can create a `.coordination/` directory (gitignored) with hub files for cross-project state:

| File | Purpose |
|------|---------|
| `DASHBOARD.md` | Session control station |
| `status.md` | Current state of coordinated projects |
| `priorities.md` | Unified priority stack |
| `decisions.md` | Cross-project architectural decisions |

This pattern works well with project-specific skills that read/write these files. See the devkit METHODOLOGY.md for the full cross-project learning workflow.
