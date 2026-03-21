#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates missing .devkit.json enrollment markers across all DevSpace projects.

.DESCRIPTION
    Discovers all git projects under devspacePath (2-level: direct and family-folder).
    For each project missing .devkit.json, creates the marker with auto-detected
    profile (stack), family (parent directory), and current devkit version.

    Run with -DryRun first to preview. Run without -DryRun to write files.
    After running, commit the .devkit.json in each project's repo individually.

.PARAMETER DryRun
    Preview changes without writing any files.

.PARAMETER Force
    Overwrite existing .devkit.json files (default: skip existing).

.EXAMPLE
    pwsh scripts/Repair-DevkitEnrollment.ps1 -DryRun
    pwsh scripts/Repair-DevkitEnrollment.ps1
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

$configPath = Join-Path $HOME '.devkit-config.json'
if (-not (Test-Path $configPath)) {
    Write-Error "~/.devkit-config.json not found"
    exit 1
}
$config = Get-Content $configPath -Raw | ConvertFrom-Json
$devspacePath = $config.devspacePath

$versionFile = Join-Path $PSScriptRoot '..' 'VERSION'
$devkitVersion = (Get-Content $versionFile -Raw -ErrorAction SilentlyContinue).Trim()
if (-not $devkitVersion) { $devkitVersion = 'unknown' }

$today = (Get-Date).ToString('yyyy-MM-dd')

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Get-ProjectProfile {
    param([string]$ProjectPath)
    $stacks = @()
    if (Test-Path (Join-Path $ProjectPath 'go.mod')) { $stacks += 'go' }
    if (Test-Path (Join-Path $ProjectPath 'package.json')) { $stacks += 'node' }
    if (Test-Path (Join-Path $ProjectPath 'Cargo.toml')) { $stacks += 'rust' }
    # Check root and one level deep for .csproj (handles src/ layout)
    $csprojFound = @(Get-ChildItem -Path $ProjectPath -Filter '*.csproj' -Recurse -Depth 2 -ErrorAction SilentlyContinue)
    if ($csprojFound.Count -gt 0) { $stacks += 'dotnet' }
    # Docker Desktop extension detection
    $metadataJson = Join-Path $ProjectPath 'metadata.json'
    if ((Test-Path $metadataJson) -and (Test-Path (Join-Path $ProjectPath 'Dockerfile'))) {
        # Replace node with node-extension if it has Docker extension metadata
        $stacks = @($stacks | Where-Object { $_ -ne 'node' })
        $stacks += 'node-extension'
    }
    if ($stacks.Count -eq 0) { return 'unknown' }
    return ($stacks -join '-')
}

function Write-Step { param([string]$msg) Write-Host "  $msg" }
function Write-OK   { param([string]$msg) Write-Host "  [+] $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  [~] $msg" -ForegroundColor Yellow }
function Write-Skip { param([string]$msg) Write-Host "  [-] $msg" -ForegroundColor DarkGray }

# ---------------------------------------------------------------------------
# Discover projects (2-level)
# ---------------------------------------------------------------------------

$excludedFamilies = @('.templates', '.shared-vscode', '.coordination', 'research', 'archive')
$projects = @()

foreach ($familyDir in Get-ChildItem -Path $devspacePath -Directory) {
    if ($excludedFamilies -contains $familyDir.Name) { continue }

    # Direct project (family IS the project)
    if (Test-Path (Join-Path $familyDir.FullName '.git')) {
        $projects += [PSCustomObject]@{
            Name   = $familyDir.Name
            Path   = $familyDir.FullName
            Family = (Split-Path $devspacePath -Leaf)
        }
        continue
    }

    # Family folder — scan children
    foreach ($projDir in Get-ChildItem -Path $familyDir.FullName -Directory -ErrorAction SilentlyContinue) {
        if (Test-Path (Join-Path $projDir.FullName '.git')) {
            $projects += [PSCustomObject]@{
                Name   = $projDir.Name
                Path   = $projDir.FullName
                Family = $familyDir.Name
            }
        }
    }
}

Write-Host ""
Write-Host "Repair DevKit Enrollment" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor DarkGray
Write-Host "  DevSpace:       $devspacePath"
Write-Host "  DevKit version: $devkitVersion"
Write-Host "  Projects found: $($projects.Count)"
if ($DryRun) { Write-Host "  Mode:           DRY-RUN (no files written)" -ForegroundColor Yellow }
Write-Host ""

$created = 0
$skipped = 0
$updated = 0

foreach ($proj in $projects) {
    $markerPath = Join-Path $proj.Path '.devkit.json'
    $exists     = Test-Path $markerPath
    $profile    = Get-ProjectProfile -ProjectPath $proj.Path

    if ($exists -and -not $Force) {
        Write-Skip "$($proj.Family)/$($proj.Name) — already enrolled (skip, use -Force to overwrite)"
        $skipped++
        continue
    }

    $marker = [ordered]@{
        project        = $proj.Name
        tier           = 'full'
        profile        = $profile
        family         = $proj.Family
        managed_by     = $null
        created        = $today
        devkit_version = $devkitVersion
    }

    $json = $marker | ConvertTo-Json -Depth 2

    if ($DryRun) {
        if ($exists) {
            Write-Warn "$($proj.Family)/$($proj.Name) — would UPDATE .devkit.json (profile: $profile)"
        } else {
            Write-OK "$($proj.Family)/$($proj.Name) — would CREATE .devkit.json (profile: $profile)"
        }
    } else {
        Set-Content -Path $markerPath -Value $json -Encoding UTF8
        if ($exists) {
            Write-Warn "$($proj.Family)/$($proj.Name) — UPDATED .devkit.json"
            $updated++
        } else {
            Write-OK "$($proj.Family)/$($proj.Name) — CREATED .devkit.json"
            $created++
        }
    }
}

Write-Host ""
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "-------" -ForegroundColor DarkGray
if ($DryRun) {
    Write-Host "  Would create: $($projects.Count - $skipped)"
    Write-Host "  Would skip:   $skipped (already enrolled)"
} else {
    Write-Host "  Created: $created"
    Write-Host "  Updated: $updated"
    Write-Host "  Skipped: $skipped"
    if ($created -gt 0 -or $updated -gt 0) {
        Write-Host ""
        Write-Host "Next: commit .devkit.json in each project repo individually." -ForegroundColor Yellow
        Write-Host "  git -C <project> add .devkit.json && git -C <project> commit -m 'chore: add DevKit enrollment marker'"
    }
}
