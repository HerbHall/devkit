---
name: devkit-sync
description: Manual sync operations for DevKit multi-machine synchronization. Status, push, pull, init, diff, unlink, promote, and update.
user_invocable: true
---

# DevKit Sync

Manual control for DevKit multi-machine synchronization. While auto-pull (SessionStart) and auto-push (/reflect) handle routine sync, this skill provides manual operations for setup, forced sync, conflict resolution, and portable snapshots.

<essential_principles>

**DevKit sync uses symlinks, not copies.** Files in `~/.claude/` are symlinks pointing to the DevKit clone. Editing `~/.claude/rules/foo.md` actually edits `devkit/claude/rules/foo.md`, and `git diff` in the DevKit clone shows changes instantly.

**Machine identity matters.** Each machine has a `.machine-id` used in sync branch names (`sync/<machine-id>`) and commit messages. This prevents cross-machine conflicts.

**Local files are never synced.** Files matching `*.local.md`, `settings.local.json`, `.credentials*`, and `projects/` stay on the local machine.

</essential_principles>

<intake>
What sync operation do you need?

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

Or just type your question about DevKit sync.
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "status", "state", "health", "check" | workflows/status.md |
| 2, "push", "commit", "upload", "share" | workflows/push.md |
| 3, "pull", "fetch", "download" | workflows/pull.md |
| 4, "init", "setup", "install", "link" | workflows/init.md |
| 5, "diff", "changes", "what changed" | workflows/diff.md |
| 6, "unlink", "copy", "snapshot", "portable" | workflows/unlink.md |
| 7, "resolve", "conflicts", "conflict", "merge conflict", "rebase conflict" | workflows/resolve-conflicts.md |
| 8, "promote", "graduate", "elevate", "local to universal" | workflows/promote.md |
| 9, "update", "upgrade", "version", "release" | workflows/update.md |
| 10, "verify", "propagation", "check projects", "reach" | workflows/verify.md |

**After reading the workflow, follow it exactly.**
</routing>

<tool_restrictions>

- Bash (git commands, sync.ps1 invocation)
- Read, Edit, Write (for config files)
- Glob, Grep (for file discovery)
</tool_restrictions>
