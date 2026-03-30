<#
.SYNOPSIS
    Syncs VS Code extension recommendations in .code-workspace files with DevKit stack fragments.

.DESCRIPTION
    For each registered project, detects the stack, loads the matching fragment from
    devspace/shared-vscode/extensions.jsonc, and merges the recommended extensions into the
    project's .code-workspace file — preserving any project-specific additions not in the fragment.

    Updates vscodeWorkspace.lastSynced and vscodeWorkspace.stackProfile in ~/.devkit-registry.json.

.PARAMETER DevkitRoot
    Path to the DevKit repo root. Defaults to the directory containing this script's parent.

.PARAMETER RegistryPath
    Path to the devkit registry JSON. Defaults to ~/.devkit-registry.json.

.PARAMETER ProjectPath
    Limit sync to a single project at this path. Omit to sync all registered projects.

.PARAMETER WhatIf
    Preview changes without applying them.

.EXAMPLE
    # Dry run against all registered projects
    pwsh -File devkit/scripts/Sync-WorkspaceExtensions.ps1 -WhatIf

    # Apply to all projects
    pwsh -File devkit/scripts/Sync-WorkspaceExtensions.ps1

    # Apply to a specific project
    pwsh -File devkit/scripts/Sync-WorkspaceExtensions.ps1 -ProjectPath D:\DevSpace\SubNetree

.NOTES
    See docs/vscode-workspaces.md for the full workspace convention.
    This script is also the backend for the /workspace sync-all skill.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$DevkitRoot = '',
    [string]$RegistryPath = (Join-Path $env:USERPROFILE '.devkit-registry.json'),
    [string]$ProjectPath = '',
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -- Resolve DevKit root --
if (-not $DevkitRoot) {
    $scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
    $DevkitRoot = Split-Path -Parent $scriptDir
}

$extensionsFragment = Join-Path $DevkitRoot 'devspace\shared-vscode\extensions.jsonc'

# -- Helpers --

function Get-ExtensionsFragment {
    param([string]$FragmentPath)
    if (-not (Test-Path $FragmentPath)) {
        Write-Warning "Extensions fragment not found: $FragmentPath"
        return $null
    }
    $raw = Get-Content $FragmentPath -Raw
    # Strip JSONC comments
    $stripped = $raw -replace '//[^\r\n]*', '' -replace '/\*[\s\S]*?\*/', ''
    return $stripped | ConvertFrom-Json
}

function Detect-StackProfile {
    param([string]$Root)
    if (Test-Path (Join-Path $Root 'go.mod'))       { return 'go' }
    if (Test-Path (Join-Path $Root 'package.json')) { return 'typescript' }
    if (Test-Path (Join-Path $Root 'Cargo.toml'))   { return 'rust' }
    $csprojs = Get-ChildItem $Root -Filter '*.csproj' -ErrorAction SilentlyContinue
    if ($csprojs) { return 'csharp' }
    return 'base'
}

function Get-StackExtensions {
    param([object]$Fragment, [string]$Stack)
    $cmdArgs = [System.Collections.Generic.List[string]]::new()

    # Always add general extensions
    if ($Fragment.general) {
        foreach ($ext in $Fragment.general) { $cmdArgs.Add($ext) }
    }

    switch ($Stack) {
        'go'         { if ($Fragment.go)         { foreach ($e in $Fragment.go)         { $cmdArgs.Add($e) } } }
        'typescript' { if ($Fragment.typescript) { foreach ($e in $Fragment.typescript) { $cmdArgs.Add($e) } } }
        'csharp'     { if ($Fragment.csharp)     { foreach ($e in $Fragment.csharp)     { $cmdArgs.Add($e) } } }
        'docker'     { if ($Fragment.docker)     { foreach ($e in $Fragment.docker)     { $cmdArgs.Add($e) } } }
        # rust and base: general only
    }

    return $cmdArgs | Sort-Object -Unique
}

function Get-WorkspaceRecommendations {
    param([string]$WorkspacePath)
    try {
        $raw = Get-Content $WorkspacePath -Raw
        $stripped = $raw -replace '//[^\r\n]*', '' -replace '/\*[\s\S]*?\*/', ''
        $json = $stripped | ConvertFrom-Json
        if ($json.extensions -and $json.extensions.recommendations) {
            return [string[]]$json.extensions.recommendations
        }
    }
    catch {
        Write-Warning "  Could not parse $WorkspacePath : $_"
    }
    return @()
}

function Set-WorkspaceRecommendations {
    param([string]$WorkspacePath, [string[]]$Recommendations)
    $raw = Get-Content $WorkspacePath -Raw
    # Strip JSONC comments for parsing
    $stripped = $raw -replace '//[^\r\n]*', '' -replace '/\*[\s\S]*?\*/', ''
    $json = $stripped | ConvertFrom-Json

    if (-not $json.extensions) {
        $json | Add-Member -NotePropertyName 'extensions' -NotePropertyValue ([PSCustomObject]@{ recommendations = @() })
    }
    $json.extensions.recommendations = $Recommendations

    # Write back as JSON (loses original comments, but that is acceptable for managed files)
    $json | ConvertTo-Json -Depth 10 | Set-Content $WorkspacePath -Encoding UTF8
}

function Update-Registry {
    param([string]$RegistryPath, [string]$ProjectPath, [string]$WorkspacePath, [string]$Stack)
    if (-not (Test-Path $RegistryPath)) { return }

    $registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
    $updated  = $false

    foreach ($project in $registry.projects) {
        if ($project.path -eq $ProjectPath) {
            if (-not $project.vscodeWorkspace) {
                $project | Add-Member -NotePropertyName 'vscodeWorkspace' -NotePropertyValue ([PSCustomObject]@{
                    path        = $WorkspacePath
                    lastSynced  = $null
                    stackProfile = $Stack
                })
            }
            $project.vscodeWorkspace.path         = $WorkspacePath
            $project.vscodeWorkspace.lastSynced   = (Get-Date -Format 'o')
            $project.vscodeWorkspace.stackProfile = $Stack
            $updated = $true
            break
        }
    }

    if ($updated) {
        $registry | ConvertTo-Json -Depth 10 | Set-Content $RegistryPath -Encoding UTF8
    }
}

# -- Load extensions fragment --
$fragment = Get-ExtensionsFragment $extensionsFragment
if ($null -eq $fragment) {
    Write-Error "Cannot load extensions fragment from $extensionsFragment. Aborting."
    exit 1
}

# -- Load registry --
if (-not (Test-Path $RegistryPath)) {
    Write-Error "Registry not found at $RegistryPath. Run devkit-sync to register projects first."
    exit 1
}
$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json

# -- Build project list --
$projects = if ($ProjectPath) {
    $registry.projects | Where-Object { $_.path -eq $ProjectPath }
}
else {
    $registry.projects
}

if (-not $projects) {
    Write-Warning "No projects found to sync."
    exit 0
}

# -- Sync --
Write-Host ''
Write-Host '== DevKit Workspace Extension Sync ==' -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host '   (dry run -- no changes will be made)' -ForegroundColor Yellow
}
Write-Host ''

$stats = @{ clean = 0; updated = 0; missing = 0; errors = 0 }

foreach ($project in $projects) {
    $root        = $project.path
    $projectName = Split-Path -Leaf $root

    if (-not (Test-Path $root)) {
        Write-Host "  [SKIP]    $root (path does not exist)" -ForegroundColor DarkYellow
        $stats.errors++
        continue
    }

    $wsPath = Join-Path $root "$projectName.code-workspace"

    if (-not (Test-Path $wsPath)) {
        Write-Host "  [MISSING] $wsPath" -ForegroundColor Yellow
        Write-Host "             -> Run Repair-WorkspaceFiles.ps1 to scaffold"
        $stats.missing++
        continue
    }

    $stack         = Detect-StackProfile $root
    $expected      = Get-StackExtensions $fragment $stack
    $current       = Get-WorkspaceRecommendations $wsPath

    # Merge: keep project-specific extensions not in the expected set
    $projectSpecific = $current | Where-Object { $_ -notin $expected }
    $merged          = ($expected + $projectSpecific) | Sort-Object -Unique

    $needsUpdate = ($null -eq (Compare-Object $current $merged))  # true = no diff = false
    $needsUpdate = ($current.Count -ne $merged.Count) -or
                   (($current | Sort-Object) -join '|') -ne (($merged | Sort-Object) -join '|')

    Write-Host "  $projectName" -NoNewline
    Write-Host "  (stack: $stack)" -ForegroundColor DarkGray

    if (-not $needsUpdate) {
        Write-Host "    [CLEAN]   extensions already up to date" -ForegroundColor Green
        $stats.clean++
    }
    else {
        $added   = $merged | Where-Object { $_ -notin $current }
        $removed = $current | Where-Object { $_ -notin $merged }

        if ($added)   { foreach ($e in $added)   { Write-Host "    + $e" -ForegroundColor Cyan } }
        if ($removed) { foreach ($e in $removed) { Write-Host "    - $e" -ForegroundColor Red  } }

        if (-not $WhatIf -and $PSCmdlet.ShouldProcess($wsPath, 'Update extension recommendations')) {
            try {
                Set-WorkspaceRecommendations $wsPath $merged
                Update-Registry $RegistryPath $root $wsPath $stack
                Write-Host "    [UPDATED] $wsPath" -ForegroundColor Cyan
                $stats.updated++
            }
            catch {
                Write-Warning "    [ERROR]   Could not update $wsPath : $_"
                $stats.errors++
            }
        }
        elseif ($WhatIf) {
            Write-Host "    [WOULD UPDATE] $wsPath" -ForegroundColor Cyan
            $stats.updated++
        }
    }
}

# -- Summary --
Write-Host ''
Write-Host '== Summary ==' -ForegroundColor Cyan
Write-Host "  Clean:   $($stats.clean)"
Write-Host "  Updated: $($stats.updated)" -ForegroundColor $(if ($stats.updated -gt 0) { 'Cyan' } else { 'White' })
Write-Host "  Missing: $($stats.missing)" -ForegroundColor $(if ($stats.missing -gt 0) { 'Yellow' } else { 'White' })
Write-Host "  Errors:  $($stats.errors)"  -ForegroundColor $(if ($stats.errors -gt 0)  { 'Red'    } else { 'White' })
Write-Host ''
