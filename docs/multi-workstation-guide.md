# Multi-Workstation Setup Guide

How to run DevKit on multiple machines and keep them in sync. This guide covers first-time setup, adding new workstations, daily workflow, cross-platform considerations, and troubleshooting.

## Prerequisites

Install these on every machine before starting.

**Required on all platforms:**

- [Git](https://git-scm.com/) 2.39+ (for `init.templateDir` and modern diff features)
- [PowerShell 7](https://github.com/PowerShell/PowerShell/releases) (`pwsh`) -- setup scripts require it
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) -- the CLI that loads DevKit config
- [GitHub CLI](https://cli.github.com/) (`gh`) -- for sync branch PRs and issue management

**OS-specific requirements:**

| OS | Extra Requirement | Why |
|----|------------------|-----|
| Windows | Developer Mode enabled | Symlink creation without admin. Settings > System > For developers > Developer Mode |
| Linux | `$XDG_CONFIG_HOME` awareness | Claude config may live at `~/.config/claude/` instead of `~/.claude/` |
| macOS | None | Symlinks and `~/.claude/` work out of the box |

**Verify prerequisites:**

```bash
git --version       # 2.39+
pwsh --version      # 7.0+
claude --version    # any
gh auth status      # must show "Logged in"
```

## First Workstation Setup

### Step 1: Clone DevKit

Clone into your workspace root directory. All DevKit paths are relative to this location.

```bash
# Choose your workspace root (examples)
# Windows: ~/DevSpace, Linux/macOS: ~/workspace
cd "$HOME/DevSpace"  # or wherever your projects live
git clone https://github.com/HerbHall/devkit.git
```

### Step 2: Create symlinks

The sync script creates symbolic links from `~/.claude/` to the DevKit clone. Edits in either location are the same file -- no copy drift.

```bash
pwsh -NoProfile -File devkit/setup/sync.ps1 -Link
```

This will:

1. Back up any existing files in `~/.claude/` to `~/.claude/.backup/<timestamp>/`
2. Create symlinks for all shared files (rules, skills, agents, hooks)
3. Prompt you for a **machine ID** (derived from hostname, e.g., `desktop-main`)

The machine ID is stored at `~/.claude/.machine-id` and used in sync branch names.

### Step 3: Configure machine identity

Create `~/.devkit-config.json` with your machine-specific settings:

```json
{
  "version": 2,
  "machineId": "desktop-main",
  "devspacePath": "/home/you/workspace",
  "claudeHome": "/home/you/.claude",
  "os": "linux",
  "forge": {
    "primary": "github",
    "giteaUrl": null
  },
  "installedProfiles": [],
  "lastSync": null
}
```

Adjust the values for your machine:

| Field | Windows example | Linux example | macOS example |
|-------|----------------|---------------|---------------|
| `devspacePath` | `D:\\DevSpace` | `$HOME/workspace` | `$HOME/workspace` |
| `claudeHome` | `C:\\Users\\you\\.claude` | `$HOME/.config/claude` (XDG) or `$HOME/.claude` | `$HOME/.claude` |
| `os` | `windows` | `linux` | `darwin` |

### Step 4: Verify

Run the full verification check:

```bash
pwsh -NoProfile -File devkit/setup/sync.ps1 -Verify
```

Expected output shows all shared files correctly symlinked and the machine ID set. Then start a Claude Code session anywhere to confirm:

- SessionStart hook fires and reports "DevKit: up to date" (or pulls new commits)
- Rules load (check with a prompt that triggers a known pattern)
- Skills appear (type `/devkit-sync` to see the skill menu)

## Additional Workstation Setup

Setting up a second (or third, or fourth) machine follows the same steps with one key difference: choose a **unique machine ID**.

### Step 1: Clone and link

```bash
cd "$HOME/workspace"
git clone https://github.com/HerbHall/devkit.git
pwsh -NoProfile -File devkit/setup/sync.ps1 -Link
```

When prompted for the machine ID, choose something descriptive and unique:

- `laptop-dev` -- a development laptop
- `server-lab` -- a headless lab server
- `desktop-work` -- a work desktop

### Step 2: Configure and verify

Create `~/.devkit-config.json` with this machine's paths and OS. Then verify:

```bash
pwsh -NoProfile -File devkit/setup/sync.ps1 -Verify
```

### Step 3: Confirm auto-pull works

Start a Claude Code session. The SessionStart hook should:

1. Locate the DevKit clone (via `~/.devkit-config.json` or common paths)
2. Fetch from origin (5-second timeout, fails silently if offline)
3. Pull any new commits from main

Check the pull log at `~/.claude/.devkit-pull.log` for recent activity.

## Daily Workflow

Once multiple machines are set up, the sync cycle looks like this:

```text
                    GitHub (main branch)
                   /         |         \
                  /          |          \
     auto-pull  /   merge PR |           \  auto-pull
               /             |            \
              v              |             v
  +------------------+      |      +------------------+
  |   Machine A      |      |      |   Machine B      |
  |   (desktop-main) |      |      |   (laptop-dev)   |
  +------------------+      |      +------------------+
              |              |             |
   /devkit-sync push        |    /devkit-sync push
              |              |             |
              v              |             v
     sync/desktop-main ------+------ sync/laptop-dev
          (PR to main)                (PR to main)
```

### Auto-pull on session start

Every time you open a Claude Code session, `SessionStart.sh` runs automatically:

1. Checks if the last pull was less than 1 hour ago (rate-limited to avoid network spam)
2. Skips if the working tree has uncommitted changes
3. Skips if a git lock file is present
4. Fetches with a 5-second timeout
5. Pulls with `--rebase` if there are new commits on main

You do not need to do anything -- this happens silently in the background.

### Capture patterns with /reflect

During a session, when you learn something new (a gotcha, a pattern, a fix), run `/reflect`. This appends the learning to the appropriate rules file in `~/.claude/rules/`. Because of symlinks, the edit lands directly in your DevKit clone.

### Push changes with /devkit-sync push

When you have accumulated changes (new patterns, updated skills, config tweaks):

1. Run `/devkit-sync push` in any Claude Code session
2. The skill commits changes to `claude/` in the DevKit clone
3. Pushes to a `sync/<machine-id>` branch (e.g., `sync/desktop-main`)
4. Creates a PR to main (or updates an existing one)

### Merge PRs on GitHub

Review and merge each machine's sync PR on GitHub. Squash-merge is recommended to keep main clean.

### Other machines auto-pull

On the next session start, other machines pull the merged changes from main. The cycle repeats.

### Manual sync commands

| Command | When to use |
|---------|------------|
| `/devkit-sync status` | Check symlink health, git status, potential conflicts |
| `/devkit-sync push` | Commit and push local changes to sync branch |
| `/devkit-sync pull` | Force a pull outside the auto-pull interval |
| `/devkit-sync diff` | See detailed diff of local changes vs main |
| `/devkit-sync resolve-conflicts` | Fix merge conflicts after pull/rebase |
| `/devkit-sync promote` | Move local patterns from `*.local.md` to universal rules |

## Cross-Platform Notes

### Windows

**Developer Mode** is required for symlinks. Without it, `sync.ps1 -Link` falls back to directory junctions (for skill directories) and hard links (for individual files). Junctions work well but hard links lose the "edit either location" property for some operations.

Enable Developer Mode: Settings > System > For developers > Developer Mode toggle.

**MSYS path translation**: Git Bash on Windows translates paths automatically (`/c/Users/you` maps to `C:\Users\you`). The SessionStart hook handles this with `sed 's|\\\\|/|g'` when reading `devspacePath` from config.

**Symlink verification on Windows:**

```powershell
# Check if a file is a symlink
(Get-Item ~/.claude/CLAUDE.md -Force).Attributes -band [IO.FileAttributes]::ReparsePoint
```

### Linux

**Claude config path**: Claude Code on Linux may use `$XDG_CONFIG_HOME/claude/` instead of `~/.claude/`. If `$XDG_CONFIG_HOME` is set (common on modern distros), the config directory defaults to `~/.config/claude/`.

Set the correct path in `~/.devkit-config.json`:

```json
{
  "claudeHome": "/home/you/.config/claude"
}
```

The `sync.ps1` script reads `claudeHome` from config and uses it instead of assuming `~/.claude/`.

**Symlink creation**: No special permissions needed. `ln -s` works for any unprivileged user.

### macOS

Claude config lives at `~/.claude/` (same as Windows default). No special permissions needed for symlinks.

**Homebrew installs**: If PowerShell 7 is installed via Homebrew, the binary is `pwsh` (same as all platforms):

```bash
brew install powershell
pwsh -NoProfile -File devkit/setup/sync.ps1 -Link
```

## Multi-Forge Setup

DevKit defaults to GitHub (`gh` CLI). If you also use a self-hosted Gitea instance, configure forge detection.

### GitHub only (default)

No configuration needed. The `gh` CLI handles everything. Forge detection parses `git remote get-url origin` and recognizes `github.com` automatically.

### Adding Gitea as a secondary forge

1. Install the `tea` CLI from [Gitea releases](https://gitea.com/gitea/tea/releases)

2. Authenticate with your Gitea instance:

   ```bash
   tea login add --name my-gitea --url https://git.example.com --token YOUR_TOKEN
   ```

3. Set the Gitea URL in `~/.devkit-config.json`:

   ```json
   {
     "forge": {
       "primary": "github",
       "giteaUrl": "https://git.example.com"
     }
   }
   ```

4. Forge detection is automatic per-repository. When you run a DevKit skill inside a Gitea-hosted project, the forge wrapper functions detect the remote URL and use `tea` instead of `gh`.

### How forge detection works

The `devkit-forge-detect` function in `claude-functions.sh` inspects the current repository's origin URL:

- URLs containing `github.com` route to `gh`
- All other URLs route to `tea`
- The `forge.primary` field in config can override auto-detection

Not all `gh` features have `tea` equivalents. PR status checks (`gh pr checks`) are skipped for Gitea repos since `tea` does not support them.

## Troubleshooting

### Symlink permission denied (Windows)

**Symptom**: `sync.ps1 -Link` fails with "A required privilege is not held by the client."

**Cause**: Developer Mode is not enabled and the current user is not an administrator.

**Fix**: Enable Developer Mode (Settings > System > For developers) or run PowerShell as Administrator. After enabling, re-run:

```powershell
pwsh -NoProfile -File devkit/setup/sync.ps1 -Link
```

If Developer Mode cannot be enabled (corporate policy), the script falls back to junctions and hard links. Run `/devkit-sync status` to check which fallback was used.

### SessionStart pull failures

**Symptom**: Claude Code session starts but no "DevKit: pulled N commit(s)" message appears.

**Possible causes and fixes:**

| Cause | Diagnosis | Fix |
|-------|-----------|-----|
| Rate limited | Pull log shows `UP_TO_DATE` recently | Wait 1 hour or delete `~/.claude/.devkit-last-pull` |
| Dirty working tree | `git -C <devkit> status` shows changes | Commit or stash changes, or run `/devkit-sync push` |
| Git lock file | `.git/index.lock` exists | Delete the lock file: `rm <devkit>/.git/index.lock` |
| Network timeout | Pull log shows `SKIPPED_OFFLINE` | Check internet connection |
| DevKit not found | No output at all | Create `~/.devkit-config.json` with correct `devspacePath` |

Check the pull log:

```bash
cat ~/.claude/.devkit-pull.log
```

### Merge conflicts between machines

**Symptom**: `/devkit-sync pull` fails with rebase conflicts.

**Cause**: Two machines edited the same file. Most common with `autolearn-patterns.md` and `known-gotchas.md` (append-only files where both machines added new entries).

**Fix**: Run `/devkit-sync resolve-conflicts`. The skill will:

1. Identify conflicted files
2. For append-only files: accept remote version, renumber local entries, append them
3. For other files: show both versions and ask you to choose

If conflicts are too complex, abort and start fresh:

```bash
git -C <devkit-path> rebase --abort
```

Then manually inspect both versions with `/devkit-sync diff`.

**Prevention**: Merge sync PRs promptly. The longer two machines diverge, the higher the conflict risk. Merging one PR at a time with a pull in between keeps the delta small.

### .local.md files not loading

**Symptom**: Machine-specific patterns in `~/.claude/rules/my-machine.local.md` are not picked up by Claude Code.

**Possible causes:**

- File is not in `~/.claude/rules/` (it must be there, not in the DevKit clone)
- File does not end with `.md` (Claude Code only loads `*.md` from rules)
- File is a symlink pointing to a DevKit path (local files must be real files, not symlinks)

**Verify:**

```bash
ls -la ~/.claude/rules/*.local.md
# Should show real files (no -> arrow indicating symlink)
```

### Git lock file issues

**Symptom**: "DevKit: pull skipped -- git lock file present" on every session start.

**Cause**: A previous git operation crashed or was interrupted, leaving `<devkit>/.git/index.lock`.

**Fix:**

```bash
# Verify no git operation is actually running
ps aux | grep git  # Linux/macOS
# or
tasklist | findstr git  # Windows

# Remove the stale lock
rm <devkit-path>/.git/index.lock
```

### Symlinks show as modified in git status

**Symptom**: `git status` in the DevKit clone shows symlinked files as modified even though you did not change them.

**Cause**: Line ending differences. Git on Windows may convert LF to CRLF when checking out, but the symlink target has the original LF endings.

**Fix**: Configure git to not convert line endings for the DevKit repo:

```bash
cd <devkit-path>
git config core.autocrlf input
```

Or add a `.gitattributes` file (already present in DevKit) that enforces LF for all text files.

## FAQ

### What happens when two machines edit the same rule

Both machines edit the file through their symlinks. When each pushes to its own `sync/<machine-id>` branch and creates a PR, GitHub shows the diff for each. Merge one PR first, then the other machine pulls, rebases, and resolves any conflicts (usually just renumbering entries in append-only files). See [Merge conflicts between machines](#merge-conflicts-between-machines) above.

### Can I use DevKit without PowerShell

Partially. The **SessionStart hook** and **shell functions** are bash and work without PowerShell. Skills and rules are plain markdown files that Claude Code loads natively. However, the **sync script** (`sync.ps1`) requires PowerShell 7 for symlink creation and verification.

Alternatives without PowerShell:

- **Manual symlinks**: Create them with `ln -s` on Linux/macOS (see the init workflow for the loop pattern)
- **Copy mode**: Use `bash setup/legacy/setup.sh` to copy files instead of symlinking (loses live-edit sync)
- **Manual git operations**: Push/pull the DevKit clone with standard git commands instead of `/devkit-sync`

PowerShell 7 is strongly recommended. It is cross-platform (`pwsh` runs on Windows, Linux, and macOS) and handles all the edge cases (backups, fallback chains, verification).

### How do I pin to a specific DevKit version

DevKit uses a `VERSION` file at the repo root. To pin a machine to a specific release:

```bash
cd <devkit-path>
git fetch --tags
git checkout v1.2.0  # replace with desired version tag
```

The SessionStart hook skips auto-pull when the working tree is in detached HEAD state (which `git checkout <tag>` creates). To resume tracking main:

```bash
git checkout main
git pull --rebase origin main
```

You can also check for version updates without upgrading by running `/devkit-sync update` which compares local and remote VERSION files.

### What if I am offline

DevKit works fully offline. All rules, skills, agents, and hooks are local files (or symlinks to local files). The only network-dependent features are:

- **SessionStart auto-pull**: Skips silently after a 5-second timeout. Logged as `SKIPPED_OFFLINE`.
- **`/devkit-sync push`**: Fails if it cannot reach the remote. Changes remain committed locally and can be pushed when connectivity returns.
- **PR creation**: Requires GitHub access. The sync branch push succeeds to the local remote ref; the PR creation step fails gracefully.

No data is lost when offline. The next time you are online, auto-pull catches up and push works normally.

### What files are never synced between machines

Files matching these patterns stay local and are never committed to DevKit:

| Pattern | Purpose |
|---------|---------|
| `*.local.md` | Machine-specific rules and instructions |
| `settings.local.json` | Claude Code local settings (tool permissions) |
| `.credentials*` | Authentication tokens |
| `.machine-id` | Machine identifier |
| `projects/` | Project-specific memory |
| `plans/` | Session plans |
| `memory/` | Auto-memory files |
| `history.jsonl` | Conversation history |

These are defined in `.sync-manifest.json` under `tiers.machine.local_only_patterns`.

### How do I add a machine-specific rule without affecting other machines

Create a `.local.md` file in `~/.claude/rules/`:

```bash
cp <devkit-path>/project-templates/rules-local-template.md \
   ~/.claude/rules/my-machine.local.md
```

Edit the file with machine-specific patterns. Claude Code loads all `*.md` files from `~/.claude/rules/` automatically. The `.local.md` suffix is a convention that `.sync-manifest.json` excludes from syncing -- the file stays on this machine only.

When a local pattern proves universally useful, promote it with `/devkit-sync promote`.
