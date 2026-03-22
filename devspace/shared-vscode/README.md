# Shared VS Code Fragments

Reusable VS Code setting snippets for project workspace files. These are **NOT auto-loaded** — VS Code does not cascade workspace settings from parent directories.

## How to Use

**Manual (copy-paste):**

1. Open the fragment file relevant to your project type
2. Copy the settings you need into your project's `.code-workspace` file
3. Adjust paths and project-specific values

```jsonc
// In your-project.code-workspace, merge what you need:
{
    "settings": {
        // Paste from typescript.jsonc, go.jsonc, etc.
    },
    "extensions": {
        "recommendations": [
            // Paste from extensions.jsonc for your stack
        ]
    }
}
```

**Automated (DevKit skill):**

Use `/workspace scaffold` to create a new workspace file with the correct fragment merged in automatically, or `/workspace sync-all` to sync extension recommendations across all registered projects. See `docs/vscode-workspaces.md` for full details on the workspace convention and automation tools.

## Important

- **Don't duplicate User Settings.** If something is already in your VS Code User Settings (Tier 1), don't repeat it in the workspace file. Only add the delta.
- **Don't duplicate .editorconfig.** Indent style, charset, and line endings are handled by `.editorconfig` at `D:\DevSpace\` (Tier 2 auto-cascading). Don't replicate those as VS Code settings.
- **These are starting points.** Projects own their copies and can diverge as needed.

## Available Fragments

| Fragment | For Projects Using |
|----------|--------------------|
| `typescript.jsonc` | TypeScript, React, Node.js |
| `go.jsonc` | Go |
| `extensions.jsonc` | Common extension recommendations by project type (all stacks) |

Rust and C# projects fall back to base extensions only — no settings fragment exists yet. See `docs/vscode-workspaces.md` for the stack detection heuristic.
