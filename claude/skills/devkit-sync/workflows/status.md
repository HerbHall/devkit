# DevKit Sync: Status

Show current sync state including symlink health, git status, and drift report.

## Steps

1. **Resolve DevKit path** from `~/.devkit-config.json` or common locations (`D:/DevSpace/devkit`, `~/DevSpace/devkit`)

2. **Run sync status check:**

   ```bash
   pwsh -NoProfile -File <devkit>/setup/sync.ps1 -Status
   ```

   If PowerShell is not available, gather status manually:

   ```bash
   # Machine ID
   cat ~/.claude/.machine-id 2>/dev/null || echo "Not set"

   # Git status
   git -C <devkit> status --short
   git -C <devkit> rev-list --left-right --count HEAD...origin/main

   # Symlink count
   find ~/.claude/rules -maxdepth 1 -type l | wc -l
   find ~/.claude/skills -maxdepth 1 -type l | wc -l
   find ~/.claude/agents -maxdepth 1 -type l | wc -l
   ```

3. **Display formatted status:**

   ```text
   DevKit Sync Status
     Clone:    <path> (clean / dirty / N uncommitted files)
     Branch:   main (up to date / N behind / N ahead)
     Machine:  <machine-id>
     Symlinks: N/N valid (or X broken, Y missing)
     Local:    N *.local.md files
   ```

4. **Flag issues** if any symlinks are broken, missing, or are real files instead of symlinks.
