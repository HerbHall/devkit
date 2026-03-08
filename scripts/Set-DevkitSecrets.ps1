#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Distributes secrets from ~/.devkit-config.json to GitHub repos.

.DESCRIPTION
    Reads the .Secrets block from ~/.devkit-config.json and pushes each
    key/value pair as a GitHub Actions secret to one or all repos owned
    by the configured GitHub user.

    Replaces the one-off D:\DevSpace\scripts\Set-ReleasePleaseToken.ps1.

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

# Validate that .Secrets is a non-null object with at least one property
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
    # Stderr is redirected to a temp file so it cannot corrupt the stdout output;
    # it is only included in the error message when the command fails.
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
        $secretValue = $secrets.$secretName

        if ([string]::IsNullOrWhiteSpace($secretValue)) {
            Write-Warning "    $secretName -- empty value, skipping"
            $skip++
            continue
        }

        try {
            $result = ($secretValue | & gh secret set $secretName --repo $targetRepo 2>&1)
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    [OK] $secretName"
                $ok++
            } else {
                Write-Warning "    [FAIL] $secretName -- $result"
                $fail++
            }
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
