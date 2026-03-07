# DevKit Sync: Push

Commit and push local DevKit changes, then automatically create or update a PR. No separate human instruction is needed for PR creation -- it happens as part of the push flow.

## Prerequisites

Source the forge abstraction wrappers before running any forge commands:

```bash
source "$(git -C <devkit> rev-parse --show-toplevel)/scripts/forge-wrappers.sh"
```

## Steps

1. **Resolve DevKit path** and read machine ID from `~/.claude/.machine-id`

2. **Check for changes:**

   ```bash
   git -C <devkit> status --porcelain
   ```

   If no changes: report "No DevKit changes to push" and stop.

3. **Show what changed:**

   ```bash
   git -C <devkit> diff --stat
   ```

   Present the list to the user and confirm they want to push.

4. **Commit changes:**

   ```bash
   git -C <devkit> add claude/
   git -C <devkit> commit -m "chore(sync): <machine-id> session learnings $(date +%Y-%m-%d)"
   ```

   Include `Co-Authored-By: Claude <noreply@anthropic.com>` in the commit.

5. **Push to sync branch:**

   ```bash
   git -C <devkit> push -u origin sync/<machine-id>
   ```

   If the branch doesn't exist remotely, this creates it.

6. **Create or update PR (automatic -- no confirmation needed):**

   ```bash
   # Check if PR already exists for this branch
   devkit-pr-list --head sync/<machine-id> --json number,url

   # If no PR exists, create one with issue references
   devkit-pr-create \
     --title "chore(sync): <machine-id> learnings" \
     --body "Auto-synced DevKit changes from <machine-id>." \
     --head "sync/<machine-id>"
   ```

   If PR already exists, the push updates it automatically -- skip creation.

   For feature branches (not sync branches), derive the PR title from the conventional commit on HEAD and add `Closes #NNN` references extracted from the branch name (e.g., `feature/issue-42-foo` yields `Closes #42`).

7. **Report** the PR URL to the user. CI and Copilot auto-review take it from here.

## Edge Cases

- No `.machine-id`: prompt user to run `/devkit-sync init` first
- Push fails (auth/network): report error, suggest manual resolution
- Conflicting remote changes: suggest `/devkit-sync pull` first
- Forge wrappers not found: fall back to `gh` directly with a warning
