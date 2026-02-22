# setup/lib/checks.ps1 -- Prerequisite and tool detection library
#
# Provides structured check functions for bootstrap and verify scripts.
# All Test-* functions return @{ Met = [bool]; ... } hashtables.
# Never throws on missing tools -- always returns @{ Met = $false }.

#Requires -Version 7.0

Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function _ResolveCommand {
    <#
    .SYNOPSIS
        Wraps Get-Command so callers never see exceptions.
    #>
    param([string]$Name)
    try {
        $cmd = Get-Command $Name -ErrorAction Stop
        return $cmd
    } catch {
        return $null
    }
}

function _ExtractVersion {
    <#
    .SYNOPSIS
        Runs a tool's version command and extracts the first semver-ish match.
    .DESCRIPTION
        Handles common variations: --version, version, -v.
        Returns $null when parsing fails.
    #>
    param(
        [string]$Tool,
        [string]$Path
    )

    # Map tools to their version-extraction command
    $versionArgs = switch ($Tool) {
        'go'       { @('version') }
        'python'   { @('--version') }
        'python3'  { @('--version') }
        'py'       { @('--version') }
        'java'     { @('-version') }
        'javac'    { @('-version') }
        'winget'   { @('--version') }
        'wsl'      { @('--version') }
        'code'     { @('--version') }
        'claude'   { @('--version') }
        default    { @('--version') }
    }

    try {
        # Run version command with timeout to avoid hanging on Windows Store aliases
        # (py.exe, python.exe in WindowsApps are stubs that hang indefinitely)
        $job = Start-Job -ScriptBlock {
            param($p, $a)
            & $p @a 2>&1 | Out-String
        } -ArgumentList $Path, $versionArgs

        $completed = $job | Wait-Job -Timeout 5
        if (-not $completed) {
            $job | Stop-Job
            $job | Remove-Job -Force
            return $null
        }

        $output = $job | Receive-Job
        $job | Remove-Job -Force

        # Match semver-like patterns: 2.47.1, 20.11.0, 1.9.2
        if ($output -match '(\d+\.\d+(?:\.\d+)+)') {
            return $Matches[1]
        }
        # Fallback: two-part version (e.g., winget v1.9, node v20.11)
        if ($output -match '(\d+\.\d+)') {
            return $Matches[1]
        }
        return $null
    } catch {
        return $null
    }
}

# ---------------------------------------------------------------------------
# Test-Tool -- generic tool check
# ---------------------------------------------------------------------------

function Test-Tool {
    <#
    .SYNOPSIS
        Checks whether a CLI tool is available and extracts its version.
    .OUTPUTS
        @{ Met=[bool]; Version=[string|$null]; Path=[string|$null] }
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $cmd = _ResolveCommand $Name
    if (-not $cmd) {
        return @{ Met = $false; Version = $null; Path = $null }
    }

    $toolPath = $cmd.Source
    $version  = _ExtractVersion -Tool $Name -Path $toolPath

    return @{ Met = $true; Version = $version; Path = $toolPath }
}

# ---------------------------------------------------------------------------
# Windows feature checks
# ---------------------------------------------------------------------------

function Test-HyperV {
    <#
    .SYNOPSIS
        Checks if Hyper-V is enabled.
    .OUTPUTS
        @{ Met=[bool]; State=[string] }
    #>
    try {
        # Get-WindowsOptionalFeature requires elevation; fall back to registry
        $feature = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online -ErrorAction Stop
        $state = $feature.State.ToString()
        return @{ Met = ($state -eq 'Enabled'); State = $state }
    } catch {
        # Fallback: registry check (works without elevation)
        try {
            $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'
            if (Test-Path $regPath) {
                return @{ Met = $true; State = 'Enabled' }
            }
            return @{ Met = $false; State = 'Disabled' }
        } catch {
            return @{ Met = $false; State = 'Unknown' }
        }
    }
}

function Test-WSL2 {
    <#
    .SYNOPSIS
        Checks if WSL 2 is available and returns version info.
    .OUTPUTS
        @{ Met=[bool]; Version=[string|$null] }
    #>
    $cmd = _ResolveCommand 'wsl'
    if (-not $cmd) {
        return @{ Met = $false; Version = $null }
    }

    try {
        $output = & wsl --version 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            return @{ Met = $false; Version = $null }
        }
        $version = $null
        if ($output -match 'WSL.*?:\s*(\d+\.\d+[\.\d]*)') {
            $version = $Matches[1]
        } elseif ($output -match '(\d+\.\d+[\.\d]*)') {
            $version = $Matches[1]
        }
        return @{ Met = $true; Version = $version }
    } catch {
        return @{ Met = $false; Version = $null }
    }
}

function Test-Virtualization {
    <#
    .SYNOPSIS
        Checks if hardware virtualization (VT-x / AMD-V) is enabled.
    .OUTPUTS
        @{ Met=[bool]; Source=[string] }
    #>
    try {
        $proc = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop |
                Select-Object -First 1
        if ($proc.VirtualizationFirmwareEnabled) {
            return @{ Met = $true; Source = 'BIOS' }
        }
        return @{ Met = $false; Source = 'BIOS' }
    } catch {
        return @{ Met = $false; Source = 'Unknown' }
    }
}

function Test-DeveloperMode {
    <#
    .SYNOPSIS
        Checks if Windows Developer Mode is enabled.
    .OUTPUTS
        @{ Met=[bool] }
    #>
    try {
        $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
        if (-not (Test-Path $regPath)) {
            return @{ Met = $false }
        }
        $val = Get-ItemProperty -Path $regPath -Name AllowDevelopmentWithoutDevLicense -ErrorAction Stop
        return @{ Met = ($val.AllowDevelopmentWithoutDevLicense -eq 1) }
    } catch {
        return @{ Met = $false }
    }
}

function Test-WindowsVersion {
    <#
    .SYNOPSIS
        Checks if Windows build meets minimum requirement (19041 = Windows 10 2004).
    .OUTPUTS
        @{ Met=[bool]; Build=[int]; MinRequired=[int] }
    #>
    param(
        [int]$MinBuild = 19041
    )

    $build = [Environment]::OSVersion.Version.Build
    return @{
        Met         = ($build -ge $MinBuild)
        Build       = $build
        MinRequired = $MinBuild
    }
}

# ---------------------------------------------------------------------------
# Claude-specific checks
# ---------------------------------------------------------------------------

function Test-ClaudeAuth {
    <#
    .SYNOPSIS
        Checks if Claude Code authentication is configured.
    .OUTPUTS
        @{ Met=[bool] }
    #>
    $userHome = [Environment]::GetFolderPath('UserProfile')

    # Check ~/.claude.json (legacy auth file)
    $legacyAuth = Join-Path $userHome '.claude.json'
    if (Test-Path $legacyAuth) {
        try {
            $json = Get-Content $legacyAuth -Raw | ConvertFrom-Json
            if ($json.sessionKey -or $json.apiKey -or $json.oauthToken) {
                return @{ Met = $true }
            }
        } catch {
            # Malformed JSON -- treat as not authenticated
        }
    }

    # Check ~/.claude/ for auth or credentials files (including dotfiles)
    $claudeDir = Join-Path $userHome '.claude'
    if (Test-Path $claudeDir) {
        $authFiles = Get-ChildItem -Path $claudeDir -Filter 'auth*' -File -Force -ErrorAction SilentlyContinue
        $credFiles = Get-ChildItem -Path $claudeDir -Filter 'credentials*' -File -Force -ErrorAction SilentlyContinue
        $dotCredFiles = Get-ChildItem -Path $claudeDir -Filter '.credentials*' -File -Force -ErrorAction SilentlyContinue
        if ($authFiles -or $credFiles -or $dotCredFiles) {
            return @{ Met = $true }
        }
    }

    return @{ Met = $false }
}

function Test-ClaudeSkill {
    <#
    .SYNOPSIS
        Checks if a named Claude Code skill is installed.
    .OUTPUTS
        @{ Met=[bool]; Path=[string|$null] }
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $userHome = [Environment]::GetFolderPath('UserProfile')
    $skillPath = Join-Path $userHome '.claude' 'skills' $Name 'SKILL.md'

    if (Test-Path $skillPath) {
        return @{ Met = $true; Path = $skillPath }
    }
    return @{ Met = $false; Path = $null }
}

function Test-ClaudeMCP {
    <#
    .SYNOPSIS
        Checks if a named MCP server is configured in Claude Code settings.
    .OUTPUTS
        @{ Met=[bool] }
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $userHome = [Environment]::GetFolderPath('UserProfile')

    # Check global settings
    $settingsPath = Join-Path $userHome '.claude' 'settings.json'
    if (Test-Path $settingsPath) {
        try {
            $json = Get-Content $settingsPath -Raw | ConvertFrom-Json
            if ($json.mcpServers -and $json.mcpServers.PSObject.Properties.Name -contains $Name) {
                return @{ Met = $true }
            }
        } catch {
            # Malformed JSON
        }
    }

    # Check local settings (project-scoped)
    $localSettings = Join-Path $userHome '.claude' 'settings.local.json'
    if (Test-Path $localSettings) {
        try {
            $json = Get-Content $localSettings -Raw | ConvertFrom-Json
            if ($json.mcpServers -and $json.mcpServers.PSObject.Properties.Name -contains $Name) {
                return @{ Met = $true }
            }
        } catch {
            # Malformed JSON
        }
    }

    return @{ Met = $false }
}

# ---------------------------------------------------------------------------
# Docker-specific checks
# ---------------------------------------------------------------------------

function Test-DockerRunning {
    <#
    .SYNOPSIS
        Checks if the Docker daemon is responsive.
    .OUTPUTS
        @{ Met=[bool] }
    #>
    $cmd = _ResolveCommand 'docker'
    if (-not $cmd) {
        return @{ Met = $false }
    }

    try {
        $null = & docker info 2>&1
        return @{ Met = ($LASTEXITCODE -eq 0) }
    } catch {
        return @{ Met = $false }
    }
}

function Test-DockerWSLBackend {
    <#
    .SYNOPSIS
        Checks if Docker Desktop is configured to use the WSL 2 backend.
    .OUTPUTS
        @{ Met=[bool] }
    #>
    $settingsPath = Join-Path $env:APPDATA 'Docker' 'settings.json'
    if (-not (Test-Path $settingsPath)) {
        return @{ Met = $false }
    }

    try {
        $json = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $enabled = $json.wslEngineEnabled
        return @{ Met = ($enabled -eq $true) }
    } catch {
        return @{ Met = $false }
    }
}

# ---------------------------------------------------------------------------
# Credential checks
# ---------------------------------------------------------------------------

function Test-Credential {
    <#
    .SYNOPSIS
        Checks if a named credential exists in Windows Credential Manager.
    .OUTPUTS
        @{ Met=[bool] }
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        $output = & cmdkey /list 2>&1 | Out-String
        # cmdkey lists entries as "Target: <name>"
        $found = $output -match [regex]::Escape($Name)
        return @{ Met = [bool]$found }
    } catch {
        return @{ Met = $false }
    }
}

# ---------------------------------------------------------------------------
# Composite: Get-PreflightStatus
# ---------------------------------------------------------------------------

function Get-PreflightStatus {
    <#
    .SYNOPSIS
        Runs core tool and environment checks. Returns an array of result objects.
    .OUTPUTS
        Array of @{ Name=[string]; Met=[bool]; Version=[string|$null]; Detail=[string|$null] }
    #>
    $results = [System.Collections.ArrayList]::new()

    # Core tools
    $coreTools = @('git', 'gh', 'docker', 'winget', 'code')
    foreach ($tool in $coreTools) {
        $check = Test-Tool $tool
        $null = $results.Add(@{
            Name    = $tool
            Met     = $check.Met
            Version = $check.Version
            Detail  = if ($check.Met) { $check.Path } else { 'Not found' }
        })
    }

    # Windows version
    $winVer = Test-WindowsVersion
    $null = $results.Add(@{
        Name    = 'WindowsVersion'
        Met     = $winVer.Met
        Version = "$($winVer.Build)"
        Detail  = "Min required: $($winVer.MinRequired)"
    })

    # Docker running
    $dockerRun = Test-DockerRunning
    $null = $results.Add(@{
        Name    = 'DockerRunning'
        Met     = $dockerRun.Met
        Version = $null
        Detail  = if ($dockerRun.Met) { 'Daemon responsive' } else { 'Daemon not responding' }
    })

    # Claude auth
    $claudeAuth = Test-ClaudeAuth
    $null = $results.Add(@{
        Name    = 'ClaudeAuth'
        Met     = $claudeAuth.Met
        Version = $null
        Detail  = if ($claudeAuth.Met) { 'Authenticated' } else { 'Not authenticated' }
    })

    return $results.ToArray()
}
