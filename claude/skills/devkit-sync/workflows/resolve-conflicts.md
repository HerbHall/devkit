# DevKit Sync: Resolve Conflicts

Guide the user through resolving conflicts after `git pull --rebase` fails on the DevKit clone.

## Detect Conflict Type

1. **Check rebase status:**

   ```bash
   git -C <devkit> status
   ```

   If output shows "rebase in progress", a pull has already failed. If not, the user may be running this proactively after seeing conflicts in `-Status` output.

2. **Identify conflicted files:**

   ```bash
   git -C <devkit> diff --name-only --diff-filter=U
   ```

3. **Classify each file** by checking `.sync-manifest.json`:
   - If the file is in `append_only_files` (e.g., `autolearn-patterns.md`, `known-gotchas.md`): use the **Append-Only Resolution** flow
   - Otherwise: use the **Whole-File Resolution** flow

## Append-Only Resolution

These files are numbered entry lists. Two machines may add entries with the same number, causing merge conflicts on the entry headers.

1. **Accept the incoming (remote) version as the base:**

   ```bash
   git -C <devkit> checkout --theirs <file>
   ```

2. **Find the highest entry number in the accepted version:**

   ```bash
   grep -oP '^## \K\d+' <devkit>/<file> | sort -n | tail -1
   ```

   For files using `**N.**` pattern instead of `## N`:

   ```bash
   grep -oP '^\*\*\K\d+' <devkit>/<file> | sort -n | tail -1
   ```

3. **Retrieve the local machine's new entries from the conflict backup:**

   ```bash
   git -C <devkit> show REBASE_HEAD:<file> > /tmp/local-version.md
   ```

   Diff against the common ancestor to isolate only new entries:

   ```bash
   git -C <devkit> diff REBASE_HEAD~1..REBASE_HEAD -- <file>
   ```

4. **Renumber the local entries** starting from `highest + 1` and append them to the file.

5. **Stage and continue:**

   ```bash
   git -C <devkit> add <file>
   git -C <devkit> rebase --continue
   ```

## Whole-File Resolution

For skills, agents, config files, and other non-append content.

1. **Show both versions side-by-side:**

   ```bash
   # Remote (incoming) version
   git -C <devkit> show origin/main:<file>

   # Local (current) version
   git -C <devkit> show REBASE_HEAD:<file>

   # Unified diff
   git -C <devkit> diff
   ```

2. **Ask the user to choose:**
   - **Keep remote:** `git -C <devkit> checkout --theirs <file>`
   - **Keep local:** `git -C <devkit> checkout --ours <file>`
   - **Manual merge:** User edits the file to combine both changes

3. **Stage and continue:**

   ```bash
   git -C <devkit> add <file>
   git -C <devkit> rebase --continue
   ```

## Branch Strategy

Each machine pushes to its own sync branch to avoid direct conflicts on main.

- **Branch naming:** `sync/<machine-id>` (read from `~/.claude/.machine-id`)
- **Workflow:**
  1. Machine A pushes to `sync/machine-a`, opens PR to main
  2. Machine B pushes to `sync/machine-b`, opens PR to main
  3. User reviews and merges one PR at a time on GitHub
  4. After merging Machine A's PR, Machine B runs `/devkit-sync pull` to rebase onto updated main
  5. If rebase conflicts occur, Machine B runs `/devkit-sync resolve-conflicts`
  6. Machine B force-pushes its updated branch: `git push --force-with-lease origin sync/machine-b`

## Aborting

If resolution gets too complex, abort and start fresh:

```bash
git -C <devkit> rebase --abort
```

Then manually inspect both versions and cherry-pick changes.

## Edge Cases

- **Multiple conflicted commits:** Rebase may pause at each commit. Repeat the resolution flow for each stop.
- **No rebase in progress:** User ran this proactively. Show the `-Status` conflict detection output and suggest running pull first.
- **Network unavailable:** Cannot fetch remote. Show local changes only and suggest trying again when online.
