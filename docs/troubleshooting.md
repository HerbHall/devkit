# Troubleshooting

Common issues and fixes when using DevKit.

## Symlinks Not Working

**Symptom**: Claude Code does not load DevKit rules, skills, or hooks. Files in `~/.claude/` are missing or not linked to the DevKit clone.

**Fix**: Run the sync script to create symlinks:

```powershell
pwsh -File setup/sync.ps1 -Link
```

**Requirements**:

- PowerShell 7+ (`pwsh`)
- On Windows, creating symlinks may require **Developer Mode** enabled or running as Administrator
- Verify links with `ls -la ~/.claude/rules/` -- entries should point to your DevKit clone

## SessionStart Hook Not Firing

**Symptom**: No auto-pull, version check, or CLAUDE.md detection message when starting a Claude Code session.

**Possible causes**:

1. **Hook not configured**: Check that `~/.claude/settings.json` includes the SessionStart hook configuration. The setup script creates this automatically, but manual installations may miss it.

2. **Hook requires user input**: SessionStart hooks inject context as system reminders but only fire after the user sends their first message. Type anything to trigger it.

3. **Command failure**: The hook runs `claude/hooks/SessionStart.sh`. Verify the script exists and is executable:

   ```bash
   ls -la ~/.claude/hooks/SessionStart.sh
   ```

4. **Wrong hook type**: SessionStart hooks must use `type: "command"`, not `type: "prompt"`. See [Known Gotcha #32](../claude/rules/known-gotchas.md) for details.

## Skills Not Appearing

**Symptom**: `/skill-name` does not work or the skill is not listed.

**Fix**:

- Verify the skill directory exists: `ls ~/.claude/skills/{name}/SKILL.md`
- Check that `SKILL.md` has valid YAML frontmatter with a `description` field
- Ensure workflow files referenced in the routing table exist on disk
- Restart Claude Code after adding new skills

## CI Markdownlint Failures

**Symptom**: CI reports markdownlint errors on files that pass locally.

**Common causes**:

- **Missing config**: Ensure `.markdownlint.json` exists at the repo root. CI discovers config by walking up from each file's directory.
- **MD013 (line-length)**: DevKit disables this rule. Add `"MD013": false` to your config.
- **MD060 (table-column-style)**: Auto-enabled with `"default": true` in newer markdownlint versions. Add `"MD060": false` to your config.
- **Nested node_modules**: The exclusion pattern `"#node_modules"` only excludes the root. Add `"#*/node_modules"` for subdirectories. See [Known Gotcha #91](../claude/rules/known-gotchas.md).
- **Git template files**: `.git/CLAUDE.md` from git init templates gets picked up by `**/*.md` globs. Add `"#.git"` to exclusion patterns.

## Setup Script Failures

**Symptom**: `setup.ps1` fails or produces errors.

**Fix**:

- **PowerShell version**: Setup requires PowerShell 7+. Check with `$PSVersionTable.PSVersion`. Install via `winget install Microsoft.PowerShell`.
- **Execution policy**: If blocked, use `pwsh -ExecutionPolicy Bypass -File setup/setup.ps1` for a one-time bypass.
- **Missing dependencies**: The setup script expects `git` on PATH. Install with `winget install Git.Git`.

## CLAUDE.md Not Found Warning

**Symptom**: SessionStart hook warns that no CLAUDE.md was detected for the current project.

**Fix**:

- Run setup to create symlinks, which includes the global CLAUDE.md: `pwsh -File setup/setup.ps1`
- For project-specific CLAUDE.md, create one from the template:

  ```bash
  cp devkit/project-templates/claude-md-template.md CLAUDE.md
  ```

- The warning is informational -- Claude Code still works, but project-specific context is missing

## Pre-Push Hook Failures

**Symptom**: `git push` fails with errors from the pre-push hook.

**Possible causes**:

1. **Hook not installed**: Verify it exists:

   ```bash
   ls -la .git/hooks/pre-push
   ```

   If missing, copy from DevKit:

   ```bash
   cp devkit/git-templates/hooks/pre-push .git/hooks/pre-push
   chmod +x .git/hooks/pre-push
   ```

2. **Missing tools**: The hook runs build, test, and lint commands. Ensure all required tools are installed (e.g., `golangci-lint`, `npx`, `cargo`).

3. **Untracked files from parallel agents**: If multiple agents wrote files in the working tree, untracked files may cause build failures. Stash files belonging to other branches before pushing. See [Known Gotcha #76](../claude/rules/known-gotchas.md).

4. **Legitimate failures**: The hook is doing its job -- fix the build, test, or lint errors before pushing.

## Verify Script Not Implemented

**Symptom**: `pwsh -File setup/verify.ps1` does nothing or shows a stub message.

**Status**: This is a known issue ([#204](https://github.com/HerbHall/devkit/issues/204)). The `verify.ps1` script is a stub.

**Workaround**: Use the bootstrap Phase 6 verification instead:

```powershell
pwsh -File setup/bootstrap.ps1 -Phase 6
```

This checks tool availability, symlink integrity, and basic configuration.

## Sync Conflicts After Manual Edits

**Symptom**: `git diff` in the DevKit clone shows unexpected changes, or symlinked files have diverged.

**Fix**:

- Because DevKit uses symlinks, edits to `~/.claude/rules/` directly modify the clone. This is by design.
- Run `git diff` in the DevKit clone to review changes
- Use `/devkit-sync push` to commit and push changes back to the repo
- Use `/devkit-sync pull` to pull latest changes from the remote

## Windows-Specific Issues

### Python aliases block scripts

Windows Store Python aliases (`py.exe`, `python.exe` in WindowsApps) hang indefinitely instead of running Python. See [Known Gotcha #8](../claude/rules/known-gotchas.md).

**Fix**: Use the full path to a real Python installation, or check candidates with `"$p" --version` instead of `command -v`.

### MSYS path translation

MSYS bash auto-translates Unix paths to Windows paths. Use `MSYS_NO_PATHCONV=1` prefix or double-slash `//` to prevent translation. See [Known Gotcha #1](../claude/rules/known-gotchas.md).

### Stale PATH after tool installation

Tools installed via winget update the registry PATH but not the current session. Restart your terminal or refresh PATH manually. See [Known Gotcha #51](../claude/rules/known-gotchas.md).

## Getting More Help

- **Known gotchas**: See `claude/rules/known-gotchas.md` for 98 documented platform-specific issues
- **Autolearn patterns**: See `claude/rules/autolearn-patterns.md` for 117 discovered patterns
- **File an issue**: [DevKit Issues](https://github.com/HerbHall/devkit/issues)
