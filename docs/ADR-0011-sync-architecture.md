# ADR-0011: DevKit Synchronization Architecture

## Status

Accepted

## Date

2026-02-25

## Context

DevKit stores Claude Code configuration (rules, skills, agents, hooks) in a git-tracked repository. These files must live at `~/.claude/` for Claude Code to load them. The original approach used copy-based installation: `setup.sh` copied files from the DevKit clone to `~/.claude/`, and manual `cp` commands copied them back when patterns accumulated during sessions.

This created a **drift problem** on multiple levels:

- **Invisible edits**: Changes to `~/.claude/rules/autolearn-patterns.md` during a session (via `/reflect` or manual edits) were invisible to `git diff` in the DevKit clone. The user had to remember to copy files back.
- **Multi-machine divergence**: On two machines, each accumulates its own patterns and gotchas independently. There was no mechanism to merge learnings from machine A into machine B.
- **Manual sync tax**: The "Updating" section of the README described a manual `cp` workflow that was easy to forget, especially at the end of a productive session when new patterns were fresh.

The result was that patterns discovered on one machine never reached the other, and the DevKit repository was perpetually behind the working configuration.

## Decision

Replace copy-based installation with **symlinks** and **automatic git push/pull via hooks and skills**.

### Symlink model

`sync.ps1 -Link` creates symbolic links from `~/.claude/` back to the DevKit clone:

```text
~/.claude/rules/autolearn-patterns.md  ->  devkit/claude/rules/autolearn-patterns.md
~/.claude/skills/autolearn/            ->  devkit/claude/skills/autolearn/
~/.claude/hooks/SessionStart.sh        ->  devkit/claude/hooks/SessionStart.sh
```

Editing `~/.claude/rules/foo.md` now edits the file inside the DevKit clone. `git diff` in the clone shows changes instantly. No copy-back step is needed.

### Split-file pattern

Files follow a shared + local convention:

- `foo.md` (shared, symlinked, git-tracked)
- `foo.local.md` (local-only, real file, gitignored)

Claude Code loads all `*.md` from `~/.claude/rules/` automatically. The local file adds machine-specific patterns, credentials references, or environment gotchas without modifying shared files. The `.sync-manifest.json` defines which paths are shared and which patterns are local-only.

### Multi-machine sync strategy

1. Each machine has a `.machine-id` file (e.g., `desktop-main`, `laptop-dev`) generated during `sync.ps1 -Link`
2. The `/devkit-sync push` skill commits changes and pushes to a `sync/<machine-id>` branch
3. Pull requests are the merge point -- changes from each machine are reviewed before merging to main
4. The `SessionStart.sh` hook auto-pulls main on every new Claude Code session (with a 5-second network timeout to avoid blocking)
5. The `/reflect` and session review workflows check for uncommitted DevKit changes and prompt the user to run `/devkit-sync push`

### Automatic triggers

| Trigger | Action | Mechanism |
|---------|--------|-----------|
| Session start | Pull latest from main | `SessionStart.sh` hook |
| `/reflect` or session review | Prompt to push if dirty | Workflow step 6 in `quick-reflect.md` |
| `/devkit-sync push` | Commit, push to sync branch, create PR | Skill workflow |
| `/devkit-sync pull` | Fetch and merge main | Skill workflow |

## Alternatives Considered

### Git-tracked `~/.claude/` directory

Make `~/.claude/` itself a git repository (or a subdirectory of one).

**Rejected because:**

- Claude Code manages `~/.claude/settings.local.json`, `~/.claude/projects/`, and other state files. A git repo at `~/.claude/` would need extensive `.gitignore` rules and would conflict with Claude Code's own file management.
- Pollutes the user's home directory with a `.git/` folder at a path they didn't choose.
- Every Claude Code update could introduce new files in `~/.claude/` that need gitignore entries.

### chezmoi

Use [chezmoi](https://www.chezmoi.io/) to manage dotfiles, including `~/.claude/`.

**Rejected because:**

- External dependency that must be installed before DevKit can function -- a bootstrapping problem.
- Chezmoi's templating system (Go templates) is overkill for a flat file set with no per-machine variable substitution.
- Adds a layer of indirection: edits go to the chezmoi source directory, then `chezmoi apply` copies them. This is the same copy problem in different clothes.
- Learning curve for a tool that solves a broader problem than needed here.

### Git submodules

Make `~/.claude/` a git submodule pointing to the DevKit repository (or a subset of it).

**Rejected because:**

- Submodule inside `~/.claude/` creates nesting issues with Claude Code's own expectations for that directory.
- The update workflow (`git submodule update --remote`) is clunky and easy to forget.
- Submodule pointers are fragile -- detached HEAD states are common and confusing.
- Does not solve the split between shared and local-only files cleanly.

### Separate config repository

Keep DevKit as a methodology/docs repo and create a second `claude-config` repo for the actual `~/.claude/` contents.

**Rejected because:**

- Rules reference skills, hooks reference config, and the CLAUDE.md references all of them. Splitting context that belongs together forces cross-repo coordination.
- Two repos means two git workflows, two CI pipelines, and two things to keep in sync.
- The DevKit repo is already organized to serve both purposes (portable config + methodology).

## Consequences

### Positive

- **Zero-effort sync**: Edits to `~/.claude/` are immediately visible in `git diff` inside the DevKit clone. No copy step required.
- **Multi-machine convergence**: Each machine pushes to its own branch; PRs are the review and merge point. Learnings flow from any machine to all machines.
- **Session continuity**: `SessionStart.sh` auto-pulls, so a session on machine B sees patterns discovered on machine A (after merge).
- **Backup on link**: Pre-existing files in `~/.claude/` are backed up to `~/.claude/.backup/<timestamp>/` before symlinks are created. No data is lost during the transition.
- **Graceful degradation**: `sync.ps1 -Unlink` replaces all symlinks with real copies, producing a portable snapshot that works without the DevKit clone.

### Negative

- **Windows symlink requirement**: Creating symbolic links on Windows requires either Developer Mode enabled or administrator privileges. `sync.ps1` falls back to directory junctions for skill directories, but file symlinks have no fallback. This is documented in the init workflow and reported clearly on failure.
- **Single-repo bottleneck**: All machines push to the same DevKit repo. If two machines make conflicting edits to the same rule entry, the PR merge requires manual conflict resolution. In practice this is rare because most edits are append-only (new patterns/gotchas).
- **Network dependency for auto-pull**: `SessionStart.sh` requires network access to fetch updates. The 5-second timeout prevents blocking, but offline sessions start without the latest changes.
- **Append-only file growth**: `autolearn-patterns.md` and `known-gotchas.md` grow monotonically. The `.sync-manifest.json` marks them as `append_only_files` to signal that entries should not be removed during sync, but periodic curation is still manual.
