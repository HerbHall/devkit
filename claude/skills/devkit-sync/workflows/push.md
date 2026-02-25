# DevKit Sync: Push

Commit and push local DevKit changes, create or update a PR.

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

6. **Create or update PR:**

   ```bash
   # Check if PR already exists
   gh pr list -R HerbHall/devkit --head sync/<machine-id> --json number,url

   # If no PR exists, create one
   gh pr create -R HerbHall/devkit \
     --head sync/<machine-id> \
     --title "chore(sync): <machine-id> learnings" \
     --body "Auto-synced DevKit changes from <machine-id>."
   ```

   If PR already exists, the push updates it automatically.

7. **Report** the PR URL to the user.

## Edge Cases

- No `.machine-id`: prompt user to run `/devkit-sync init` first
- Push fails (auth/network): report error, suggest manual resolution
- Conflicting remote changes: suggest `/devkit-sync pull` first
