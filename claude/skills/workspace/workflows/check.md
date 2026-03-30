# Workspace Health Check

Audits all registered projects for workspace file issues without modifying anything.

## Steps

1. Read `~/.devkit-registry.json` to get the project list.

2. For each registered project, check:
   - Does `<project-root>/<project-name>.code-workspace` exist?
   - Is `folders[0].path` set to `.`?
   - Does the `extensions.recommendations` array have any entries?
   - Does the registry entry have a `vscodeWorkspace.lastSynced` timestamp?

3. Classify each project:
   - **clean**: workspace exists, `folders[0].path = "."`, extensions present
   - **missing**: no `.code-workspace` file exists
   - **stale-path**: workspace exists but `folders[0].path` is not `.`
   - **no-extensions**: workspace exists but `extensions.recommendations` is empty
   - **never-synced**: workspace exists but `vscodeWorkspace.lastSynced` is null

4. Report findings in a table:

   | Project | Path | Status | Last Synced |
   |---------|------|--------|-------------|
   | SubNetree | D:\DevSpace\SubNetree | clean | 2026-03-21 |
   | Runbooks | D:\DevSpace\Runbooks | missing | — |

5. Suggest next steps based on findings:
   - Missing → run `/workspace repair` or scaffold individually
   - Stale-path → run `/workspace repair`
   - Never-synced → run `/workspace sync-all`

## Notes

- This workflow is read-only. No files are modified.
- If the registry is missing, report it and suggest running `devkit-sync` to register projects.
