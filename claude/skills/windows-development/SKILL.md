---
name: windows-development
description: Windows-specific development patterns, registry operations, shell integration, and path handling. Use when working with Windows registry, Explorer context menus, shell extensions, batch files, Windows Terminal configuration, or any task requiring Windows-specific knowledge about quoting, escaping, and path handling.
---

<critical_lessons>

<lesson name="registry_operations">
**NEVER use `reg.exe` for commands containing quotes** - quotes get stripped unpredictably.

**ALWAYS use PowerShell's native registry provider:**

```powershell
# Create key
$path = "Registry::HKEY_CLASSES_ROOT\Directory\shell\MyEntry"
$null = New-Item -Path $path -Force
Set-ItemProperty -Path $path -Name "(Default)" -Value "My Menu Item"
Set-ItemProperty -Path $path -Name "Icon" -Value "myapp.exe"

# Create command subkey
$null = New-Item -Path "$path\command" -Force
Set-ItemProperty -Path "$path\command" -Name "(Default)" -Value 'myapp.exe "%1"'
```

**Before writing new registry entries, ALWAYS examine existing working examples:**

```powershell
# List all context menu entries
reg query "HKEY_CLASSES_ROOT\Directory\shell"

# Show specific entry with command
reg query "HKEY_CLASSES_ROOT\Directory\shell\<entry>\command"

# Full recursive dump
reg query "HKEY_CLASSES_ROOT\Directory\shell" /s
```
</lesson>

<lesson name="context_menu_locations">
| Location | Trigger |
|----------|---------|
| `Directory\shell` | Right-click ON a folder |
| `Directory\Background\shell` | Right-click INSIDE a folder (empty space) |
</lesson>

<lesson name="path_variables">
| Variable | Meaning | Use Case |
|----------|---------|----------|
| `%1` | Selected item path | Right-click on folder |
| `%V` | Current directory | Right-click inside folder |
</lesson>

<lesson name="quoting_and_escaping">
**Single quotes survive better than escaped double quotes in PowerShell strings:**

```powershell
# GOOD - quotes preserved
$cmd = 'wsl.exe --cd "%1"'

# BAD - quotes may be stripped
$cmd = "wsl.exe --cd `"%1`""
```

**Always use `-LiteralPath` instead of `-Path` for paths with special characters:**

```powershell
Set-Location -LiteralPath $folderPath  # Handles [brackets], spaces, etc.
```
</lesson>

<lesson name="testing_approach">
**ALWAYS test with edge cases immediately:**

1. Create test folder: `D:\Test Folder With Spaces`
2. Create test folder: `D:\Test[Brackets]`
3. Test BOTH right-click scenarios:
   - Right-click ON the folder
   - Right-click INSIDE the folder (empty space)
4. Verify registry entries after creation:
   ```powershell
   reg query "HKEY_CLASSES_ROOT\Directory\shell\YourEntry\command"
   ```
</lesson>

<lesson name="windows_terminal">
**Profile names must match exactly** - check settings.json:
```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

**Common WT commands:**
```powershell
wt.exe -d "path"                    # Open at directory (uses default profile)
wt.exe -p "Profile Name" -d "path"  # Specific profile
wt.exe -p "Command Prompt" -d "path" cmd /k command  # CMD with command
```
</lesson>

<lesson name="batch_vs_powershell">
**Avoid batch files for complex quoting** - use PowerShell scripts instead:

```powershell
# PowerShell script with proper parameter handling
param([string]$Path)
& wt.exe -d $Path
```

**If batch files are required, use `%~1` to strip outer quotes:**
```batch
@echo off
wt.exe -d "%~1"
```
</lesson>

</critical_lessons>

<proven_patterns>
These patterns are proven to work from registry entries:

```
cmd.exe /s /k pushd "%V"
powershell.exe -NoExit -Command Set-Location -LiteralPath '%V'
wsl.exe --cd "%V"
wt.exe -d "%V" -p "Command Prompt"
"C:\Program Files\App\app.exe" "%1"
```
</proven_patterns>

<debugging_checklist>
When context menu entries don't work:

1. [ ] Check if `\command` subkey exists: `reg query "...\command"`
2. [ ] Verify quotes are preserved in the command value
3. [ ] Test with a simple path first (no spaces)
4. [ ] Test with a path containing spaces
5. [ ] Check Windows Event Viewer for errors
6. [ ] Try running the command manually in cmd/PowerShell
</debugging_checklist>
