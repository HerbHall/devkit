---
name: workspace
description: VS Code workspace management — scaffold, check health, repair orphans, and sync extension recommendations across DevKit-managed projects.
user_invocable: true
---

# DevKit Workspace

Manage VS Code workspace files across DevKit-managed projects. All operations follow the convention defined in `docs/vscode-workspaces.md`.

<essential_principles>

**One workspace file per project, at the project root.** Canonical location: `<project-root>/<project-name>.code-workspace`. The `folders[0].path` is always `.`.

**Stack-detect, then merge.** Settings and extensions come from `devspace/shared-vscode/` fragments. Projects own their copies and can add project-specific extensions — the sync scripts preserve those additions.

**On-demand only.** Workspace sync is not in any automatic hook. Run explicitly to keep things clean.

</essential_principles>

<intake>

**workspace triggered.** What do you need?

1. **Check** -- Audit all registered projects for missing, misplaced, or stale workspace files
2. **Scaffold** -- Create a workspace file for the current project (or a specified path)
3. **Repair** -- Fix orphaned or stale workspace files across D:\DevSpace\
4. **Sync all** -- Sync extension recommendations for all registered projects

Type a number, keyword, or **skip** to dismiss.

</intake>

<routing>

| Input | Workflow |
|-------|----------|
| 1, check, audit, health | `workflows/check.md` |
| 2, scaffold, create, new | `workflows/scaffold.md` |
| 3, repair, fix, orphan | `workflows/repair.md` |
| 4, sync, sync-all, extensions | `workflows/sync-all.md` |
| skip, dismiss, cancel, exit | End skill — no action |

</routing>
