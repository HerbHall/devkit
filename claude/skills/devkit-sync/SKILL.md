---
name: devkit-sync
description: Manual sync operations for DevKit multi-machine synchronization. Status, push, pull, init, diff, unlink, promote, update, new-project scaffolding, and settings audit.
user_invocable: true
---

# DevKit Sync

Manual control for DevKit multi-machine synchronization. While auto-pull (SessionStart) and auto-push (/autolearn) handle routine sync, this skill provides manual operations for setup, forced sync, conflict resolution, and portable snapshots.

<essential_principles>

**DevKit sync uses symlinks, not copies.** Files in `~/.claude/` are symlinks pointing to the DevKit clone. Editing `~/.claude/rules/foo.md` actually edits `devkit/claude/rules/foo.md`, and `git diff` in the DevKit clone shows changes instantly.

**Machine identity matters.** Each machine has a `.machine-id` used in sync branch names (`sync/<machine-id>`) and commit messages. This prevents cross-machine conflicts.

**Local files are never synced.** Files matching `*.local.md`, `settings.local.json`, `.credentials*`, and `projects/` stay on the local machine.

</essential_principles>

<intake>
**devkit-sync triggered.** What sync operation do you need?

1. **Status** -- Show symlink health, git status, drift report
2. **Push** -- Commit and push local DevKit changes, create/update PR
3. **Pull** -- Fetch and pull latest from DevKit main
4. **Init** -- Set up symlinks and machine identity (first-time setup)
5. **Diff** -- Show detailed diff of local changes vs DevKit main
6. **Unlink** -- Replace symlinks with copies (portable snapshot)
7. **Resolve conflicts** -- Fix merge conflicts after pull/rebase
8. **Promote** -- Promote local patterns/gotchas to universal rules files
9. **Update** -- Check version and upgrade to a specific release or latest
10. **Verify** -- Check if DevKit updates reached all active projects
11. **New project** -- Scaffold a new project with DevKit templates and profile
12. **Audit settings** -- Check for redundant permissions in settings.json

Type a number, keyword, or **skip** to dismiss.

> Note: This skill blocks on user input. If triggered unintentionally,
> type **skip** or **dismiss** to cancel.
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "sync status", "symlink health", "drift report" | workflows/status.md |
| 2, "sync push", "push changes", "commit and push" | workflows/push.md |
| 3, "sync pull", "pull latest", "fetch devkit" | workflows/pull.md |
| 4, "sync init", "setup symlinks", "first-time setup" | workflows/init.md |
| 5, "sync diff", "show diff", "what changed" | workflows/diff.md |
| 6, "unlink", "portable snapshot", "replace symlinks" | workflows/unlink.md |
| 7, "resolve conflicts", "merge conflict", "rebase conflict" | workflows/resolve-conflicts.md |
| 8, "promote rules", "graduate", "local to universal" | workflows/promote.md |
| 9, "devkit update", "devkit upgrade", "check version" | workflows/update.md |
| 10, "verify propagation", "check projects", "verify reach" | workflows/verify.md |
| 11, "new project", "scaffold project", "create project" | workflows/new-project.md |
| 12, "audit settings", "settings cleanup", "redundant permissions" | workflows/audit-settings.md |

If the user types **skip** or **dismiss**, briefly confirm cancellation (e.g., "devkit-sync cancelled.") and end the skill without running any workflow.

If the input does not clearly match any option above and is not "skip" or "dismiss", respond:
"devkit-sync was triggered but your input didn't match a workflow. Options: 1-12 (listed above). Type **skip** to dismiss."

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>

- Bash (git commands, sync.ps1 invocation)
- Read, Edit, Write (for config files)
- Glob, Grep (for file discovery)
</tool_restrictions>
