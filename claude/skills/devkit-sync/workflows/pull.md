# DevKit Sync: Pull

Fetch and pull latest DevKit updates from main.

## Steps

1. **Resolve DevKit path** from config or common locations.

2. **Check for local changes** that would block a pull:

   ```bash
   git -C <devkit> status --porcelain
   ```

   If dirty: warn the user and offer to stash changes first.

3. **Fetch and pull:**

   ```bash
   git -C <devkit> fetch origin
   git -C <devkit> pull --rebase origin main
   ```

4. **Report result:**
   - Success: "Pulled N new commit(s). Symlinked files updated instantly."
   - Already up to date: "DevKit is up to date with origin/main."
   - Conflict: "Rebase conflict detected. Resolve manually in `<devkit>` or run `git -C <devkit> rebase --abort`."

5. **If stashed in step 2**, pop the stash:

   ```bash
   git -C <devkit> stash pop
   ```

## Edge Cases

- Network unavailable: report fetch failure
- Rebase conflict: show conflicted files, suggest resolution steps
- Dirty working tree: offer stash/unstash flow
