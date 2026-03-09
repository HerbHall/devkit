#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Distributes secrets from ~/.devkit-config.json to GitHub repos.

.DESCRIPTION
    Distributes secrets to GitHub/Gitea repos as Actions secrets.

    Secret sources (checked in order):
    1. If ~/.devkit-config.json .Secrets block contains a _note field
       (vault migration marker), reads from user-level environment
       variables populated by the HomeLabVault via sync-secrets.
    2. Otherwise reads directly from the .Secrets block (legacy path).

.PARAMETER Repo
    Push secrets to a single repo (e.g. HerbHall/myproject).

.PARAMETER All
    Push secrets to all repos under the GitHub user in ~/.devkit-config.json.
    This is the default when no parameter is specified.

.EXAMPLE
    .\Set-DevkitSecrets.ps1 -Repo HerbHall/myproject

.EXAMPLE
    .\Set-DevkitSecrets.ps1 -All

.EXAMPLE
    .\Set-DevkitSecrets.ps1
#>
[CmdletBinding(DefaultParameterSetName = 'All')]
param(
    [Parameter(ParameterSetName = 'Single', Mandatory)]
    [string]$Repo,

    [Parameter(ParameterSetName = 'All')]
    [switch]$All
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..' 'setup' 'lib' 'forge-wrappers.ps1')

# ---------------------------------------------------------------------------
# Load config
# ---------------------------------------------------------------------------

$configFile = Join-Path $HOME '.devkit-config.json'

if (-not (Test-Path $configFile)) {
    Write-Error "Config file not found: $configFile"
    exit 1
}

$config = $null
try {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse ${configFile}: $_"
    exit 1
}

if (-not $config.PSObject.Properties['Secrets']) {
    Write-Error "No .Secrets block found in $configFile"
    exit 1
}

$secrets = $config.Secrets

# ---------------------------------------------------------------------------
# If the Secrets block has been migrated to the vault (contains _note field),
# fall back to reading secrets from environment variables instead.
# ---------------------------------------------------------------------------
$useEnvVars = $false
if ($null -ne $secrets -and $secrets.PSObject.Properties['_note']) {
    Write-Host 'Secrets block migrated to vault -- reading from environment variables'
    $useEnvVars = $true

    # Map: GitHub Actions secret name -> environment variable name
    $envMapping = @{
        'RELEASE_PLEASE_TOKEN'   = 'GITHUB_TOKEN'
        'GITHUB_MCP_TOKEN'       = 'GITHUB_MCP_TOKEN'
        'HOME_ASSISTANT_TOKEN'   = 'HOME_ASSISTANT_TOKEN'
        'CLOUDFLARE_API_TOKEN'   = 'CLOUDFLARE_API_TOKEN'
        'GITEA_ACCESS_TOKEN'     = 'GITEA_TOKEN'
        'SAMVERK_AUTH_TOKEN'     = 'SAMVERK_AUTH_TOKEN'
        'ANTHROPIC_API_KEY'      = 'ANTHROPIC_API_KEY'
        'GITEA_DISPATCHER_TOKEN' = 'GITEA_DISPATCHER_TOKEN'
    }

    # Build a secrets hashtable from env vars
    $resolvedSecrets = @{}
    foreach ($pair in $envMapping.GetEnumerator()) {
        $val = [System.Environment]::GetEnvironmentVariable($pair.Value, 'User')
        if (-not [string]::IsNullOrWhiteSpace($val)) {
            $resolvedSecrets[$pair.Key] = $val
        }
    }

    if ($resolvedSecrets.Count -eq 0) {
        Write-Error "No secrets found in environment variables. Run sync-secrets in PowerShell 7 to push vault to env vars."
        exit 1
    }

    $secretNames = @($resolvedSecrets.Keys)
    Write-Host "Secrets to distribute (from env): $($secretNames -join ', ')"
} else {
    # Legacy path: read directly from .Secrets block in config file
    if ($null -eq $secrets -or $secrets.PSObject.Properties.Count -eq 0) {
        Write-Error "The .Secrets block in $configFile must be a non-null object with at least one property"
        exit 1
    }
    $secretNames = @($secrets.PSObject.Properties.Name)

    if ($secretNames.Count -eq 0) {
        Write-Warning 'No secrets defined in .Secrets block -- nothing to do'
        exit 0
    }

    Write-Host "Secrets to distribute: $($secretNames -join ', ')"
}

# ---------------------------------------------------------------------------
# Resolve target repos
# ---------------------------------------------------------------------------

$repos = @()

if ($PSCmdlet.ParameterSetName -eq 'Single') {
    $repos = @($Repo)
} else {
    # Determine GitHub user from config
    $githubUser = $null
    if ($config.PSObject.Properties['GitHubUser'] -and $config.GitHubUser) {
        $githubUser = $config.GitHubUser
    }

    if (-not $githubUser) {
        # Fall back to gh auth
        $githubUser = (& gh api user --jq '.login' 2>&1).Trim()
        if ($LASTEXITCODE -ne 0 -or -not $githubUser) {
            Write-Error 'Could not determine GitHub user. Set .GitHubUser in ~/.devkit-config.json or run gh auth login.'
            exit 1
        }
    }

    Write-Host "GitHub user: $githubUser"
    Write-Host 'Fetching repo list...'

    # Use gh api with pagination to fetch all repositories for the user.
    # full_name has the "owner/name" format equivalent to nameWithOwner.
    # Isolate stderr so error messages don't mix with repo names in $repoOutput.
    $tmpErr = [System.IO.Path]::GetTempFileName()
    try {
        $repoOutput = & gh api "users/$githubUser/repos" --paginate --jq '.[].full_name' 2>$tmpErr | Out-String
        if ($LASTEXITCODE -ne 0) {
            $stderrMsg = Get-Content $tmpErr -Raw -ErrorAction SilentlyContinue
            Write-Error "gh api failed while fetching repos: $stderrMsg"
            exit 1
        }
    } finally {
        Remove-Item $tmpErr -ErrorAction SilentlyContinue
    }

    # Split the output into individual repo names, trimming empty lines.
    $repos = @(
        $repoOutput -split "(`r`n|`n|`r)" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' }
    )

    if ($repos.Count -eq 0) {
        Write-Warning 'No repos found'
        exit 0
    }

    Write-Host "Found $($repos.Count) repos"
}

# ---------------------------------------------------------------------------
# Distribute secrets
# ---------------------------------------------------------------------------

$ok    = 0
$fail  = 0
$skip  = 0

foreach ($targetRepo in $repos) {
    Write-Host "`n  $targetRepo"

    foreach ($secretName in $secretNames) {
        $secretValue = if ($useEnvVars) { $resolvedSecrets[$secretName] } else { $secrets.$secretName }

        if ([string]::IsNullOrWhiteSpace($secretValue)) {
            Write-Warning "    $secretName -- empty value, skipping"
            $skip++
            continue
        }

        try {
            Set-ForgeSecret -Repo $targetRepo -SecretName $secretName -SecretValue $secretValue
            Write-Host "    [OK] $secretName"
            $ok++
        } catch {
            Write-Warning "    [FAIL] $secretName -- $_"
            $fail++
        }
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host "Done. OK: $ok  Failed: $fail  Skipped: $skip"

if ($fail -gt 0) {
    exit 1
}
