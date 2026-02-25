# DevKit Sync: Update

Check current version and upgrade to a specific release or latest.

## Steps

1. **Resolve DevKit path** from config or common locations.

2. **Read current version:**

   ```bash
   cat <devkit>/VERSION
   ```

   Report: "Current version: X.Y.Z"

3. **Fetch latest tags from origin:**

   ```bash
   git -C <devkit> fetch origin --tags
   ```

4. **Show available versions** (most recent first):

   ```bash
   git -C <devkit> tag -l "v*" --sort=-v:refname | head -5
   ```

   If no tags exist: "No tagged releases found. Use `/devkit-sync pull` to track main HEAD."

5. **Determine target version:**
   - If user said `--latest` or "latest": target is `main` HEAD
   - If user specified a version (e.g., `v2.0.0`): target is that tag
   - Otherwise: target is the newest tag from step 4

6. **Check for local changes** that would block checkout:

   ```bash
   git -C <devkit> status --porcelain
   ```

   If dirty: warn and offer to stash first.

7. **Apply the update:**
   - For a tag target:

     ```bash
     git -C <devkit> checkout <tag>
     ```

   - For latest (main HEAD):

     ```bash
     git -C <devkit> pull --rebase origin main
     ```

8. **Confirm version change:**

   ```bash
   cat <devkit>/VERSION
   ```

   Report: "Updated from X.Y.Z to A.B.C. Symlinked files updated instantly."

## Edge Cases

- Network unavailable: report fetch failure, show current version
- No VERSION file: report "VERSION file not found -- this DevKit predates version tagging"
- Target tag not found: list available tags, ask user to pick one
- Dirty working tree: offer stash/unstash flow
