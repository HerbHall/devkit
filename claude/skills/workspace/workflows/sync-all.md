# Sync All Workspace Extensions

Runs `scripts/Sync-WorkspaceExtensions.ps1` against all registered projects to ensure extension recommendations reflect the current stack fragments in `devspace/shared-vscode/`.

## Steps

1. Locate the DevKit `scripts/` directory:

   ```text
   C:\Users\<user>\.devkit-stable\scripts\Sync-WorkspaceExtensions.ps1
   ```

2. Run a dry-run first to show what would change:

   ```powershell
   pwsh -File "$env:USERPROFILE\.devkit-stable\scripts\Sync-WorkspaceExtensions.ps1" -WhatIf
   ```

3. Show the dry-run output. If changes are needed, ask for confirmation before applying.

4. If the user confirms (or if there are no changes), run without `-WhatIf`:

   ```powershell
   pwsh -File "$env:USERPROFILE\.devkit-stable\scripts\Sync-WorkspaceExtensions.ps1"
   ```

5. Report the summary (clean / updated / missing / errors).

6. Verify that `vscodeWorkspace.lastSynced` was updated in `~/.devkit-registry.json` for each touched project.

7. If any projects show as `missing` (no workspace file), suggest running `/workspace repair` first.

## What the Script Does

For each registered project:

1. Detects the stack (`go`, `typescript`, `rust`, `base`) from files at the project root.
2. Loads stack + general extension recommendations from `devspace/shared-vscode/extensions.jsonc`.
3. Merges them into `extensions.recommendations` in the project's `.code-workspace`.
   - Extensions already in the fragment: kept as-is.
   - Project-specific extensions not in the fragment: preserved.
   - Extensions that were removed from the fragment: removed from the workspace file.
4. Updates `vscodeWorkspace.lastSynced` and `vscodeWorkspace.stackProfile` in the registry.

## Notes

- Only registered projects (in `~/.devkit-registry.json`) are synced.
- Projects with no `.code-workspace` file are reported but not modified — run `/workspace repair` first.
- Project-specific extension additions that are not in the DevKit fragment are always preserved.
- This workflow does not touch `settings` in workspace files — only `extensions.recommendations`.
