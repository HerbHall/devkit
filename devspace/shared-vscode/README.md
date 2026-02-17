# Shared VS Code Fragments

Reusable VS Code setting snippets for project workspace files. These are **NOT auto-loaded** — VS Code does not cascade workspace settings from parent directories.

## How to Use

1. Open the fragment file relevant to your project type
2. Copy the settings you need into your project's `.code-workspace` file or `.vscode/settings.json`
3. Adjust paths and project-specific values

```jsonc
// In your-project.code-workspace, merge what you need:
{
    "settings": {
        // Paste from typescript.jsonc, go.jsonc, etc.
    },
    "extensions": {
        // Paste from extensions.jsonc
    }
}
```

## Important

- **Don't duplicate User Settings.** If something is already in your VS Code User Settings (Tier 1), don't repeat it in the workspace file. Only add the delta.
- **Don't duplicate .editorconfig.** Indent style, charset, and line endings are handled by `.editorconfig` at `D:\DevSpace\` (Tier 2 auto-cascading). Don't replicate those as VS Code settings.
- **These are starting points.** Projects own their copies and can diverge as needed.

## Available Fragments

| Fragment | For Projects Using |
|----------|--------------------|
| `typescript.jsonc` | TypeScript, React, Node.js |
| `go.jsonc` | Go |
| `extensions.jsonc` | Common extension recommendations by project type |
