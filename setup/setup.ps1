# setup/setup.ps1 -- Main menu entry point for devkit setup
#
# Presents a numbered menu and dispatches to the three kit scripts:
#   1. Machine bootstrap (bootstrap.ps1)
#   2. Stack profile install (stack.ps1)
#   3. New project scaffolding (new-project.ps1)
#   4. Verify installation (verify.ps1)
#   5. Refresh machine snapshot (backup.ps1)
#
# Usage:
#   pwsh -File setup.ps1                  # interactive menu
#   pwsh -File setup.ps1 -Kit bootstrap   # direct dispatch (skips menu)

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('bootstrap', 'stack', 'project', 'verify', 'snapshot')]
    [string]$Kit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Resolve paths (works when run from any directory)
# ---------------------------------------------------------------------------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot  = Split-Path -Parent $ScriptDir

# ---------------------------------------------------------------------------
# Dot-source shared libraries
# ---------------------------------------------------------------------------

. (Join-Path $ScriptDir 'lib' 'ui.ps1')
. (Join-Path $ScriptDir 'lib' 'checks.ps1')

# ---------------------------------------------------------------------------
# Read version from VERSION file
# ---------------------------------------------------------------------------

function Get-DevkitVersion {
    $versionFile = Join-Path $RepoRoot 'VERSION'
    if (Test-Path $versionFile) {
        $ver = (Get-Content $versionFile -Raw).Trim()
        if ($ver) { return $ver }
    }
    return 'dev'
}

# ---------------------------------------------------------------------------
# Quick status check
# ---------------------------------------------------------------------------

function Get-QuickStatus {
    <#
    .SYNOPSIS
        Runs fast core tool checks and returns a status message.
    #>
    $results = Get-PreflightStatus
    $missing = @($results | Where-Object { -not $_.Met })
    if ($missing.Count -eq 0) {
        return @{ Bootstrapped = $true; Message = 'Machine appears bootstrapped' }
    }
    $names = ($missing | ForEach-Object { $_.Name }) -join ', '
    return @{ Bootstrapped = $false; Message = "Some tools not found ($names) -- run option 1" }
}

# ---------------------------------------------------------------------------
# Dispatch helpers
# ---------------------------------------------------------------------------

function Invoke-Kit {
    param([string]$ScriptName)

    $path = Join-Path $ScriptDir $ScriptName
    if (-not (Test-Path $path)) {
        Write-Fail "$ScriptName not found at $path"
        return
    }

    try {
        & $path
    }
    catch {
        if ($_.Exception.Message -match 'Not yet implemented') {
            Write-Warn "$ScriptName is not yet implemented"
        }
        else {
            Write-Fail "$ScriptName failed: $($_.Exception.Message)"
        }
    }
}

function Invoke-Snapshot {
    <#
    .SYNOPSIS
        Refreshes machine snapshots (winget manifest + VS Code extensions).
    #>
    . (Join-Path $ScriptDir 'lib' 'install.ps1')

    $machineDir = Join-Path $RepoRoot 'machine'

    Write-Section 'Refresh Machine Snapshot'

    $winget = Export-WingetManifest -Path (Join-Path $machineDir 'winget.json')
    $vscode = Export-VSCodeExtensions -Path (Join-Path $machineDir 'vscode-extensions.txt')

    if ($winget.Success -and $vscode.Success) {
        Write-OK 'Machine snapshot updated'
    }
    elseif ($winget.Success -or $vscode.Success) {
        Write-Warn 'Machine snapshot partially updated'
    }
    else {
        Write-Fail 'Machine snapshot failed'
    }
}

# ---------------------------------------------------------------------------
# Direct dispatch via -Kit parameter
# ---------------------------------------------------------------------------

if ($Kit) {
    switch ($Kit) {
        'bootstrap' { Invoke-Kit 'bootstrap.ps1' }
        'stack'     { Invoke-Kit 'stack.ps1' }
        'project'   { Invoke-Kit 'new-project.ps1' }
        'verify'    { Invoke-Kit 'verify.ps1' }
        'snapshot'  { Invoke-Snapshot }
    }
    exit 0
}

# ---------------------------------------------------------------------------
# Interactive menu
# ---------------------------------------------------------------------------

$version = Get-DevkitVersion

while ($true) {
    # Header
    Write-Host ''
    Write-Host "devkit v${version} -- Windows AI Development Platform"
    Write-Host ('=' * 52)

    # Quick status
    $status = Get-QuickStatus
    if ($status.Bootstrapped) {
        Write-OK $status.Message
    }
    else {
        Write-Warn $status.Message
    }

    # Menu
    Write-Host ''
    Write-Host '  1. Bootstrap this machine       (Kit 1 -- first-time setup)'
    Write-Host '  2. Add a stack profile          (Kit 2 -- add tools for a project type)'
    Write-Host '  3. Set up a new project         (Kit 3 -- scaffold a new project)'
    Write-Host '  4. Verify installation          (run checks, show pass/fail table)'
    Write-Host '  5. Refresh machine snapshot     (update winget.json and extension list)'
    Write-Host '  0. Exit'
    Write-Host ''

    $choice = Read-Host -Prompt 'Select option [0-5]'

    switch ($choice) {
        '1' { Invoke-Kit 'bootstrap.ps1' }
        '2' { Invoke-Kit 'stack.ps1' }
        '3' { Invoke-Kit 'new-project.ps1' }
        '4' { Invoke-Kit 'verify.ps1' }
        '5' { Invoke-Snapshot }
        '0' {
            Write-Host ''
            Write-Host 'Goodbye.'
            exit 0
        }
        default {
            Write-Warn "Invalid selection '$choice'. Enter a number between 0 and 5."
        }
    }
}
