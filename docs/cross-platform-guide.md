# Cross-Platform Path Resolution and Symlink Strategy

Reference for how DevKit resolves Claude Code config paths and creates symlinks on each supported OS.

## Claude Code Config Paths

| OS | Default Path | Override |
|----|-------------|----------|
| Windows | `%USERPROFILE%\.claude\` (or `$HOME/.claude/` in MSYS) | `claudeHome` in `.devkit-config.json` |
| macOS | `~/.claude/` | `claudeHome` in `.devkit-config.json` |
| Linux | `$XDG_CONFIG_HOME/claude/` (defaults to `~/.config/claude/` if unset) | `claudeHome` in `.devkit-config.json` |

The `claudeHome` field in `~/.devkit-config.json` stores the resolved absolute path. Setup detects the OS and writes the correct default. Users can override it for non-standard installations.

## Path Resolution Rules

- Always use `$HOME`-relative paths internally, never hardcoded drive letters or usernames
- The `os` field in `.devkit-config.json` (`windows`, `linux`, `darwin`) determines default behavior
- On Linux, check `$XDG_CONFIG_HOME` first; fall back to `~/.config/` if unset
- On Windows MSYS, `$HOME` resolves to `/c/Users/<name>` which maps to `C:\Users\<name>`

## Symlink Creation

### Per-OS behavior

**Windows** requires either Developer Mode enabled or Administrator privileges to create symbolic links. PowerShell's `New-Item -ItemType SymbolicLink` is the primary method.

**macOS and Linux** use `ln -s` with no special permissions needed. Any unprivileged user can create symlinks.

### Fallback chain

When the primary symlink method fails, DevKit tries alternatives in order:

1. **Symbolic link** -- preferred; preserves the live-edit workflow
2. **Directory junction** (Windows only) -- works without Developer Mode for directories; created via `New-Item -ItemType Junction`
3. **Hard link** -- works for files only (not directories); no special permissions on any OS
4. **File copy** -- last resort; works everywhere but loses the live-edit link

When copy mode is used, edits to `~/.claude/` do not propagate back to the DevKit clone. `sync.ps1 -Status` reports these as "Real file (not symlink)" with a drift warning.

### Windows Developer Mode detection

Before attempting symlinks, check Developer Mode status:

```powershell
$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
$devMode = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
```

If `$devMode` is not `1`, fall back to junctions (for directories) or hard links (for files).

## How claudeHome Resolves

The `claudeHome` field in `.devkit-config.json` is set once during setup and used by all sync operations:

```text
Setup detects OS
  -> Windows: claudeHome = Join-Path $HOME ".claude"
  -> macOS:   claudeHome = "$HOME/.claude"
  -> Linux:   claudeHome = "${XDG_CONFIG_HOME:-$HOME/.config}/claude"

sync.ps1 reads claudeHome from .devkit-config.json
  -> Uses it instead of hardcoded $HOME/.claude
  -> All symlink targets resolve relative to this path
```

If `claudeHome` is absent from the config, `sync.ps1` falls back to `$HOME/.claude` (the pre-v2 default).

## Summary

| Concern | Windows | macOS | Linux |
|---------|---------|-------|-------|
| Config path | `$HOME\.claude\` | `~/.claude/` | `$XDG_CONFIG_HOME/claude/` |
| Symlink method | `New-Item -ItemType SymbolicLink` | `ln -s` | `ln -s` |
| Permissions needed | Developer Mode or Admin | None | None |
| Directory fallback | Junction | N/A | N/A |
| File fallback | Hard link, then copy | Hard link, then copy | Hard link, then copy |
