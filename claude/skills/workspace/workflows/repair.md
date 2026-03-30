# Repair Workspace Files

Runs `scripts/Repair-WorkspaceFiles.ps1` to locate, classify, and repair orphaned or stale workspace files under `D:\DevSpace\`.

## Steps

1. Locate the DevKit `scripts/` directory. If DevKit is installed at `~/.devkit-stable/`, the script is at:

   ```text
   C:\Users\<user>\.devkit-stable\scripts\Repair-WorkspaceFiles.ps1
   ```

2. Run a dry-run first to show what would change:

   ```powershell
   pwsh -File "$env:USERPROFILE\.devkit-stable\scripts\Repair-WorkspaceFiles.ps1" -WhatIf
   ```

3. Show the dry-run output to the user and ask for confirmation before applying.

4. If the user confirms, run without `-WhatIf` to apply repairs:

   ```powershell
   pwsh -File "$env:USERPROFILE\.devkit-stable\scripts\Repair-WorkspaceFiles.ps1"
   ```

5. Report the summary (valid / misplaced / stale-path / missing / repaired).

6. For any scaffolded (`missing`) files, remind the user to:
   - Review the scaffolded workspace file
   - Merge settings from `devspace/shared-vscode/<stack>.jsonc` into the `settings` block
   - Run `/workspace sync-all` to populate extension recommendations

## What the Script Repairs

| Classification | Action |
|----------------|--------|
| `valid` | No change |
| `misplaced` | Moves workspace to `<project-root>/<project-name>.code-workspace`, rewrites `folders[0].path` to `.` |
| `stale-path` | Rewrites `folders[0].path` to `.` in place |
| `missing` | Scaffolds a new workspace from `project-templates/workspace.code-workspace` |

## Notes

- The script requires the DevKit registry (`~/.devkit-registry.json`) to detect missing workspace files. If the registry is absent, it still repairs existing files but cannot detect missing ones.
- Always run with `-WhatIf` first on production machines to preview changes.
- The script does not modify `valid` files.
