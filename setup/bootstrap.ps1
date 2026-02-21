# setup/bootstrap.ps1 -- Kit 1: Machine bootstrap
#
# Phases:
#   1: Pre-flight checks (Windows version, winget, Hyper-V, WSL2, virtualization, dev mode)
#   2: Core tool installs (winget packages from machine/winget.json, VS Code extensions)
#   3: Git config, devspace directory, PowerShell profile
#   4: Credentials (Windows Credential Manager)
#   5: AI layer deploy (Claude Code install, skills, rules, agents, hooks)
#   6: Verification and summary (full pass/fail table with next steps)

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
. "$PSScriptRoot\lib\install.ps1"      # also sources checks.ps1 and ui.ps1
. "$PSScriptRoot\lib\credentials.ps1"  # Set/Get/Test/Remove-DevkitCredential, Invoke-CredentialCollection

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

# ============================= Phase 3 =====================================

function Invoke-Phase3 {
    <#
    .SYNOPSIS
        Configures git, devspace directory, and PowerShell profile.
    .DESCRIPTION
        Phase 3 handles interactive configuration:
        - Writes ~/.gitconfig from machine/git-config.template with user values
        - Creates the devspace root directory and stores path in ~/.devkit-config.json
        - Appends devkit alias to PowerShell profile (with confirmation)
    .OUTPUTS
        Hashtable with keys: GitConfigured (bool), DevspacePath (string or $null),
        ProfileUpdated (bool).
    #>
    [CmdletBinding()]
    param()

    Write-Section 'Phase 3: Configuration'

    $gitConfigured = $false
    $devspacePath = $null
    $profileUpdated = $false

    # --- 3a. Git config ---

    Write-Step 'Setting up git configuration...'

    $existingName  = & git config --global --get user.name 2>$null
    $existingEmail = & git config --global --get user.email 2>$null

    if ($existingName -and $existingEmail) {
        Write-OK "Git already configured: $existingName <$existingEmail>"
        $gitConfigured = $true
    }
    else {
        $templatePath = Join-Path $repoRoot 'machine' 'git-config.template'
        if (-not (Test-Path $templatePath)) {
            Write-Fail "Git config template not found at $templatePath"
        }
        else {
            $userName  = Read-Required -Prompt 'Enter your full name for git commits'
            $userEmail = Read-Required -Prompt 'Enter your email address for git commits'

            $template = Get-Content $templatePath -Raw
            $gitConfig = $template `
                -replace 'YOUR_NAME', $userName `
                -replace 'YOUR_EMAIL', $userEmail

            $gitconfigPath = Join-Path $HOME '.gitconfig'
            Set-Content -Path $gitconfigPath -Value $gitConfig -Encoding utf8
            Write-OK "~/.gitconfig written ($userName <$userEmail>)"
            $gitConfigured = $true
        }
    }

    # --- 3b. Devspace directory ---

    Write-Host ''
    Write-Step 'Setting up devspace root directory...'

    $defaultDevspace = 'D:\DevSpace'
    $configFile = Join-Path $HOME '.devkit-config.json'

    # Check for existing config
    if (Test-Path $configFile) {
        try {
            $existingConfig = Get-Content $configFile -Raw | ConvertFrom-Json
            if ($existingConfig.devspacePath -and (Test-Path $existingConfig.devspacePath)) {
                Write-OK "Devspace already configured: $($existingConfig.devspacePath)"
                $devspacePath = $existingConfig.devspacePath
            }
        }
        catch {
            # Invalid config file -- re-prompt
        }
    }

    if (-not $devspacePath) {
        Write-Host "  Default: $defaultDevspace"
        $inputPath = Read-Host -Prompt "  Enter devspace root path [$defaultDevspace]"
        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            $inputPath = $defaultDevspace
        }

        if (-not (Test-Path $inputPath)) {
            $null = New-Item -ItemType Directory -Path $inputPath -Force
            Write-OK "$inputPath created"
        }
        else {
            Write-OK "$inputPath already exists"
        }

        $devspacePath = $inputPath

        # Store config
        $config = @{ devspacePath = $devspacePath }
        $config | ConvertTo-Json | Set-Content -Path $configFile -Encoding utf8
        Write-OK "Config saved to ~/.devkit-config.json"
    }

    # --- 3c. PowerShell profile ---

    Write-Host ''
    Write-Step 'Checking PowerShell profile...'

    $profilePath = $PROFILE.CurrentUserAllHosts
    $aliasBlock = @"

# devkit aliases (added by bootstrap)
function devkit { pwsh -File `"$devspacePath\devkit\setup\setup.ps1`" @args }
"@

    $profileExists = Test-Path $profilePath
    $alreadyHasAlias = $false

    if ($profileExists) {
        $profileContent = Get-Content $profilePath -Raw
        $alreadyHasAlias = $profileContent -match 'function devkit'
    }

    if ($alreadyHasAlias) {
        Write-OK 'devkit alias already in PowerShell profile'
        $profileUpdated = $true
    }
    else {
        Write-Host '  Will add to PowerShell profile:'
        Write-Host "    function devkit { pwsh -File `"$devspacePath\devkit\setup\setup.ps1`" @args }"
        Write-Host ''

        $confirm = Read-Confirm -Prompt 'Add devkit alias to PowerShell profile?'
        if ($confirm) {
            if (-not $profileExists) {
                $profileDir = Split-Path $profilePath -Parent
                if (-not (Test-Path $profileDir)) {
                    $null = New-Item -ItemType Directory -Path $profileDir -Force
                }
            }
            Add-Content -Path $profilePath -Value $aliasBlock -Encoding utf8
            Write-OK 'devkit alias added to PowerShell profile'
            $profileUpdated = $true
        }
        else {
            Write-Warn 'PowerShell profile update skipped'
        }
    }

    return @{
        GitConfigured  = $gitConfigured
        DevspacePath   = $devspacePath
        ProfileUpdated = $profileUpdated
    }
}

# ============================= Phase 4 =====================================

function Invoke-Phase4 {
    <#
    .SYNOPSIS
        Collects and stores credentials in Windows Credential Manager.
    .DESCRIPTION
        Phase 4 uses Invoke-CredentialCollection to interactively gather
        API tokens and secrets. Already-stored credentials are skipped.
        Optional credentials can be skipped by pressing Enter.
    .OUTPUTS
        Hashtable with keys: Stored (int), Skipped (int), Failed (int).
    #>
    [CmdletBinding()]
    param()

    Write-Section 'Phase 4: Credentials'
    Write-Step 'Storing credentials in Windows Credential Manager...'

    $credentialDefs = @(
        [PSCustomObject]@{
            Name           = 'devkit/github-pat'
            Label          = 'GitHub Personal Access Token'
            Instructions   = 'Create at https://github.com/settings/tokens -- needs scopes: repo, workflow, read:org'
            ValidateFn     = { param($v) $v -match '^gh[ps]_' -or $v -match '^github_pat_' }
            ValidationNote = 'Token should start with ghp_, ghs_, or github_pat_'
            Optional       = $false
        },
        [PSCustomObject]@{
            Name           = 'devkit/anthropic-key'
            Label          = 'Anthropic API Key'
            Instructions   = 'Create at https://console.anthropic.com/settings/keys'
            ValidateFn     = { param($v) $v -match '^sk-ant-' }
            ValidationNote = 'Key should start with sk-ant-'
            Optional       = $false
        },
        [PSCustomObject]@{
            Name           = 'devkit/docker-hub'
            Label          = 'Docker Hub Access Token'
            Instructions   = 'Create at https://hub.docker.com/settings/security -- for private image pulls'
            ValidateFn     = $null
            ValidationNote = $null
            Optional       = $true
        }
    )

    $result = Invoke-CredentialCollection -Credentials $credentialDefs

    Write-Host ''
    Write-Section 'Phase 4 Summary'
    Write-Step "$($result.Stored) stored, $($result.Skipped) already configured, $($result.Failed) failed"

    return $result
}

# ============================= Phase 5 =====================================

function Invoke-Phase5 {
    <#
    .SYNOPSIS
        Deploys the Claude AI layer: Claude Code install, skills, rules, agents, hooks.
    .DESCRIPTION
        Phase 5 installs Claude Code via npm, copies configuration files from the
        devkit repo to ~/.claude/, performs placeholder substitution on CLAUDE.md,
        and checks Claude authentication status.
    .OUTPUTS
        Hashtable with keys: ClaudeInstalled (bool), SkillsDeployed (int),
        RulesDeployed (int), AgentsDeployed (int), HooksDeployed (int),
        ClaudeAuthenticated (bool).
    #>
    [CmdletBinding()]
    param()

    Write-Section 'Phase 5: AI Layer'

    $claudeDir = Join-Path $HOME '.claude'
    $skillsDeployed = 0
    $rulesDeployed  = 0
    $agentsDeployed = 0
    $hooksDeployed  = 0

    # --- 5a. Ensure ~/.claude/ directory structure ---

    Write-Step 'Setting up ~/.claude/ directory...'
    foreach ($subdir in @('skills', 'rules', 'agents', 'hooks')) {
        $path = Join-Path $claudeDir $subdir
        if (-not (Test-Path $path)) {
            $null = New-Item -ItemType Directory -Path $path -Force
        }
    }
    Write-OK '~/.claude/ directory structure ready'

    # --- 5b. Install Claude Code via npm ---

    Write-Host ''
    Write-Step 'Checking Claude Code...'
    $claudeCheck = Test-Tool 'claude'
    if ($claudeCheck.Met) {
        Write-OK "Claude Code already installed ($($claudeCheck.Version))"
        $claudeInstalled = $true
    }
    else {
        $nodeCheck = Test-Tool 'node'
        if (-not $nodeCheck.Met) {
            Write-Warn 'Node.js not found -- cannot install Claude Code via npm'
            Write-Warn '  Install Node.js first (Phase 2), then re-run Phase 5'
            $claudeInstalled = $false
        }
        else {
            Write-Step 'Installing Claude Code via npm...'
            try {
                $output = & npm install -g @anthropic-ai/claude-code 2>&1 | Out-String
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    Write-OK 'Claude Code installed'
                    $claudeInstalled = $true
                }
                else {
                    Write-Fail "npm install failed (exit $exitCode)"
                    Write-Warn "Output:`n$output"
                    $claudeInstalled = $false
                }
            }
            catch {
                Write-Fail "Claude Code install exception: $_"
                $claudeInstalled = $false
            }
        }
    }

    # --- 5c. Deploy CLAUDE.md with placeholder substitution ---

    Write-Host ''
    Write-Step 'Deploying CLAUDE.md...'
    $srcClaudeMd = Join-Path $repoRoot 'claude' 'CLAUDE.md'
    $destClaudeMd = Join-Path $claudeDir 'CLAUDE.md'

    if (Test-Path $srcClaudeMd) {
        $content = Get-Content $srcClaudeMd -Raw

        # Read devspace path from config if available
        $configFile = Join-Path $HOME '.devkit-config.json'
        $devspaceVal = 'D:\DevSpace'
        if (Test-Path $configFile) {
            try {
                $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
                if ($cfg.devspacePath) { $devspaceVal = $cfg.devspacePath }
            }
            catch { }
        }

        # Substitute placeholders
        $content = $content -replace '\{\{USERNAME\}\}', $env:USERNAME
        $content = $content -replace '\{\{MACHINE\}\}', $env:COMPUTERNAME
        $content = $content -replace '\{\{DEVSPACE\}\}', $devspaceVal

        # Platform detection
        try {
            $osCaption = (Get-CimInstance Win32_OperatingSystem).Caption
            $platform = "Windows ($osCaption)"
        }
        catch {
            $platform = "Windows ($([System.Environment]::OSVersion.VersionString))"
        }
        $content = $content -replace '\{\{PLATFORM\}\}', $platform

        Set-Content -Path $destClaudeMd -Value $content -Encoding utf8
        Write-OK "CLAUDE.md deployed (user: $env:USERNAME, platform: $platform)"
    }
    else {
        Write-Warn "Source CLAUDE.md not found at $srcClaudeMd -- skipping"
    }

    # --- 5d. Deploy skills ---

    Write-Host ''
    Write-Step 'Deploying skills...'
    $srcSkills = Join-Path $repoRoot 'claude' 'skills'
    $destSkills = Join-Path $claudeDir 'skills'

    if (Test-Path $srcSkills) {
        $skillDirs = Get-ChildItem -Path $srcSkills -Directory
        foreach ($skill in $skillDirs) {
            $destSkill = Join-Path $destSkills $skill.Name
            if (-not (Test-Path $destSkill)) {
                $null = New-Item -ItemType Directory -Path $destSkill -Force
            }
            # Copy all files, overwrite if hash differs
            $files = Get-ChildItem -Path $skill.FullName -File -Recurse
            foreach ($file in $files) {
                $relPath = $file.FullName.Substring($skill.FullName.Length)
                $destFile = Join-Path $destSkill $relPath
                $destDir = Split-Path $destFile -Parent
                if (-not (Test-Path $destDir)) {
                    $null = New-Item -ItemType Directory -Path $destDir -Force
                }
                $shouldCopy = $true
                if (Test-Path $destFile) {
                    $srcHash  = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
                    $destHash = (Get-FileHash $destFile -Algorithm SHA256).Hash
                    $shouldCopy = $srcHash -ne $destHash
                }
                if ($shouldCopy) {
                    Copy-Item -Path $file.FullName -Destination $destFile -Force
                }
            }
            $skillsDeployed++
        }
        Write-OK "$skillsDeployed skills deployed to ~/.claude/skills/"
    }
    else {
        Write-Warn "Skills directory not found at $srcSkills"
    }

    # --- 5e. Deploy rules ---

    Write-Host ''
    Write-Step 'Deploying rules...'
    $srcRules = Join-Path $repoRoot 'claude' 'rules'
    $destRules = Join-Path $claudeDir 'rules'

    if (Test-Path $srcRules) {
        $ruleFiles = Get-ChildItem -Path $srcRules -File -Filter '*.md'
        foreach ($file in $ruleFiles) {
            $destFile = Join-Path $destRules $file.Name
            $shouldCopy = $true
            if (Test-Path $destFile) {
                $srcHash  = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
                $destHash = (Get-FileHash $destFile -Algorithm SHA256).Hash
                $shouldCopy = $srcHash -ne $destHash
            }
            if ($shouldCopy) {
                Copy-Item -Path $file.FullName -Destination $destFile -Force
            }
            $rulesDeployed++
        }
        Write-OK "$rulesDeployed rules deployed to ~/.claude/rules/"
    }
    else {
        Write-Warn "Rules directory not found at $srcRules"
    }

    # --- 5f. Deploy agents ---

    Write-Host ''
    Write-Step 'Deploying agents...'
    $srcAgents = Join-Path $repoRoot 'claude' 'agents'
    $destAgents = Join-Path $claudeDir 'agents'

    if (Test-Path $srcAgents) {
        $agentFiles = Get-ChildItem -Path $srcAgents -File -Filter '*.md'
        foreach ($file in $agentFiles) {
            $destFile = Join-Path $destAgents $file.Name
            $shouldCopy = $true
            if (Test-Path $destFile) {
                $srcHash  = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
                $destHash = (Get-FileHash $destFile -Algorithm SHA256).Hash
                $shouldCopy = $srcHash -ne $destHash
            }
            if ($shouldCopy) {
                Copy-Item -Path $file.FullName -Destination $destFile -Force
            }
            $agentsDeployed++
        }
        Write-OK "$agentsDeployed agents deployed to ~/.claude/agents/"
    }
    else {
        Write-Warn "Agents directory not found at $srcAgents"
    }

    # --- 5g. Deploy hooks ---

    Write-Host ''
    Write-Step 'Deploying hooks...'
    $srcHooks = Join-Path $repoRoot 'claude' 'hooks'
    $destHooks = Join-Path $claudeDir 'hooks'

    if (Test-Path $srcHooks) {
        $hookFiles = Get-ChildItem -Path $srcHooks -File
        foreach ($file in $hookFiles) {
            $destFile = Join-Path $destHooks $file.Name
            Copy-Item -Path $file.FullName -Destination $destFile -Force
            $hooksDeployed++
        }
        Write-OK "$hooksDeployed hooks deployed to ~/.claude/hooks/"
    }
    else {
        Write-Warn "Hooks directory not found at $srcHooks"
    }

    # --- 5h. Claude authentication check ---

    Write-Host ''
    Write-Step 'Checking Claude authentication...'
    $claudeAuth = Test-ClaudeAuth
    $claudeAuthenticated = $claudeAuth.Met

    if ($claudeAuthenticated) {
        Write-OK 'Claude Code is authenticated'
    }
    else {
        Write-Warn 'Claude Code is not authenticated'
        Write-Host '  Run: claude auth login'
        Write-Host '  (Opens browser for authentication)'
        Write-Host ''

        $response = Read-Host -Prompt '  Press Enter when authenticated, or S to skip'
        if ($response -notmatch '^[Ss]') {
            $recheck = Test-ClaudeAuth
            $claudeAuthenticated = $recheck.Met
            if ($claudeAuthenticated) {
                Write-OK 'Claude Code is now authenticated'
            }
            else {
                Write-Warn 'Claude Code still not authenticated -- some features will use template mode'
            }
        }
        else {
            Write-Warn 'Claude authentication skipped'
        }
    }

    return @{
        ClaudeInstalled    = $claudeInstalled
        SkillsDeployed     = $skillsDeployed
        RulesDeployed      = $rulesDeployed
        AgentsDeployed     = $agentsDeployed
        HooksDeployed      = $hooksDeployed
        ClaudeAuthenticated = $claudeAuthenticated
    }
}

# ============================= Phase 6 =====================================

function Invoke-Phase6 {
    <#
    .SYNOPSIS
        Runs full verification of the bootstrap and displays a pass/fail summary.
    .DESCRIPTION
        Phase 6 checks all tools, Windows features, credentials, and Claude
        skills, displaying a comprehensive table with version information.
        This is the same logic that verify.ps1 will use.
    .OUTPUTS
        Hashtable with keys: TotalChecks (int), Passed (int), Failed (int),
        Skipped (int).
    #>
    [CmdletBinding()]
    param()

    Write-Section 'Phase 6: Verification'

    $total   = 0
    $passed  = 0
    $failed  = 0
    $skipped = 0

    # --- 6a. Tools ---

    Write-Step 'Core tools:'
    $tools = @(
        @{ Name = 'git';     Check = 'git' },
        @{ Name = 'gh';      Check = 'gh' },
        @{ Name = 'go';      Check = 'go' },
        @{ Name = 'node';    Check = 'node' },
        @{ Name = 'docker';  Check = 'docker' },
        @{ Name = 'code';    Check = 'code' },
        @{ Name = 'claude';  Check = 'claude' },
        @{ Name = 'pwsh';    Check = 'pwsh' },
        @{ Name = 'rustup';  Check = 'rustup' },
        @{ Name = 'cmake';   Check = 'cmake' }
    )

    $toolRows = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($tool in $tools) {
        $result = Test-Tool $tool.Check
        $total++
        if ($result.Met) {
            $passed++
            $toolRows.Add([PSCustomObject]@{ Name = $tool.Name; Status = 'OK'; Version = ($result.Version ?? '-') })
        }
        else {
            $failed++
            $toolRows.Add([PSCustomObject]@{ Name = $tool.Name; Status = 'FAIL'; Version = '-' })
        }
    }
    Write-VerifyTable $toolRows.ToArray()

    # --- 6b. Windows features ---

    Write-Host ''
    Write-Step 'Windows features:'
    $featureRows = [System.Collections.Generic.List[PSCustomObject]]::new()

    $hyperv = Test-HyperV
    $total++
    if ($hyperv.Met) { $passed++ } else { $failed++ }
    $featureRows.Add([PSCustomObject]@{
        Name    = 'Hyper-V'
        Status  = if ($hyperv.Met) { 'OK' } else { 'FAIL' }
        Version = if ($hyperv.Met) { 'enabled' } else { 'disabled' }
    })

    $wsl = Test-WSL2
    $total++
    if ($wsl.Met) { $passed++ } else { $failed++ }
    $featureRows.Add([PSCustomObject]@{
        Name    = 'WSL2'
        Status  = if ($wsl.Met) { 'OK' } else { 'FAIL' }
        Version = if ($wsl.Met -and $wsl.Version) { $wsl.Version } elseif ($wsl.Met) { 'enabled' } else { 'disabled' }
    })

    $virt = Test-Virtualization
    $total++
    if ($virt.Met) { $passed++ } else { $failed++ }
    $featureRows.Add([PSCustomObject]@{
        Name    = 'Virtualization'
        Status  = if ($virt.Met) { 'OK' } else { 'FAIL' }
        Version = if ($virt.Met) { 'enabled' } else { 'disabled' }
    })

    $devmode = Test-DeveloperMode
    $total++
    if ($devmode.Met) { $passed++ } else { $failed++ }
    $featureRows.Add([PSCustomObject]@{
        Name    = 'Developer Mode'
        Status  = if ($devmode.Met) { 'OK' } else { 'FAIL' }
        Version = if ($devmode.Met) { 'enabled' } else { 'disabled' }
    })

    Write-VerifyTable $featureRows.ToArray()

    # --- 6c. Credentials ---

    Write-Host ''
    Write-Step 'Credentials:'
    $credRows = [System.Collections.Generic.List[PSCustomObject]]::new()
    $credChecks = @(
        @{ Name = 'GitHub PAT';    CredName = 'devkit/github-pat';   Optional = $false },
        @{ Name = 'Anthropic Key'; CredName = 'devkit/anthropic-key'; Optional = $false },
        @{ Name = 'Docker Hub';    CredName = 'devkit/docker-hub';    Optional = $true }
    )

    foreach ($cred in $credChecks) {
        $total++
        $exists = Test-DevkitCredential -Name $cred.CredName
        if ($exists) {
            $passed++
            $credRows.Add([PSCustomObject]@{ Name = $cred.Name; Status = 'OK'; Version = 'stored' })
        }
        elseif ($cred.Optional) {
            $skipped++
            $credRows.Add([PSCustomObject]@{ Name = $cred.Name; Status = 'WARN'; Version = 'skipped' })
        }
        else {
            $failed++
            $credRows.Add([PSCustomObject]@{ Name = $cred.Name; Status = 'FAIL'; Version = 'missing' })
        }
    }
    Write-VerifyTable $credRows.ToArray()

    # --- 6d. Claude skills ---

    Write-Host ''
    Write-Step 'Claude skills:'
    $skillRows = [System.Collections.Generic.List[PSCustomObject]]::new()
    $claudeSkillsDir = Join-Path $HOME '.claude' 'skills'

    if (Test-Path $claudeSkillsDir) {
        $installedSkills = Get-ChildItem -Path $claudeSkillsDir -Directory
        foreach ($skill in $installedSkills) {
            $total++
            $skillMd = Join-Path $skill.FullName 'SKILL.md'
            if (Test-Path $skillMd) {
                $passed++
                $skillRows.Add([PSCustomObject]@{ Name = $skill.Name; Status = 'OK'; Version = 'present' })
            }
            else {
                $failed++
                $skillRows.Add([PSCustomObject]@{ Name = $skill.Name; Status = 'FAIL'; Version = 'missing SKILL.md' })
            }
        }
    }
    else {
        $skillRows.Add([PSCustomObject]@{ Name = '(no skills directory)'; Status = 'FAIL'; Version = '-' })
        $total++
        $failed++
    }
    Write-VerifyTable $skillRows.ToArray()

    # --- Final summary ---

    Write-Host ''
    $optionalNote = if ($skipped -gt 0) { " ($skipped optional, skipped)" } else { '' }
    Write-Section "Bootstrap complete: $passed/$total checks passed${optionalNote}"

    if ($failed -gt 0) {
        Write-Host ''
        Write-Warn "$failed check(s) failed. Review the table above for details."
    }

    # Next steps
    Write-Host ''
    Write-Step 'Next steps:'
    Write-Host '  1. Open a new terminal to pick up profile changes'
    Write-Host '  2. Run "claude" to start a Claude Code session'
    Write-Host '  3. Use "devkit" alias to access setup menu anytime'
    Write-Host ''

    return @{
        TotalChecks = $total
        Passed      = $passed
        Failed      = $failed
        Skipped     = $skipped
    }
}

# ============================= Main Entry ==================================

function Invoke-Bootstrap {
    <#
    .SYNOPSIS
        Runs the machine bootstrap process.
    .DESCRIPTION
        Executes bootstrap phases in sequence. Use -Phase to run a single phase,
        or omit to run all phases (1-6).
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
    $shouldRunPhase3 = ($Phase -eq 0) -or ($Phase -eq 3)
    $shouldRunPhase4 = ($Phase -eq 0) -or ($Phase -eq 4)
    $shouldRunPhase5 = ($Phase -eq 0) -or ($Phase -eq 5)
    $shouldRunPhase6 = ($Phase -eq 0) -or ($Phase -eq 6)

    # Phase 1
    if ($shouldRunPhase1) {
        $phase1Result = Invoke-Phase1 -Force:$Force

        # If blocking failures and not forcing, stop before Phase 2
        if ($phase1Result.BlockingFailures -gt 0 -and -not $Force) {
            Write-Host ''
            Write-Warn 'Stopping after Phase 1 due to blocking failures.'
            Write-Warn 'Fix the issues above, or re-run with -Force to continue.'
            return @{ Phase1 = $phase1Result; Phase2 = $null; Phase3 = $null; Phase4 = $null; Phase5 = $null; Phase6 = $null }
        }
    }

    # Phase 2
    if ($shouldRunPhase2) {
        $phase2Result = Invoke-Phase2
    }

    # Phase 3
    if ($shouldRunPhase3) {
        $phase3Result = Invoke-Phase3
    }

    # Phase 4
    if ($shouldRunPhase4) {
        $phase4Result = Invoke-Phase4
    }

    # Phase 5
    if ($shouldRunPhase5) {
        $phase5Result = Invoke-Phase5
    }

    # Phase 6
    if ($shouldRunPhase6) {
        $phase6Result = Invoke-Phase6
    }

    return @{
        Phase1 = if ($shouldRunPhase1) { $phase1Result } else { $null }
        Phase2 = if ($shouldRunPhase2) { $phase2Result } else { $null }
        Phase3 = if ($shouldRunPhase3) { $phase3Result } else { $null }
        Phase4 = if ($shouldRunPhase4) { $phase4Result } else { $null }
        Phase5 = if ($shouldRunPhase5) { $phase5Result } else { $null }
        Phase6 = if ($shouldRunPhase6) { $phase6Result } else { $null }
    }
}

# Run bootstrap with parameters from the command line
Invoke-Bootstrap -Phase $Phase -Force:$Force
