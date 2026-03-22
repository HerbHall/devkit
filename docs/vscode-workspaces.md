# VS Code Workspace Convention

Defines how DevKit-managed projects structure, locate, and maintain their VS Code workspace files.

## Canonical Location

One workspace file per project, at the project root, named after the project:

```text
<project-root>/<project-name>.code-workspace
```

Examples:

- `D:\DevSpace\SubNetree\subnetree.code-workspace`
- `D:\DevSpace\Runbooks\runbooks.code-workspace`
- `D:\DevSpace\Toolkit\samverk\samverk.code-workspace`

## Required Structure

Every DevKit-managed workspace file must have these three top-level sections:

```jsonc
{
    "folders": [
        { "path": "." }
    ],
    "settings": {
        // Stack-specific settings merged from devspace/shared-vscode/<stack>.jsonc
        // Do not duplicate User Settings or .editorconfig values
    },
    "extensions": {
        "recommendations": [
            // Merged from devspace/shared-vscode/extensions.jsonc for this stack
        ]
    }
}
```

The `folders` array always contains a single entry pointing to `.` (the project root). Multi-root workspaces are out of scope for DevKit-managed projects.

## Stack Detection Heuristic

When scaffolding or syncing a workspace, the stack is detected from files at the project root:

| Indicator file | Stack profile | Fragment source |
|---|---|---|
| `go.mod` | `go` | `devspace/shared-vscode/go.jsonc` |
| `package.json` | `typescript` | `devspace/shared-vscode/typescript.jsonc` |
| `Cargo.toml` | `rust` | `devspace/shared-vscode/rust.jsonc` (stub — falls back to base) |
| `*.csproj` or `*.sln` | `csharp` | none yet — falls back to base |
| none of the above | `base` | no settings fragment; base extensions only |

For projects with multiple indicators (e.g., a Go backend + React frontend), the Go fragment takes precedence. The `stackProfile` field in the registry can be set explicitly to override heuristic detection for polyglot projects.

## Relation to `.vscode/settings.json`

These two files serve different purposes and must not duplicate each other:

| File | Purpose |
|------|---------|
| `<project>.code-workspace` | Project-scoped editor configuration — stack settings, extension recommendations |
| `.vscode/settings.json` | Claude Code project settings — tool permissions, hooks, MCP config |

Workspace-level settings live in `.code-workspace`. `.vscode/settings.json` is reserved for Claude Code and project-specific tool configuration. See `docs/settings-strategy.md` for the full settings hierarchy.

## What NOT to Put in the Workspace File

- **User Settings values**: Font family, theme, auto-save, git auto-fetch — these belong in VS Code User Settings (Tier 1 in `docs/settings-strategy.md`).
- **`.editorconfig` values**: Indent style, charset, line endings — the `D:\DevSpace\.editorconfig` file handles these via auto-cascade. Do not duplicate them as VS Code settings.
- **Secrets or credentials**: Workspace files are committed; never put tokens, passwords, or API keys in them.

## `.gitignore` Policy

`.code-workspace` files are committed. They define project-scoped editor configuration that every developer on the project should inherit. Do not add them to `.gitignore`.

## Registry Tracking

The project registry (`~/.devkit-registry.json`) records workspace state for each project. See `docs/project-registry-schema.md` for the `vscodeWorkspace` field definitions.

The `devkit workspace sync` skill reads and updates these fields automatically.

## Automation

| Tool | Purpose |
|------|---------|
| `scripts/Repair-WorkspaceFiles.ps1` | One-time recovery: locates, classifies, and repairs orphaned or missing workspace files |
| `scripts/Sync-WorkspaceExtensions.ps1` | Ongoing sync: ensures extension recommendations reflect the current stack fragments |
| `/workspace` skill | Claude Code skill for interactive workspace management (check, scaffold, repair, sync-all) |

Run `Repair-WorkspaceFiles.ps1 -WhatIf` first to preview changes before applying.

## Rust Projects

No `rust.jsonc` fragment exists yet. Rust projects fall back to `base` (extensions only, no settings fragment). A future issue will add the fragment when DevKit onboards a Rust project. Until then, document in project CLAUDE.md if project-specific Rust settings are needed.

## Deciding Whether to Add Workspace Sync to Automatic Hooks

**Decision: on-demand only (not automatic).**

Workspace sync is not added to `setup/sync.ps1` or any SessionStart hook. Reasons:

1. Workspace files are committed — unintended automated edits would create noisy commits.
2. Extension lists are stable; they only change when fragments are updated (infrequent).
3. On-demand via `/workspace sync-all` provides explicit control with a clear audit trail.

Revisit this decision if the workspace skill shows high manual invocation rate (>2x/week per project).
