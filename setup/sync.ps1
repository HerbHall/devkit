# setup/sync.ps1 -- Symlink management between DevKit clone and ~/.claude/
#
# Replaces copy-based installation with live symlinks. Edits to
# ~/.claude/rules/foo.md actually edit devkit/claude/rules/foo.md,
# and `git diff` in the DevKit clone shows changes instantly.
#
# Usage:
#   pwsh -File sync.ps1 -Link                        # create symlinks
#   pwsh -File sync.ps1 -Link -DevKitPath D:\DevKit  # explicit clone path
#   pwsh -File sync.ps1 -Unlink                      # replace symlinks with copies
#   pwsh -File sync.ps1 -Status                      # show current state
#   pwsh -File sync.ps1 -Verify                      # full validation

#Requires -Version 7.0

[CmdletBinding(DefaultParameterSetName = 'Status')]
param(
    [Parameter(ParameterSetName = 'Link', Mandatory)]
    [switch]$Link,

    [Parameter(ParameterSetName = 'Unlink', Mandatory)]
    [switch]$Unlink,

    [Parameter(ParameterSetName = 'Status', Mandatory = $false)]
    [switch]$Status,

    [Parameter(ParameterSetName = 'Verify', Mandatory)]
    [switch]$Verify,

    [Parameter(ParameterSetName = 'Link')]
    [string]$DevKitPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot  = Split-Path -Parent $ScriptDir

. (Join-Path $ScriptDir 'lib' 'ui.ps1')

$ClaudeHome = Join-Path $HOME '.claude'

# ---------------------------------------------------------------------------
# Resolve DevKit clone path
# ---------------------------------------------------------------------------

function Resolve-DevKitPath {
    <#
    .SYNOPSIS
        Determines the DevKit clone directory from parameter, config, or repo root.
    #>
    param([string]$Explicit)

    # 1. Explicit parameter
    if ($Explicit) {
        if (-not (Test-Path $Explicit)) {
            Write-Fail "DevKit path not found: $Explicit"
            return $null
        }
        return (Resolve-Path $Explicit).Path
    }

    # 2. Running from within the repo
    $manifest = Join-Path $RepoRoot '.sync-manifest.json'
    if (Test-Path $manifest) {
        return $RepoRoot
    }

    # 3. Machine config
    $configPath = Join-Path $HOME '.devkit-config.json'
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($config.devspace) {
            $candidate = Join-Path $config.devspace 'devkit'
            if (Test-Path (Join-Path $candidate '.sync-manifest.json')) {
                return $candidate
            }
        }
    }

    Write-Fail 'Could not locate DevKit clone. Use -DevKitPath to specify.'
    return $null
}

# ---------------------------------------------------------------------------
# Read manifest
# ---------------------------------------------------------------------------

function Read-SyncManifest {
    <#
    .SYNOPSIS
        Parses .sync-manifest.json and returns the manifest object.
    #>
    param([string]$DevKit)

    $manifestPath = Join-Path $DevKit '.sync-manifest.json'
    if (-not (Test-Path $manifestPath)) {
        Write-Fail ".sync-manifest.json not found in $DevKit"
        return $null
    }
    return Get-Content $manifestPath -Raw | ConvertFrom-Json
}

# ---------------------------------------------------------------------------
# Symlink helpers
# ---------------------------------------------------------------------------

function Test-IsSymlink {
    <#
    .SYNOPSIS
        Returns $true if the path is a symlink or junction.
    #>
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $item = Get-Item $Path -Force
    return ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
}

function Get-SymlinkTarget {
    <#
    .SYNOPSIS
        Returns the target of a symlink, or $null if not a symlink.
    #>
    param([string]$Path)
    if (-not (Test-IsSymlink $Path)) { return $null }
    return (Get-Item $Path -Force).Target
}

function New-SafeSymlink {
    <#
    .SYNOPSIS
        Creates a symlink, backing up existing real files first.
    .OUTPUTS
        Hashtable with Status (linked, backed-up, skipped, failed) and Message.
    #>
    param(
        [string]$LinkPath,
        [string]$TargetPath,
        [string]$BackupDir,
        [switch]$IsDirectory
    )

    # Target must exist
    if (-not (Test-Path $TargetPath)) {
        return @{ Status = 'failed'; Message = "Target not found: $TargetPath" }
    }

    # Already correctly linked
    if (Test-IsSymlink $LinkPath) {
        $existingTarget = Get-SymlinkTarget $LinkPath
        $resolvedTarget = (Resolve-Path $TargetPath).Path
        if ($existingTarget -eq $resolvedTarget) {
            return @{ Status = 'skipped'; Message = 'Already linked correctly' }
        }
        # Wrong target -- remove and relink
        Remove-Item $LinkPath -Force
    }
    elseif (Test-Path $LinkPath) {
        # Real file/dir exists -- back it up
        $relativePath = $LinkPath.Replace($ClaudeHome, '').TrimStart('\', '/')
        $backupTarget = Join-Path $BackupDir $relativePath
        $backupParent = Split-Path -Parent $backupTarget
        if (-not (Test-Path $backupParent)) {
            New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
        }
        Move-Item -Path $LinkPath -Destination $backupTarget -Force
        Write-Step "Backed up: $relativePath"
    }

    # Ensure parent directory exists
    $linkParent = Split-Path -Parent $LinkPath
    if (-not (Test-Path $linkParent)) {
        New-Item -ItemType Directory -Path $linkParent -Force | Out-Null
    }

    # Create symlink
    try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath -Force | Out-Null
        return @{ Status = 'linked'; Message = 'Symlink created' }
    }
    catch {
        # Fallback: try junction for directories
        if ($IsDirectory) {
            try {
                New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath -Force | Out-Null
                return @{ Status = 'linked'; Message = 'Junction created (symlink fallback)' }
            }
            catch {
                return @{ Status = 'failed'; Message = "Junction failed: $_" }
            }
        }
        return @{ Status = 'failed'; Message = "Symlink failed: $_" }
    }
}

# ---------------------------------------------------------------------------
# Collect all expected link pairs from manifest
# ---------------------------------------------------------------------------

function Get-LinkPairs {
    <#
    .SYNOPSIS
        Returns an array of @{ LinkPath; TargetPath; IsDirectory } from the manifest.
    #>
    param(
        [object]$Manifest,
        [string]$DevKit
    )

    $pairs = @()

    # Individual files: rules, agents, hooks, top-level files
    foreach ($category in @('rules', 'agents', 'hooks', 'files')) {
        $items = $Manifest.shared.$category
        if (-not $items) { continue }
        foreach ($relativePath in $items) {
            $targetPath = Join-Path $DevKit $relativePath
            # Map devkit relative path to ~/.claude/ path
            # e.g., "claude/rules/foo.md" -> "~/.claude/rules/foo.md"
            $claudeRelative = $relativePath -replace '^claude/', ''
            $linkPath = Join-Path $ClaudeHome $claudeRelative
            $pairs += @{ LinkPath = $linkPath; TargetPath = $targetPath; IsDirectory = $false }
        }
    }

    # Skill directories (directory symlinks)
    foreach ($skillPath in $Manifest.shared.skills) {
        $targetPath = Join-Path $DevKit $skillPath
        $claudeRelative = $skillPath -replace '^claude/', ''
        $linkPath = Join-Path $ClaudeHome $claudeRelative
        $pairs += @{ LinkPath = $linkPath; TargetPath = $targetPath; IsDirectory = $true }
    }

    return $pairs
}

# ---------------------------------------------------------------------------
# -Link: Create symlinks
# ---------------------------------------------------------------------------

function Invoke-Link {
    param([string]$DevKitPathParam)

    $devKit = Resolve-DevKitPath -Explicit $DevKitPathParam
    if (-not $devKit) { return }

    $manifest = Read-SyncManifest -DevKit $devKit
    if (-not $manifest) { return }

    Write-Section 'Sync: Link DevKit to ~/.claude/'
    Write-Step "DevKit clone: $devKit"
    Write-Step "Claude home:  $ClaudeHome"

    # Prepare backup directory
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupDir = Join-Path $ClaudeHome '.backup' $timestamp

    $pairs = Get-LinkPairs -Manifest $manifest -DevKit $devKit

    $counts = @{ linked = 0; skipped = 0; 'backed-up' = 0; failed = 0 }

    foreach ($pair in $pairs) {
        $result = New-SafeSymlink `
            -LinkPath $pair.LinkPath `
            -TargetPath $pair.TargetPath `
            -BackupDir $backupDir `
            -IsDirectory:$pair.IsDirectory

        $counts[$result.Status]++

        $displayPath = $pair.LinkPath.Replace($ClaudeHome, '~/.claude')
        switch ($result.Status) {
            'linked'  { Write-OK "Linked: $displayPath" }
            'skipped' { }  # quiet for already-correct links
            'failed'  { Write-Fail "$displayPath -- $($result.Message)" }
        }
    }

    # Clean up empty backup dir
    if ((Test-Path $backupDir) -and (Get-ChildItem $backupDir -Recurse -File).Count -eq 0) {
        Remove-Item $backupDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Summary
    Write-Host ''
    Write-Section 'Sync Summary'
    Write-OK "Linked:    $($counts['linked'])"
    if ($counts['skipped'] -gt 0) {
        Write-Step "Unchanged: $($counts['skipped'])"
    }
    if ($counts['backed-up'] -gt 0) {
        Write-Warn "Backed up: $($counts['backed-up']) (to .backup/$timestamp/)"
    }
    if ($counts['failed'] -gt 0) {
        Write-Fail "Failed:    $($counts['failed'])"
    }
}

# ---------------------------------------------------------------------------
# -Unlink: Replace symlinks with copies
# ---------------------------------------------------------------------------

function Invoke-Unlink {
    $devKit = Resolve-DevKitPath -Explicit ''
    if (-not $devKit) { return }

    $manifest = Read-SyncManifest -DevKit $devKit
    if (-not $manifest) { return }

    Write-Section 'Sync: Unlink (replace symlinks with copies)'

    $pairs = Get-LinkPairs -Manifest $manifest -DevKit $devKit
    $converted = 0
    $skippedCount = 0

    foreach ($pair in $pairs) {
        if (-not (Test-IsSymlink $pair.LinkPath)) {
            $skippedCount++
            continue
        }

        $target = Get-SymlinkTarget $pair.LinkPath
        if (-not $target -or -not (Test-Path $target)) {
            Write-Warn "Broken symlink, removing: $($pair.LinkPath)"
            Remove-Item $pair.LinkPath -Force
            continue
        }

        Remove-Item $pair.LinkPath -Force
        if ($pair.IsDirectory) {
            Copy-Item -Path $target -Destination $pair.LinkPath -Recurse -Force
        }
        else {
            Copy-Item -Path $target -Destination $pair.LinkPath -Force
        }
        $converted++
    }

    Write-OK "Converted $converted symlinks to copies ($skippedCount already real files)"
}

# ---------------------------------------------------------------------------
# -Status: Show current state
# ---------------------------------------------------------------------------

function Invoke-Status {
    $devKit = Resolve-DevKitPath -Explicit ''
    if (-not $devKit) { return }

    $manifest = Read-SyncManifest -DevKit $devKit
    if (-not $manifest) { return }

    Write-Section 'Sync Status'
    Write-Step "DevKit clone: $devKit"
    Write-Step "Claude home:  $ClaudeHome"

    # Machine ID
    $machineIdPath = Join-Path $ClaudeHome '.machine-id'
    if (Test-Path $machineIdPath) {
        $machineId = (Get-Content $machineIdPath -Raw).Trim()
        Write-OK "Machine ID: $machineId"
    }
    else {
        Write-Warn 'Machine ID: not set (run sync.ps1 -Link to generate)'
    }

    # Git status of DevKit clone
    Write-Host ''
    Write-Step 'DevKit git status:'
    $gitStatus = & git -C $devKit status --porcelain 2>&1
    $gitBranch = & git -C $devKit rev-parse --abbrev-ref HEAD 2>&1
    if ($gitStatus) {
        Write-Warn "  Branch: $gitBranch (dirty -- $(@($gitStatus).Count) changed files)"
    }
    else {
        Write-OK "  Branch: $gitBranch (clean)"
    }

    # Ahead/behind
    try {
        $aheadBehind = & git -C $devKit rev-list --left-right --count 'HEAD...@{upstream}' 2>&1
        if ($aheadBehind -match '(\d+)\s+(\d+)') {
            $ahead = [int]$Matches[1]
            $behind = [int]$Matches[2]
            if ($ahead -gt 0) { Write-Warn "  $ahead commit(s) ahead of remote" }
            if ($behind -gt 0) { Write-Warn "  $behind commit(s) behind remote" }
            if ($ahead -eq 0 -and $behind -eq 0) { Write-OK '  Up to date with remote' }
        }
    }
    catch {
        Write-Step '  (no upstream tracking branch)'
    }

    # Symlink state
    Write-Host ''
    Write-Step 'Symlink state:'
    $pairs = Get-LinkPairs -Manifest $manifest -DevKit $devKit
    $valid = 0
    $broken = 0
    $notSymlink = 0
    $missing = 0

    foreach ($pair in $pairs) {
        $displayPath = $pair.LinkPath.Replace($ClaudeHome, '~/.claude')
        if (-not (Test-Path $pair.LinkPath)) {
            Write-Fail "  Missing: $displayPath"
            $missing++
        }
        elseif (Test-IsSymlink $pair.LinkPath) {
            $target = Get-SymlinkTarget $pair.LinkPath
            if ($target -and (Test-Path $target)) {
                $valid++
            }
            else {
                Write-Fail "  Broken:  $displayPath -> $target"
                $broken++
            }
        }
        else {
            Write-Warn "  Real file (not symlink): $displayPath"
            $notSymlink++
        }
    }

    Write-Host ''
    Write-OK "Valid symlinks:    $valid"
    if ($notSymlink -gt 0) { Write-Warn "Real files:        $notSymlink (run -Link to convert)" }
    if ($missing -gt 0)    { Write-Fail "Missing:           $missing" }
    if ($broken -gt 0)     { Write-Fail "Broken:            $broken" }
}

# ---------------------------------------------------------------------------
# -Verify: Full validation
# ---------------------------------------------------------------------------

function Invoke-Verify {
    $devKit = Resolve-DevKitPath -Explicit ''
    if (-not $devKit) {
        Write-Fail 'VERIFY FAILED: DevKit clone not found'
        exit 1
    }

    $manifest = Read-SyncManifest -DevKit $devKit
    if (-not $manifest) {
        Write-Fail 'VERIFY FAILED: .sync-manifest.json not found'
        exit 1
    }

    Write-Section 'Sync Verification'
    $errors = 0

    # 1. DevKit clone exists
    Write-OK "DevKit clone exists at $devKit"

    # 2. All shared files are symlinked
    $pairs = Get-LinkPairs -Manifest $manifest -DevKit $devKit
    foreach ($pair in $pairs) {
        $displayPath = $pair.LinkPath.Replace($ClaudeHome, '~/.claude')
        if (-not (Test-Path $pair.LinkPath)) {
            Write-Fail "Missing: $displayPath"
            $errors++
        }
        elseif (-not (Test-IsSymlink $pair.LinkPath)) {
            Write-Fail "Not a symlink: $displayPath"
            $errors++
        }
        else {
            $target = Get-SymlinkTarget $pair.LinkPath
            if (-not $target -or -not (Test-Path $target)) {
                Write-Fail "Broken symlink: $displayPath"
                $errors++
            }
        }
    }

    if ($errors -eq 0) {
        Write-OK "All $($pairs.Count) shared files are correctly symlinked"
    }

    # 3. Local-only files are NOT symlinked
    $localChecks = @(
        (Join-Path $ClaudeHome 'settings.local.json'),
        (Join-Path $ClaudeHome 'CLAUDE.local.md')
    )
    foreach ($localPath in $localChecks) {
        if ((Test-Path $localPath) -and (Test-IsSymlink $localPath)) {
            Write-Fail "Local-only file is symlinked (should be real): $localPath"
            $errors++
        }
    }

    # 4. Machine ID exists
    $machineIdPath = Join-Path $ClaudeHome '.machine-id'
    if (Test-Path $machineIdPath) {
        $machineId = (Get-Content $machineIdPath -Raw).Trim()
        if ($machineId -match '^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$') {
            Write-OK "Machine ID: $machineId"
        }
        else {
            Write-Fail "Machine ID format invalid: '$machineId'"
            $errors++
        }
    }
    else {
        Write-Warn 'Machine ID not set (optional but recommended)'
    }

    # 5. All symlinks resolve
    Write-Host ''
    if ($errors -eq 0) {
        Write-OK 'VERIFY PASSED: All checks passed'
    }
    else {
        Write-Fail "VERIFY FAILED: $errors error(s) found"
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

switch ($PSCmdlet.ParameterSetName) {
    'Link'   { Invoke-Link -DevKitPathParam $DevKitPath }
    'Unlink' { Invoke-Unlink }
    'Status' { Invoke-Status }
    'Verify' { Invoke-Verify }
}
