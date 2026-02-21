# setup/bootstrap.ps1 -- Kit 1: Machine bootstrap
#
# Phases:
#   1: Pre-flight checks (Windows version, winget, Hyper-V, WSL2, virtualization, dev mode)
#   2: Core tool installs (winget packages from machine/winget.json, VS Code extensions)
#   3-4: Git config, devspace setup, credentials (TODO: issue #11)
#   5-6: AI layer deploy and verification (TODO: issue #12)

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Force,      # Skip blocking check failures

    [Parameter()]
    [int]$Phase = 0      # Run specific phase only (0 = all)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Resolve paths relative to repo root and load libraries
# ---------------------------------------------------------------------------

$repoRoot = Split-Path -Path $PSScriptRoot -Parent
. "$PSScriptRoot\lib\install.ps1"  # also sources checks.ps1 and ui.ps1

# ============================= Phase 1 =====================================

function Invoke-Phase1 {
    <#
    .SYNOPSIS
        Pre-flight checks for Windows compatibility and required platform features.
    .DESCRIPTION
        Validates Windows build version, winget availability, Hyper-V, WSL2,
        hardware virtualization, and Developer Mode. Blocking items prevent
        continuation unless -Force is used.
    .OUTPUTS
        Hashtable with keys: Passed (int), Failed (int), Skipped (int),
        BlockingFailures (int), Items (array of result objects).
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )

    Write-Section 'Phase 1: Pre-Flight Checks'

    $items = [System.Collections.Generic.List[PSCustomObject]]::new()
    $passed  = 0
    $failed  = 0
    $skipped = 0
    $blockingFailures = 0

    # --- 1a. Windows version (build 22000+ = Windows 11) ---

    Write-Step 'Checking Windows version...'
    $winVer = Test-WindowsVersion -MinBuild 22000
    if ($winVer.Met) {
        Write-OK "Windows build $($winVer.Build) meets minimum 22000"
        $passed++
        $items.Add([PSCustomObject]@{ Name = 'Windows Version'; Status = 'OK'; Version = "$($winVer.Build)" })
    }
    else {
        Write-Fail "Windows build $($winVer.Build) is below minimum 22000 (Windows 11 required)"
        Write-Warn '  Docker Desktop and WSL2 work best on Windows 11 (build 22000+).'
        Write-Warn '  Some features may not work on older builds.'
        $failed++
        $blockingFailures++
        $items.Add([PSCustomObject]@{ Name = 'Windows Version'; Status = 'FAIL'; Version = "$($winVer.Build)" })
    }

    # --- 1b. winget availability ---

    Write-Step 'Checking winget availability...'
    $wingetCheck = Test-Tool 'winget'
    if ($wingetCheck.Met) {
        Write-OK "winget $($wingetCheck.Version) found"
        $passed++
        $items.Add([PSCustomObject]@{ Name = 'winget'; Status = 'OK'; Version = ($wingetCheck.Version ?? '-') })
    }
    else {
        Write-Fail 'winget not found on PATH'
        Write-Warn '  winget is required for automated package installation.'
        Write-Warn '  Install via: Microsoft Store > App Installer, or see https://aka.ms/getwinget'
        $failed++
        $blockingFailures++
        $items.Add([PSCustomObject]@{ Name = 'winget'; Status = 'FAIL'; Version = '-' })
    }

    # --- 1c. Manual requirements ---

    # Hyper-V (BLOCKING)
    $hyperV = _CheckManualRequirement `
        -Label 'Hyper-V' `
        -CheckFn { (Test-HyperV).Met } `
        -Why 'Required by Docker Desktop for container isolation.' `
        -Instructions @(
            '1. Open Settings > Apps > Optional Features > More Windows Features'
            '2. Check "Hyper-V" (both sub-items)'
            '3. Click OK and reboot when prompted'
            ''
            'Alternatively, run in an elevated PowerShell:'
            '  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All'
        ) `
        -Blocking

    $passed  += $hyperV.Passed
    $failed  += $hyperV.Failed
    $skipped += $hyperV.Skipped
    $blockingFailures += $hyperV.BlockingFailures
    $items.Add($hyperV.Item)

    # WSL2 (SKIPPABLE)
    $wsl2 = _CheckManualRequirement `
        -Label 'WSL2' `
        -CheckFn { (Test-WSL2).Met } `
        -Why 'Docker Desktop uses WSL2 backend for better performance.' `
        -Instructions @(
            '1. Open PowerShell as Administrator'
            '2. Run: wsl --install'
            '3. Reboot when prompted'
            ''
            'Or enable manually via Settings > Apps > Optional Features >'
            '  More Windows Features > check "Windows Subsystem for Linux"'
        ) `
        -Skippable

    $passed  += $wsl2.Passed
    $failed  += $wsl2.Failed
    $skipped += $wsl2.Skipped
    $blockingFailures += $wsl2.BlockingFailures
    $items.Add($wsl2.Item)

    # Hardware virtualization (informational -- can't enable from Windows)
    Write-Step 'Checking hardware virtualization...'
    $virtCheck = Test-Virtualization
    if ($virtCheck.Met) {
        Write-OK 'Hardware virtualization (VT-x / AMD-V) enabled'
        $passed++
        $items.Add([PSCustomObject]@{ Name = 'Virtualization'; Status = 'OK'; Version = '-' })
    }
    else {
        Write-Warn 'Hardware virtualization not detected'
        Write-Warn '  VT-x (Intel) or AMD-V must be enabled in BIOS/UEFI.'
        Write-Warn '  Reboot into BIOS settings to enable it.'
        Write-Warn '  Without it, Hyper-V and Docker cannot run.'
        $failed++
        $blockingFailures++
        $items.Add([PSCustomObject]@{ Name = 'Virtualization'; Status = 'FAIL'; Version = '-' })
    }

    # Developer Mode (SKIPPABLE)
    $devMode = _CheckManualRequirement `
        -Label 'Developer Mode' `
        -CheckFn { (Test-DeveloperMode).Met } `
        -Why 'Enables symlinks without elevation and unlocks dev features.' `
        -Instructions @(
            '1. Open Settings > System > For developers (or Privacy & security > For developers)'
            '2. Toggle "Developer Mode" to On'
            '3. Confirm the prompt'
        ) `
        -Skippable

    $passed  += $devMode.Passed
    $failed  += $devMode.Failed
    $skipped += $devMode.Skipped
    $blockingFailures += $devMode.BlockingFailures
    $items.Add($devMode.Item)

    # --- Summary ---

    Write-Host ''
    Write-VerifyTable $items.ToArray()

    if ($blockingFailures -gt 0 -and -not $Force) {
        Write-Warn "  $blockingFailures blocking issue(s) detected."
        Write-Warn '  Re-run with -Force to continue anyway, or resolve the issues above.'
    }
    elseif ($blockingFailures -gt 0 -and $Force) {
        Write-Warn "  $blockingFailures blocking issue(s) detected, continuing with -Force."
    }

    return @{
        Passed            = $passed
        Failed            = $failed
        Skipped           = $skipped
        BlockingFailures  = $blockingFailures
        Items             = $items.ToArray()
    }
}

function _CheckManualRequirement {
    <#
    .SYNOPSIS
        Checks a manual requirement, prompts user to fix if unmet, re-verifies.
    .DESCRIPTION
        Used internally by Invoke-Phase1 for items that require user action
        (enabling Windows features). Supports blocking and skippable modes.
    .OUTPUTS
        Hashtable with: Passed, Failed, Skipped, BlockingFailures, Item (PSCustomObject).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [scriptblock]$CheckFn,

        [Parameter(Mandatory)]
        [string]$Why,

        [Parameter(Mandatory)]
        [string[]]$Instructions,

        [Parameter()]
        [switch]$Blocking,

        [Parameter()]
        [switch]$Skippable
    )

    $passed = 0
    $failed = 0
    $skipped = 0
    $blockingFailures = 0

    Write-Step "Checking $Label..."
    $met = $false
    try { $met = & $CheckFn } catch { $met = $false }

    if ($met) {
        Write-OK "$Label is enabled"
        $passed = 1
        $item = [PSCustomObject]@{ Name = $Label; Status = 'OK'; Version = '-' }
        return @{
            Passed           = $passed
            Failed           = $failed
            Skipped          = $skipped
            BlockingFailures = $blockingFailures
            Item             = $item
        }
    }

    # Not met -- show instructions and prompt
    Write-Fail "$Label is not enabled"
    Write-Host ''
    Write-Host "  ${script:Dim}Why:${script:Reset} $Why"
    Write-Host ''
    foreach ($line in $Instructions) {
        Write-Host "    $line"
    }
    Write-Host ''

    if ($Skippable) {
        $response = Read-Host -Prompt '  Press Enter when done, or S to skip'
    }
    else {
        $response = Read-Host -Prompt '  Press Enter when done'
    }

    if ($Skippable -and $response -match '^[Ss]') {
        Write-Warn "$Label skipped"
        $skipped = 1
        $item = [PSCustomObject]@{ Name = $Label; Status = 'WARN'; Version = 'skipped' }
        return @{
            Passed           = $passed
            Failed           = $failed
            Skipped          = $skipped
            BlockingFailures = $blockingFailures
            Item             = $item
        }
    }

    # Re-check after user action
    $met = $false
    try { $met = & $CheckFn } catch { $met = $false }

    if ($met) {
        Write-OK "$Label is now enabled"
        $passed = 1
        $item = [PSCustomObject]@{ Name = $Label; Status = 'OK'; Version = '-' }
    }
    else {
        Write-Fail "$Label still not detected after user action"
        $failed = 1
        if ($Blocking) {
            $blockingFailures = 1
        }
        $item = [PSCustomObject]@{ Name = $Label; Status = 'FAIL'; Version = '-' }
    }

    return @{
        Passed           = $passed
        Failed           = $failed
        Skipped          = $skipped
        BlockingFailures = $blockingFailures
        Item             = $item
    }
}

# ============================= Phase 2 =====================================

function Invoke-Phase2 {
    <#
    .SYNOPSIS
        Installs core tools from winget manifest and VS Code extensions.
    .DESCRIPTION
        Reads machine/winget.json for package IDs and installs each via winget.
        Then reads machine/vscode-extensions.txt and installs extensions via
        the VS Code CLI.
    .OUTPUTS
        Hashtable with keys: WingetInstalled (int), WingetSkipped (int),
        WingetFailed (int), ExtInstalled (int), ExtFailed (int).
    #>
    [CmdletBinding()]
    param()

    Write-Section 'Phase 2: Core Tool Installs'

    # --- 2a. Winget packages ---

    Write-Step 'Reading winget manifest...'
    $wingetManifestPath = Join-Path $repoRoot 'machine' 'winget.json'

    if (-not (Test-Path $wingetManifestPath)) {
        Write-Fail "Winget manifest not found at $wingetManifestPath"
        return @{
            WingetInstalled = 0; WingetSkipped = 0; WingetFailed = 0
            ExtInstalled    = 0; ExtFailed     = 0
        }
    }

    $manifest = Get-Content $wingetManifestPath -Raw | ConvertFrom-Json
    $packages = $manifest.Sources | ForEach-Object { $_.Packages } | ForEach-Object { $_ }

    # Map known package IDs to check commands for pre/post-install verification
    $checkCommandMap = @{
        'Git.Git'                      = 'git'
        'GitHub.cli'                   = 'gh'
        'GoLang.Go'                    = 'go'
        'Microsoft.PowerShell'         = 'pwsh'
        'Microsoft.VisualStudioCode'   = 'code'
        'Docker.DockerDesktop'         = 'docker'
        'Microsoft.WindowsTerminal'    = 'wt'
        'Rustlang.Rustup'             = 'rustup'
        'Python.Launcher'             = 'py'
        'Kitware.CMake'               = 'cmake'
    }

    Write-OK "Found $($packages.Count) packages in manifest"
    Write-Host ''

    $wingetInstalled = 0
    $wingetSkipped   = 0
    $wingetFailed    = 0

    foreach ($pkg in $packages) {
        $packageId = $pkg.PackageIdentifier
        $checkCmd  = $null
        if ($checkCommandMap.ContainsKey($packageId)) {
            $checkCmd = $checkCommandMap[$packageId]
        }

        $splat = @{ Id = $packageId }
        if ($checkCmd) {
            $splat.Check = $checkCmd
        }

        $result = Install-WingetPackage @splat

        if ($result.Success -and $result.AlreadyInstalled) {
            $wingetSkipped++
        }
        elseif ($result.Success) {
            $wingetInstalled++
        }
        else {
            $wingetFailed++
        }
    }

    # --- 2b. VS Code extensions ---

    Write-Host ''
    Write-Step 'Reading VS Code extensions list...'
    $extListPath = Join-Path $repoRoot 'machine' 'vscode-extensions.txt'

    $extInstalled = 0
    $extFailed    = 0

    if (-not (Test-Path $extListPath)) {
        Write-Warn "Extension list not found at $extListPath -- skipping"
    }
    else {
        $extensionIds = Get-Content $extListPath |
            Where-Object { $_ -match '\S' } |
            ForEach-Object { $_.Trim() }

        Write-OK "Found $($extensionIds.Count) extensions in list"
        Write-Host ''

        $extResult = Install-VSCodeExtensions -Ids $extensionIds
        $extInstalled = $extResult.Installed
        $extFailed    = $extResult.Failed
    }

    # --- Summary ---

    Write-Host ''
    Write-Section 'Phase 2 Summary'

    $summaryRows = @(
        [PSCustomObject]@{
            Name    = 'Winget: installed'
            Status  = if ($wingetInstalled -gt 0) { 'OK' } else { 'OK' }
            Version = "$wingetInstalled"
        },
        [PSCustomObject]@{
            Name    = 'Winget: already present'
            Status  = 'OK'
            Version = "$wingetSkipped"
        },
        [PSCustomObject]@{
            Name    = 'Winget: failed'
            Status  = if ($wingetFailed -gt 0) { 'FAIL' } else { 'OK' }
            Version = "$wingetFailed"
        },
        [PSCustomObject]@{
            Name    = 'VS Code extensions: installed'
            Status  = if ($extInstalled -gt 0) { 'OK' } else { 'OK' }
            Version = "$extInstalled"
        },
        [PSCustomObject]@{
            Name    = 'VS Code extensions: failed'
            Status  = if ($extFailed -gt 0) { 'FAIL' } else { 'OK' }
            Version = "$extFailed"
        }
    )

    Write-VerifyTable $summaryRows

    return @{
        WingetInstalled = $wingetInstalled
        WingetSkipped   = $wingetSkipped
        WingetFailed    = $wingetFailed
        ExtInstalled    = $extInstalled
        ExtFailed       = $extFailed
    }
}

# ============================= Phase 3-6 Placeholders ======================

# Phase 3: Git configuration and devspace setup
# - Configure git user.name, user.email, core.editor
# - Set up init.templateDir for git templates
# - Configure global gitignore
# - Set up SSH keys for GitHub
# TODO: Implement in issue #11

# Phase 4: Credential and secret management
# - Configure Windows Credential Manager entries
# - Set up GPG signing for git commits
# - Store API keys / tokens securely
# TODO: Implement in issue #11

# Phase 5: AI layer deployment
# - Install Claude Code (npm install -g @anthropic/claude-code)
# - Deploy devkit config: rules, skills, agents, hooks to ~/.claude/
# - Configure MCP servers
# TODO: Implement in issue #12

# Phase 6: Verification and summary
# - Run full verification suite (setup/verify.sh equivalent)
# - Show overall bootstrap status
# - Print next-steps guidance
# TODO: Implement in issue #12

# ============================= Main Entry ==================================

function Invoke-Bootstrap {
    <#
    .SYNOPSIS
        Runs the machine bootstrap process.
    .DESCRIPTION
        Executes bootstrap phases in sequence. Use -Phase to run a single phase,
        or omit to run all implemented phases (currently 1-2).
    .PARAMETER Phase
        Phase number to run (1-6). Use 0 to run all implemented phases.
    .PARAMETER Force
        Continue past blocking pre-flight failures.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Phase = 0,

        [Parameter()]
        [switch]$Force
    )

    Write-Section 'devkit bootstrap'
    Write-Host '  Machine setup for development environment'
    Write-Host ''

    $shouldRunPhase1 = ($Phase -eq 0) -or ($Phase -eq 1)
    $shouldRunPhase2 = ($Phase -eq 0) -or ($Phase -eq 2)

    # Phase 1
    if ($shouldRunPhase1) {
        $phase1Result = Invoke-Phase1 -Force:$Force

        # If blocking failures and not forcing, stop before Phase 2
        if ($phase1Result.BlockingFailures -gt 0 -and -not $Force) {
            Write-Host ''
            Write-Warn 'Stopping after Phase 1 due to blocking failures.'
            Write-Warn 'Fix the issues above, or re-run with -Force to continue.'
            return @{ Phase1 = $phase1Result; Phase2 = $null }
        }
    }

    # Phase 2
    if ($shouldRunPhase2) {
        $phase2Result = Invoke-Phase2
    }

    # Phases 3-6: not yet implemented
    foreach ($futurePhase in @(3, 4, 5, 6)) {
        if ($Phase -eq $futurePhase) {
            Write-Warn "Phase $futurePhase is not yet implemented. See issues #11 and #12."
        }
    }

    # Final summary
    if ($Phase -eq 0) {
        Write-Host ''
        Write-Section 'Bootstrap Complete (Phases 1-2)'
        Write-Host '  Phases 3-6 not yet implemented.'
        Write-Host '  See: https://github.com/HerbHall/devkit/issues/11 (phases 3-4)'
        Write-Host '  See: https://github.com/HerbHall/devkit/issues/12 (phases 5-6)'
    }

    return @{
        Phase1 = if ($shouldRunPhase1) { $phase1Result } else { $null }
        Phase2 = if ($shouldRunPhase2) { $phase2Result } else { $null }
    }
}

# Run bootstrap with parameters from the command line
Invoke-Bootstrap -Phase $Phase -Force:$Force
