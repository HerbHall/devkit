# DevKit Sync: Init

First-time setup: clone DevKit if needed, create symlinks, generate machine ID.

## Steps

1. **Check if DevKit clone exists:**

   ```bash
   # Check common locations
   ls -d ~/DevSpace/devkit /d/DevSpace/devkit ~/workspace/devkit 2>/dev/null
   ```

   If not found, clone it:

   ```bash
   gh repo clone HerbHall/devkit <devspace>/devkit
   ```

2. **Run sync.ps1 -Link:**

   ```bash
   pwsh -NoProfile -File <devkit>/setup/sync.ps1 -Link -DevKitPath <devkit>
   ```

   This will:
   - Back up existing real files in `~/.claude/`
   - Create symlinks for all shared files
   - Prompt for machine identity

   If PowerShell is not available, create symlinks manually:

   ```bash
   # Example for rules
   for f in <devkit>/claude/rules/*.md; do
       name=$(basename "$f")
       ln -sf "$f" ~/.claude/rules/"$name"
   done
   ```

3. **Verify setup:**

   ```bash
   pwsh -NoProfile -File <devkit>/setup/sync.ps1 -Verify
   ```

4. **Report** the setup summary: linked files count, machine ID, backup location if any.

## Edge Cases

- `~/.claude/` doesn't exist: create it first
- Symlinks not supported (no Developer Mode on Windows): report error, suggest enabling
- DevKit clone is on a different drive: use `-DevKitPath` to specify
