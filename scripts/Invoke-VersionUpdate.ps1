#Requires -Version 7.0
# scripts/Invoke-VersionUpdate.ps1 -- Tool version management for DevKit-managed projects.
#
# Modes:
#   -Mode Render      -- Render all src/ templates to project-templates/ using registry values
#   -Mode Bump        -- Update a tool version in registry then re-render
#   -Mode Rollback    -- Swap current <-> previous for a tool then re-render
#   -Mode Status      -- Print a table of all tools and their versions
#   -Mode Propagate   -- Scan projects under devspacePath and update outdated action versions
#
# Examples:
#   pwsh -File scripts/Invoke-VersionUpdate.ps1 -Mode Status
#   pwsh -File scripts/Invoke-VersionUpdate.ps1 -Mode Render
#   pwsh -File scripts/Invoke-VersionUpdate.ps1 -Mode Bump -Tool actions-checkout -Version v5
#   pwsh -File scripts/Invoke-VersionUpdate.ps1 -Mode Rollback -Tool actions-checkout
#   pwsh -File scripts/Invoke-VersionUpdate.ps1 -Mode Propagate -Projects all -DryRun

# ---------------------------------------------------------------------------
# Parameters
# ---------------------------------------------------------------------------

param(
    [Parameter(Mandatory)]
    [ValidateSet('Render', 'Bump', 'Rollback', 'Status', 'Propagate')]
    [string]$Mode,

    [Parameter()]
    [string]$Tool,

    [Parameter()]
    [string]$Version,

    [Parameter()]
    [string]$Projects = 'all',

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# UI helpers (replicated from setup/lib/ui.ps1 — standalone script)
# ---------------------------------------------------------------------------

$script:UseColor = $Host.UI.SupportsVirtualTerminal -or $null -ne $PSStyle

if ($script:UseColor) {
    $script:Esc    = [char]0x1B
    $script:Bold   = "${script:Esc}[1m"
    $script:Reset  = "${script:Esc}[0m"
    $script:Green  = "${script:Esc}[32m"
    $script:Yellow = "${script:Esc}[33m"
    $script:Red    = "${script:Esc}[31m"
    $script:Dim    = "${script:Esc}[2m"
} else {
    $script:Bold   = ''
    $script:Reset  = ''
    $script:Green  = ''
    $script:Yellow = ''
    $script:Red    = ''
    $script:Dim    = ''
}

$script:CheckMark = [char]0x2714
$script:CrossMark = [char]0x2718
$script:WarnMark  = [char]0x26A0

function Write-Section {
    param([Parameter(Mandatory, Position = 0)][string]$Title)
    $sep = '-' * [Math]::Min($Title.Length + 4, 72)
    Write-Host ''
    Write-Host "${script:Bold}${Title}${script:Reset}"
    Write-Host "${script:Dim}${sep}${script:Reset}"
}

function Write-Step {
    param([Parameter(Mandatory, Position = 0)][string]$Message)
    Write-Host "  $Message"
}

function Write-OK {
    param([Parameter(Mandatory, Position = 0)][string]$Message)
    Write-Host "  ${script:Green}${script:CheckMark}${script:Reset} $Message"
}

function Write-Warn {
    param([Parameter(Mandatory, Position = 0)][string]$Message)
    Write-Host "  ${script:Yellow}${script:WarnMark}${script:Reset} $Message"
}

function Write-Fail {
    param([Parameter(Mandatory, Position = 0)][string]$Message)
    Write-Host "  ${script:Red}${script:CrossMark}${script:Reset} $Message"
}

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot        = Split-Path -Parent $ScriptDir
$RegistryPath    = Join-Path $RepoRoot 'tool-registry.json'
$SrcDir          = Join-Path $RepoRoot 'project-templates' 'src'
$TemplatesDir    = Join-Path $RepoRoot 'project-templates'

# ---------------------------------------------------------------------------
# Registry helpers
# ---------------------------------------------------------------------------

function Read-Registry {
    if (-not (Test-Path $RegistryPath)) {
        Write-Fail "Registry not found: $RegistryPath"
        exit 1
    }
    return Get-Content $RegistryPath -Raw | ConvertFrom-Json
}

function Write-Registry {
    param([Parameter(Mandatory)][object]$Registry)
    $Registry | ConvertTo-Json -Depth 10 | Set-Content $RegistryPath -Encoding UTF8
}

function Get-TokenMap {
    param([Parameter(Mandatory)][object]$Registry)
    $map = @{}
    foreach ($prop in $Registry.tools.PSObject.Properties) {
        $tool = $prop.Value
        $map["{{$($tool.token)}}"] = $tool.current
    }
    return $map
}

function Get-Today {
    return (Get-Date -Format 'yyyy-MM-dd')
}

# ---------------------------------------------------------------------------
# Render: apply token map to all src/ files → project-templates/
# ---------------------------------------------------------------------------

function Invoke-Render {
    param([Parameter(Mandatory)][object]$Registry)

    $tokenMap = Get-TokenMap -Registry $Registry

    if (-not (Test-Path $SrcDir)) {
        Write-Fail "src/ directory not found: $SrcDir"
        exit 1
    }

    $srcFiles = Get-ChildItem -Path $SrcDir -File
    if ($srcFiles.Count -eq 0) {
        Write-Warn "No files found in $SrcDir"
        return
    }

    $rendered = 0
    $skipped  = 0

    foreach ($srcFile in $srcFiles) {
        $content = Get-Content $srcFile.FullName -Raw -Encoding UTF8

        $substitutions = 0
        foreach ($entry in $tokenMap.GetEnumerator()) {
            $token = $entry.Key
            $value = $entry.Value
            $newContent = $content -replace [regex]::Escape($token), $value
            if ($newContent -ne $content) {
                $substitutions++
                $content = $newContent
            }
        }

        $destPath = Join-Path $TemplatesDir $srcFile.Name
        Set-Content -Path $destPath -Value $content -Encoding UTF8 -NoNewline

        if ($substitutions -gt 0) {
            Write-OK "$($srcFile.Name) ($substitutions token(s) rendered)"
            $rendered++
        } else {
            Write-Step "$($srcFile.Name) (no tokens — copied as-is)"
            $skipped++
        }
    }

    Write-Host ''
    Write-Step "Rendered: $rendered  Passthrough: $skipped  Total: $($srcFiles.Count)"
}

# ---------------------------------------------------------------------------
# Status: print table of all tools
# ---------------------------------------------------------------------------

function Invoke-Status {
    param([Parameter(Mandatory)][object]$Registry)

    $rows = @()
    foreach ($prop in $Registry.tools.PSObject.Properties) {
        $tool = $prop.Value
        $rows += [PSCustomObject]@{
            ID       = $tool.id
            Token    = "{{$($tool.token)}}"
            Current  = $tool.current
            Previous = if ($null -ne $tool.previous) { $tool.previous } else { '-' }
        }
    }

    # Calculate column widths
    $idW   = ([int[]](@('ID') + $rows.ID   | ForEach-Object { $_.Length }) | Measure-Object -Maximum).Maximum
    $tokW  = ([int[]](@('Token') + $rows.Token   | ForEach-Object { $_.Length }) | Measure-Object -Maximum).Maximum
    $curW  = ([int[]](@('Current') + $rows.Current | ForEach-Object { $_.Length }) | Measure-Object -Maximum).Maximum
    $prevW = ([int[]](@('Previous') + $rows.Previous | ForEach-Object { $_.Length }) | Measure-Object -Maximum).Maximum

    $hdr = '  {0}  {1}  {2}  {3}' -f 'ID'.PadRight($idW), 'Token'.PadRight($tokW), 'Current'.PadRight($curW), 'Previous'.PadRight($prevW)
    Write-Host ''
    Write-Host "${script:Bold}${hdr}${script:Reset}"
    Write-Host "  $('-' * $idW)  $('-' * $tokW)  $('-' * $curW)  $('-' * $prevW)"

    foreach ($row in $rows) {
        $line = '  {0}  {1}  {2}  {3}' -f `
            $row.ID.PadRight($idW),
            $row.Token.PadRight($tokW),
            "${script:Green}$($row.Current.PadRight($curW))${script:Reset}",
            "${script:Dim}$($row.Previous.PadRight($prevW))${script:Reset}"
        Write-Host $line
    }
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Bump: update current version in registry
# ---------------------------------------------------------------------------

function Invoke-Bump {
    param(
        [Parameter(Mandatory)][object]$Registry,
        [Parameter(Mandatory)][string]$ToolId,
        [Parameter(Mandatory)][string]$NewVersion
    )

    if (-not $Registry.tools.PSObject.Properties[$ToolId]) {
        Write-Fail "Unknown tool ID: $ToolId"
        Write-Step "Available IDs:"
        foreach ($prop in $Registry.tools.PSObject.Properties) {
            Write-Step "  $($prop.Name)"
        }
        exit 1
    }

    $tool = $Registry.tools.$ToolId
    $oldCurrent  = $tool.current
    $oldPrevious = $tool.previous

    if ($oldCurrent -eq $NewVersion) {
        Write-Warn "$ToolId is already at $NewVersion — no change"
        return $false
    }

    # Rotate: old current → previous, new version → current
    $tool.previous     = $oldCurrent
    $tool.current      = $NewVersion
    $tool.last_updated = Get-Today

    Write-OK "${ToolId}: $oldCurrent -> $NewVersion (previous: $oldPrevious -> $oldCurrent)"
    return $true
}

# ---------------------------------------------------------------------------
# Rollback: swap current <-> previous
# ---------------------------------------------------------------------------

function Invoke-Rollback {
    param(
        [Parameter(Mandatory)][object]$Registry,
        [Parameter(Mandatory)][string]$ToolId
    )

    if (-not $Registry.tools.PSObject.Properties[$ToolId]) {
        Write-Fail "Unknown tool ID: $ToolId"
        exit 1
    }

    $tool = $Registry.tools.$ToolId

    if ($null -eq $tool.previous -or $tool.previous -eq '') {
        Write-Fail "$ToolId has no previous version to roll back to"
        exit 1
    }

    $oldCurrent  = $tool.current
    $oldPrevious = $tool.previous

    $tool.current      = $oldPrevious
    $tool.previous     = $oldCurrent
    $tool.last_updated = Get-Today

    Write-OK "${ToolId}: rolled back $oldCurrent -> $oldPrevious"
    return $true
}

# ---------------------------------------------------------------------------
# Propagate: scan project repos and open PRs for outdated version strings
# ---------------------------------------------------------------------------

function Invoke-Propagate {
    param(
        [Parameter(Mandatory)][object]$Registry,
        [Parameter(Mandatory)][string]$ProjectsArg,
        [Parameter(Mandatory)][bool]$IsDryRun
    )

    # Load devspacePath from ~/.devkit-config.json
    $configPath = Join-Path $HOME '.devkit-config.json'
    if (-not (Test-Path $configPath)) {
        Write-Fail "~/.devkit-config.json not found — cannot determine devspacePath"
        exit 1
    }

    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $devspacePath = $config.devspacePath
    if ([string]::IsNullOrWhiteSpace($devspacePath)) {
        Write-Fail "devspacePath not set in ~/.devkit-config.json"
        exit 1
    }

    # Resolve project dirs
    if ($ProjectsArg -eq 'all') {
        $projectDirs = Get-ChildItem -Path $devspacePath -Directory | Where-Object { Test-Path (Join-Path $_.FullName '.git') }
    } else {
        $names = $ProjectsArg -split ','
        $projectDirs = $names | ForEach-Object {
            $p = Join-Path $devspacePath $_.Trim()
            if (-not (Test-Path $p)) {
                Write-Warn "Project directory not found: $p — skipping"
                return
            }
            Get-Item $p
        } | Where-Object { $_ -ne $null }
    }

    if ($projectDirs.Count -eq 0) {
        Write-Warn "No project directories found to scan"
        return
    }

    # Build a list of (action, previous, current) pairs to search for
    $replacements = @()
    foreach ($prop in $Registry.tools.PSObject.Properties) {
        $tool = $prop.Value
        if ($null -eq $tool.previous -or $tool.previous -eq '') { continue }
        if ($null -eq $tool.action -or $tool.action -eq '') { continue }

        $replacements += [PSCustomObject]@{
            Action   = $tool.action
            OldPin   = "$($tool.action)@$($tool.previous)"
            NewPin   = "$($tool.action)@$($tool.current)"
            ToolId   = $tool.id
        }
    }

    $totalPRs = 0

    foreach ($projectDir in $projectDirs) {
        $projectName = $projectDir.Name
        $workflowDir = Join-Path $projectDir.FullName '.github' 'workflows'

        if (-not (Test-Path $workflowDir)) {
            Write-Step "$projectName — no .github/workflows/ — skipping"
            continue
        }

        $ymlFiles = Get-ChildItem -Path $workflowDir -Filter '*.yml' -File
        if ($ymlFiles.Count -eq 0) {
            Write-Step "$projectName — no workflow files — skipping"
            continue
        }

        # Scan for outdated pins
        $fileChanges = [System.Collections.Generic.List[PSCustomObject]]::new()

        foreach ($ymlFile in $ymlFiles) {
            $content = Get-Content $ymlFile.FullName -Raw -Encoding UTF8
            $originalContent = $content
            $fileSubstitutions = @()

            foreach ($rep in $replacements) {
                if ($content -match [regex]::Escape($rep.OldPin)) {
                    $content = $content -replace [regex]::Escape($rep.OldPin), $rep.NewPin
                    $fileSubstitutions += "$($rep.OldPin) -> $($rep.NewPin)"
                }
            }

            if ($content -ne $originalContent) {
                $fileChanges.Add([PSCustomObject]@{
                    FilePath     = $ymlFile.FullName
                    FileName     = $ymlFile.Name
                    NewContent   = $content
                    Changes      = $fileSubstitutions
                })
            }
        }

        if ($fileChanges.Count -eq 0) {
            Write-OK "$projectName — already up to date"
            continue
        }

        # Report changes
        Write-Section "$projectName — $($fileChanges.Count) file(s) to update"
        foreach ($fc in $fileChanges) {
            foreach ($ch in $fc.Changes) {
                Write-Step "  $($fc.FileName): $ch"
            }
        }

        if ($IsDryRun) {
            Write-Warn "DryRun: skipping file writes and PR creation"
            continue
        }

        # Create branch and apply changes
        $branchName = "chore/bump-actions-$(Get-Date -Format 'yyyyMMdd')"
        $pushDir    = $projectDir.FullName

        # Check if gh is available
        $ghAvailable = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
        if (-not $ghAvailable) {
            Write-Fail "gh CLI not found — cannot create PR for $projectName"
            continue
        }

        Push-Location $pushDir
        try {
            # Stash any working tree changes
            $null = & git stash 2>&1

            # Create branch from main
            $null = & git fetch origin main 2>&1
            $null = & git checkout -b $branchName origin/main 2>&1

            # Write updated files
            foreach ($fc in $fileChanges) {
                Set-Content -Path $fc.FilePath -Value $fc.NewContent -Encoding UTF8 -NoNewline
            }

            # Commit
            $null = & git add ($fileChanges | ForEach-Object { $_.FilePath }) 2>&1
            $commitMsg = "chore: bump GitHub Actions versions`n`nUpdated by Invoke-VersionUpdate.ps1 -Mode Propagate`n`nCo-Authored-By: Claude <noreply@anthropic.com>"
            $null = & git commit -m $commitMsg 2>&1

            # Push
            $null = & git push origin $branchName 2>&1

            # Create PR
            $prBody = @"
## Summary

- Bump outdated GitHub Actions version pins to current registry values
- Updated by \`scripts/Invoke-VersionUpdate.ps1 -Mode Propagate\`

## Changes

$(($fileChanges | ForEach-Object { "- ``$($_.FileName)``:`n  - $($_.Changes -join "`n  - ")" }) -join "`n")

## Test plan

- [ ] CI passes on this PR

Generated by DevKit Invoke-VersionUpdate.ps1
"@
            & gh pr create --title "chore: bump GitHub Actions versions" --body $prBody --base main --head $branchName
            Write-OK "$projectName — PR created on branch $branchName"
            $totalPRs++

            # Return to main
            $null = & git checkout main 2>&1
            $null = & git stash pop 2>&1
        } catch {
            Write-Fail "$projectName — error: $_"
            $null = & git checkout main 2>&1
            $null = & git stash pop 2>&1
        } finally {
            Pop-Location
        }
    }

    Write-Host ''
    if ($IsDryRun) {
        Write-Warn "DryRun mode: no files written, no PRs created"
    } else {
        Write-OK "Propagate complete. PRs created: $totalPRs"
    }
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------

$registry = Read-Registry

switch ($Mode) {
    'Status' {
        Write-Section "Tool Registry Status"
        Invoke-Status -Registry $registry
    }

    'Render' {
        Write-Section "Rendering Templates"
        Invoke-Render -Registry $registry
    }

    'Bump' {
        if ([string]::IsNullOrWhiteSpace($Tool)) {
            Write-Fail "-Tool is required for Bump mode"
            exit 1
        }
        if ([string]::IsNullOrWhiteSpace($Version)) {
            Write-Fail "-Version is required for Bump mode"
            exit 1
        }
        Write-Section "Bumping $Tool to $Version"
        $changed = Invoke-Bump -Registry $registry -ToolId $Tool -NewVersion $Version
        if ($changed) {
            Write-Registry -Registry $registry
            Write-Host ''
            Write-Section "Re-rendering Templates"
            Invoke-Render -Registry $registry
        }
    }

    'Rollback' {
        if ([string]::IsNullOrWhiteSpace($Tool)) {
            Write-Fail "-Tool is required for Rollback mode"
            exit 1
        }
        Write-Section "Rolling Back $Tool"
        $changed = Invoke-Rollback -Registry $registry -ToolId $Tool
        if ($changed) {
            Write-Registry -Registry $registry
            Write-Host ''
            Write-Section "Re-rendering Templates"
            Invoke-Render -Registry $registry
        }
    }

    'Propagate' {
        Write-Section "Propagating Version Updates to Projects"
        if ($DryRun) {
            Write-Warn "Dry-run mode — no changes will be written"
        }
        Invoke-Propagate -Registry $registry -ProjectsArg $Projects -IsDryRun $DryRun.IsPresent
    }
}
