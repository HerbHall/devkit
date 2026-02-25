# DevKit Sync: Diff

Show detailed diff of local DevKit changes vs origin/main.

## Steps

1. **Resolve DevKit path** from config or common locations.

2. **Fetch latest** (so diff is against current remote state):

   ```bash
   git -C <devkit> fetch origin 2>/dev/null
   ```

3. **Show uncommitted changes:**

   ```bash
   git -C <devkit> diff
   git -C <devkit> diff --cached  # staged changes
   ```

4. **Show unpushed commits** (if on a sync branch):

   ```bash
   git -C <devkit> log --oneline origin/main..HEAD
   ```

5. **Show incoming changes** (commits on main not yet pulled):

   ```bash
   git -C <devkit> log --oneline HEAD..origin/main
   ```

6. **Present a summary:**

   ```text
   DevKit Diff
     Uncommitted: N file(s) modified
     Unpushed:    N commit(s) on current branch
     Incoming:    N commit(s) on origin/main
   ```

   Follow with the actual diff content for uncommitted changes.
