# DevKit Sync: Unlink

Replace symlinks with copies for a portable snapshot of `~/.claude/`.

## Steps

1. **Confirm with user**: "This will replace all symlinks in ~/.claude/ with real file copies. The files will no longer track DevKit changes. Continue?"

2. **Run sync.ps1 -Unlink:**

   ```bash
   pwsh -NoProfile -File <devkit>/setup/sync.ps1 -Unlink
   ```

   If PowerShell is not available, do it manually:

   ```bash
   # For each symlink, replace with a copy of its target
   find ~/.claude/rules -type l -exec sh -c '
       target=$(readlink "$1")
       rm "$1"
       cp "$target" "$1"
   ' _ {} \;
   ```

3. **Verify** no symlinks remain:

   ```bash
   find ~/.claude -type l
   ```

4. **Report**: "Converted N symlinks to copies. ~/.claude/ is now a standalone snapshot. To re-enable sync, run `/devkit-sync init`."

## When to Use

- Before reformatting or reinstalling the OS
- When moving to a machine without DevKit access
- For creating a backup snapshot
- When you want to diverge from shared config temporarily
