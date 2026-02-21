# setup/backup.ps1 -- Refresh machine snapshot files from current state
#
# Usage:
#   .\setup\backup.ps1                  # Refresh all snapshots
#   .\setup\backup.ps1 -Target winget   # Refresh winget.json only
#   .\setup\backup.ps1 -Target vscode   # Refresh vscode-extensions.txt only
#   .\setup\backup.ps1 -Target git      # Refresh git-config.template only
#
# Outputs a diff summary after each refresh so you can see what changed.

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('all', 'winget', 'vscode', 'git')]
    [string]$Target = 'all'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve paths relative to repo root (one level up from setup/)
$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$machineDir = Join-Path $repoRoot 'machine'

# Dot-source libraries
. (Join-Path $PSScriptRoot 'lib' 'ui.ps1')
. (Join-Path $PSScriptRoot 'lib' 'checks.ps1')
. (Join-Path $PSScriptRoot 'lib' 'install.ps1')

# ---------------------------------------------------------------------------
# Helper: show diff summary between old and new file content
# ---------------------------------------------------------------------------

function Show-DiffSummary {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$OldContent,
        [string]$NewContent
    )

    $fileName = Split-Path -Path $Path -Leaf

    if ($null -eq $OldContent) {
        Write-OK "$fileName -- created (new file)"
        return
    }

    if ($OldContent -eq $NewContent) {
        Write-OK "$fileName -- unchanged"
        return
    }

    $oldLines = ($OldContent -split "`n").Count
    $newLines = ($NewContent -split "`n").Count
    $delta = $newLines - $oldLines

    $sign = if ($delta -ge 0) { '+' } else { '' }
    Write-OK "$fileName -- updated ($oldLines -> $newLines lines, ${sign}${delta})"
}

# ---------------------------------------------------------------------------
# Snapshot: winget.json
# ---------------------------------------------------------------------------

function Update-WingetSnapshot {
    [CmdletBinding()]
    param()

    $path = Join-Path $machineDir 'winget.json'
    Write-Section 'Winget Snapshot'

    $wingetCheck = Test-Tool 'winget'
    if (-not $wingetCheck.Met) {
        Write-Fail 'winget is not available -- skipping'
        return
    }

    # Capture old content for diff
    $oldContent = if (Test-Path $path) { Get-Content -Path $path -Raw } else { $null }

    Write-Step 'Exporting winget packages...'
    $result = Export-WingetManifest -Path $path

    if (-not $result.Success) {
        Write-Fail 'Winget export failed'
        return
    }

    $newContent = Get-Content -Path $path -Raw
    Show-DiffSummary -Path $path -OldContent $oldContent -NewContent $newContent

    Write-Warn 'Review winget.json and remove personal/non-dev packages before committing'
}

# ---------------------------------------------------------------------------
# Snapshot: vscode-extensions.txt
# ---------------------------------------------------------------------------

function Update-VSCodeSnapshot {
    [CmdletBinding()]
    param()

    $path = Join-Path $machineDir 'vscode-extensions.txt'
    Write-Section 'VS Code Extensions Snapshot'

    $codeCheck = Test-Tool 'code'
    if (-not $codeCheck.Met) {
        Write-Fail "'code' command not found -- skipping"
        return
    }

    $oldContent = if (Test-Path $path) { Get-Content -Path $path -Raw } else { $null }

    Write-Step 'Exporting VS Code extensions...'
    $result = Export-VSCodeExtensions -Path $path

    if (-not $result.Success) {
        Write-Fail 'VS Code export failed'
        return
    }

    $newContent = Get-Content -Path $path -Raw
    Show-DiffSummary -Path $path -OldContent $oldContent -NewContent $newContent
}

# ---------------------------------------------------------------------------
# Snapshot: git-config.template
# ---------------------------------------------------------------------------

function Update-GitConfigSnapshot {
    [CmdletBinding()]
    param()

    $path = Join-Path $machineDir 'git-config.template'
    Write-Section 'Git Config Template'

    $gitCheck = Test-Tool 'git'
    if (-not $gitCheck.Met) {
        Write-Fail 'git is not available -- skipping'
        return
    }

    $oldContent = if (Test-Path $path) { Get-Content -Path $path -Raw } else { $null }

    Write-Step 'Reading current git config...'

    # Read relevant git config sections (skip user-specific values)
    $sections = @(
        @{ Key = 'core.autocrlf';       Default = 'input' },
        @{ Key = 'core.editor';         Default = 'code --wait' },
        @{ Key = 'pull.rebase';         Default = 'false' },
        @{ Key = 'init.defaultBranch';  Default = 'main' },
        @{ Key = 'init.templateDir';    Default = '~/.git-templates' }
    )

    $lines = @(
        '# Git configuration template for devkit bootstrap',
        '# Copy to ~/.gitconfig and replace YOUR_NAME / YOUR_EMAIL placeholders.',
        '# bootstrap.ps1 does this automatically during Phase 3.',
        '',
        '[user]',
        '    name = YOUR_NAME',
        '    email = YOUR_EMAIL',
        ''
    )

    $currentSection = ''
    foreach ($item in $sections) {
        $parts = $item.Key -split '\.'
        $section = $parts[0]
        $key = $parts[1]

        # Read current value, fall back to default
        $value = & git config --global --get $item.Key 2>$null
        if ([string]::IsNullOrEmpty($value)) {
            $value = $item.Default
        }

        if ($section -ne $currentSection) {
            $lines += "[$section]"
            $currentSection = $section
        }
        $lines += "    $key = $value"
        $lines += ''
    }

    # Add LFS config if present
    $lfsProcess = & git config --global --get 'filter.lfs.process' 2>$null
    if ($lfsProcess) {
        $lines += '[filter "lfs"]'
        $lines += "    process = $lfsProcess"
        $lines += '    required = true'
        $lfsClean = & git config --global --get 'filter.lfs.clean' 2>$null
        if ($lfsClean) { $lines += "    clean = $lfsClean" }
        $lfsSmudge = & git config --global --get 'filter.lfs.smudge' 2>$null
        if ($lfsSmudge) { $lines += "    smudge = $lfsSmudge" }
        $lines += ''
    }

    $newContent = ($lines -join "`n") + "`n"
    Set-Content -Path $path -Value $newContent -NoNewline -Encoding utf8

    Show-DiffSummary -Path $path -OldContent $oldContent -NewContent $newContent
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Write-Section "Devkit Machine Snapshot Backup"
Write-Step "Target: $Target"

if (-not (Test-Path $machineDir)) {
    $null = New-Item -ItemType Directory -Path $machineDir -Force
}

switch ($Target) {
    'winget' { Update-WingetSnapshot }
    'vscode' { Update-VSCodeSnapshot }
    'git'    { Update-GitConfigSnapshot }
    'all' {
        Update-WingetSnapshot
        Update-VSCodeSnapshot
        Update-GitConfigSnapshot
    }
}

Write-Host ''
Write-Section 'Done'
Write-Step "Snapshot files are in: $machineDir"
Write-Step 'Review changes with: git diff machine/'
