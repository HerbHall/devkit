# forge-wrappers.ps1 -- PowerShell forge abstraction layer for DevKit scripts.
#
# Dot-source this file to get portable wrapper functions that work with
# both GitHub (gh CLI) and Gitea (REST API via token).
#
# Usage:
#   . "$PSScriptRoot\forge-wrappers.ps1"
#   $forge = Get-ForgeType
#   New-ForgeRepo -Owner 'me' -Name 'my-project' -Private -SourceDir '.'
#
# Gitea prerequisites (one-time machine setup):
#   Set forge.primary = "gitea" and forge.giteaUrl in ~/.devkit-config.json
#   Optionally set forge.giteaToken (falls back to GITEA_TOKEN env var)
#   Run: tea login add --name <name> --url <url> --token <token>
#
# See docs/forge-abstraction.md for the full specification.

# ---------------------------------------------------------------------------
# Get-ForgeType -- Identify the forge from git remote or config override
# ---------------------------------------------------------------------------
function Get-ForgeType {
    [OutputType([string])]
    param()

    # Check config override first
    $config = Join-Path $env:USERPROFILE '.devkit-config.json'
    if (Test-Path $config) {
        try {
            $cfg = Get-Content $config -Raw | ConvertFrom-Json
            $override = $cfg.forge.primary
            if ($override) { return $override }
        } catch { }
    }

    # Auto-detect from git remote
    try {
        $url = & git remote get-url origin 2>$null
        if ($url -match 'github\.com') { return 'github' }
    } catch { }

    return 'gitea'
}

# ---------------------------------------------------------------------------
# Get-GiteaConfig -- Read Gitea URL and token from config / environment
# ---------------------------------------------------------------------------
function Get-GiteaConfig {
    [OutputType([hashtable])]
    param()

    $url   = $null
    $token = $null

    $config = Join-Path $env:USERPROFILE '.devkit-config.json'
    if (Test-Path $config) {
        try {
            $cfg   = Get-Content $config -Raw | ConvertFrom-Json
            $url   = $cfg.forge.giteaUrl
            $token = $cfg.forge.giteaToken
        } catch { }
    }

    if (-not $token) { $token = $env:GITEA_TOKEN }

    if (-not $url) {
        Write-Warning '[forge] forge.giteaUrl is not set in ~/.devkit-config.json'
    }
    if (-not $token) {
        Write-Warning '[forge] forge.giteaToken is not set. Set it in ~/.devkit-config.json or GITEA_TOKEN env var'
    }

    return @{ Url = $url; Token = $token }
}

# ---------------------------------------------------------------------------
# Invoke-GiteaApi -- Call Gitea REST API
#   -Path: API path (e.g. '/api/v1/user/repos')
#   -Method: HTTP method (default: GET)
#   -Body: hashtable for JSON body (optional)
# ---------------------------------------------------------------------------
function Invoke-GiteaApi {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [string]$Method = 'GET',
        [hashtable]$Body
    )

    $cfg = Get-GiteaConfig
    if (-not $cfg.Url -or -not $cfg.Token) {
        throw '[forge] Cannot call Gitea API: missing URL or token'
    }

    $uri     = $cfg.Url.TrimEnd('/') + $Path
    $headers = @{ Authorization = "token $($cfg.Token)"; 'Content-Type' = 'application/json' }

    $params = @{ Uri = $uri; Method = $Method; Headers = $headers; ErrorAction = 'Stop' }
    if ($Body) { $params.Body = $Body | ConvertTo-Json -Compress }

    return Invoke-RestMethod @params
}

# ---------------------------------------------------------------------------
# New-ForgeRepo -- Create a remote repository and push initial commit
#   -Owner:     GitHub user / Gitea user or org
#   -Name:      Repository name
#   -Private:   Make repository private (switch)
#   -SourceDir: Local directory to push as initial commit
# ---------------------------------------------------------------------------
function New-ForgeRepo {
    param(
        [Parameter(Mandatory)] [string]$Owner,
        [Parameter(Mandatory)] [string]$Name,
        [switch]$Private,
        [string]$SourceDir = '.'
    )

    $forge = Get-ForgeType

    switch ($forge) {
        'github' {
            Push-Location $SourceDir
            try {
                $visibility = if ($Private) { '--private' } else { '--public' }
                $null = & gh repo create "$Owner/$Name" $visibility --source . --remote origin --push 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "gh repo create failed (exit $LASTEXITCODE)"
                }
                Write-Host "[forge] GitHub repo created: https://github.com/$Owner/$Name"
            } finally {
                Pop-Location
            }
        }
        'gitea' {
            $body = @{ name = $Name; private = [bool]$Private; auto_init = $false }
            $null = Invoke-GiteaApi -Path "/api/v1/user/repos" -Method POST -Body $body
            $cfg  = Get-GiteaConfig
            $url  = "$($cfg.Url.TrimEnd('/'))/$Owner/$Name.git"
            Push-Location $SourceDir
            try {
                $null = & git remote add origin $url 2>&1
                $null = & git push -u origin HEAD 2>&1
                if ($LASTEXITCODE -ne 0) { throw "git push failed (exit $LASTEXITCODE)" }
                Write-Host "[forge] Gitea repo created: $($cfg.Url.TrimEnd('/'))/$Owner/$Name"
            } finally {
                Pop-Location
            }
        }
        default { throw "[forge] Unknown forge type: $forge" }
    }
}

# ---------------------------------------------------------------------------
# New-ForgeLabel -- Create a label on a repository
#   -Repo:        'owner/name'
#   -LabelName:   Label name
#   -Color:       Hex color without # (e.g. 'e11d48')
#   -Description: Optional description
# ---------------------------------------------------------------------------
function New-ForgeLabel {
    param(
        [Parameter(Mandatory)] [string]$Repo,
        [Parameter(Mandatory)] [string]$LabelName,
        [Parameter(Mandatory)] [string]$Color,
        [string]$Description = ''
    )

    $forge = Get-ForgeType

    switch ($forge) {
        'github' {
            $labelArgs = @('label', 'create', $LabelName, '--repo', $Repo, '--color', $Color)
            if ($Description) { $labelArgs += @('--description', $Description) }
            $null = & gh @labelArgs 2>&1
        }
        'gitea' {
            $parts = $Repo -split '/'
            if ($parts.Count -ne 2) { throw "[forge] Repo must be 'owner/name', got: $Repo" }
            $owner = $parts[0]; $name = $parts[1]
            $body  = @{ name = $LabelName; color = "#$Color"; description = $Description }
            $null  = Invoke-GiteaApi -Path "/api/v1/repos/$owner/$name/labels" -Method POST -Body $body
        }
        default { throw "[forge] Unknown forge type: $forge" }
    }
}

# ---------------------------------------------------------------------------
# Set-ForgeSecret -- Set an Actions secret on a repository
#   -Repo:        'owner/name'
#   -SecretName:  Secret key name
#   -SecretValue: Secret value (plaintext, never logged)
# ---------------------------------------------------------------------------
function Set-ForgeSecret {
    param(
        [Parameter(Mandatory)] [string]$Repo,
        [Parameter(Mandatory)] [string]$SecretName,
        [Parameter(Mandatory)] [string]$SecretValue
    )

    $forge = Get-ForgeType

    switch ($forge) {
        'github' {
            $result = ($SecretValue | & gh secret set $SecretName --repo $Repo 2>&1)
            if ($LASTEXITCODE -ne 0) {
                throw "[forge] gh secret set failed: $result"
            }
        }
        'gitea' {
            $parts = $Repo -split '/'
            if ($parts.Count -ne 2) { throw "[forge] Repo must be 'owner/name', got: $Repo" }
            $owner = $parts[0]; $name = $parts[1]
            # Gitea Actions secrets API: PUT /api/v1/repos/{owner}/{repo}/actions/secrets/{secretname}
            $body  = @{ data = $SecretValue }
            $null  = Invoke-GiteaApi -Path "/api/v1/repos/$owner/$name/actions/secrets/$SecretName" -Method PUT -Body $body
        }
        default { throw "[forge] Unknown forge type: $forge" }
    }
}
