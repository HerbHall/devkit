<#
.SYNOPSIS
    Locates, classifies, and repairs VS Code workspace files under D:\DevSpace\.

.DESCRIPTION
    Scans for .code-workspace files and validates each against the DevKit convention:
    - Canonical location: <project-root>/<project-name>.code-workspace
    - folders[0].path must resolve to a real directory containing a .git folder

    Classifies each file as:
    - valid:     path resolves correctly; workspace is at project root
    - misplaced: workspace file is not at the project root (left behind after a move)
    - stale-path: workspace is at the right location but folders[0].path is non-existent
    - missing:   project is in registry but has no .code-workspace file

    Repairs automatically unless -WhatIf is specified.

.PARAMETER DevSpaceRoot
    Root directory to scan. Defaults to D:\DevSpace\.

.PARAMETER RegistryPath
    Path to the devkit registry JSON. Defaults to ~/.devkit-registry.json.

.PARAMETER TemplatePath
    Path to workspace.code-workspace template. Defaults to the DevKit project-templates location.

.PARAMETER WhatIf
    Preview changes without applying them.

.EXAMPLE
    # Dry run
    pwsh -File devkit/scripts/Repair-WorkspaceFiles.ps1 -WhatIf

    # Apply repairs
    pwsh -File devkit/scripts/Repair-WorkspaceFiles.ps1

.NOTES
    See docs/vscode-workspaces.md for the full workspace convention.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$DevSpaceRoot = 'D:\DevSpace',
    [string]$RegistryPath = (Join-Path $env:USERPROFILE '.devkit-registry.json'),
    [string]$TemplatePath = '',
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -- Resolve template path --
if (-not $TemplatePath) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $devkitRoot = Split-Path -Parent $scriptDir
    $TemplatePath = Join-Path $devkitRoot 'project-templates\workspace.code-workspace'
}

# -- Helpers --

function Get-WorkspaceFolderPath {
    param([string]$WorkspaceFile)
    try {
        $content = Get-Content $WorkspaceFile -Raw
        # Strip JSONC comments before parsing
        $stripped = $content -replace '//[^\r\n]*', '' -replace '/\*[\s\S]*?\*/', ''
        $json = $stripped | ConvertFrom-Json
        if ($json.folders -and $json.folders.Count -gt 0) {
            return $json.folders[0].path
        }
    }
    catch {
        Write-Warning "  Could not parse $WorkspaceFile : $_"
    }
    return $null
}

function Resolve-WorkspaceFolderPath {
    param([string]$WorkspaceFile, [string]$FolderPath)
    $dir = Split-Path -Parent $WorkspaceFile
    return [System.IO.Path]::GetFullPath((Join-Path $dir $FolderPath))
}

function Test-GitRoot {
    param([string]$Path)
    return (Test-Path $Path) -and (Test-Path (Join-Path $Path '.git'))
}

function Get-ProjectRootFromWorkspace {
    param([string]$WorkspaceFile)
    # Walks up from workspace file to find the first directory containing .git
    $dir = Split-Path -Parent $WorkspaceFile
    while ($dir -and (Test-Path $dir)) {
        if (Test-Path (Join-Path $dir '.git')) {
            return $dir
        }
        $parent = Split-Path -Parent $dir
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    return $null
}

function Detect-StackProfile {
    param([string]$ProjectRoot)
    if (Test-Path (Join-Path $ProjectRoot 'go.mod')) { return 'go' }
    if (Test-Path (Join-Path $ProjectRoot 'package.json')) { return 'typescript' }
    if (Test-Path (Join-Path $ProjectRoot 'Cargo.toml')) { return 'rust' }
    $csprojFiles = Get-ChildItem $ProjectRoot -Filter '*.csproj' -ErrorAction SilentlyContinue
    if ($csprojFiles -or (Test-Path (Join-Path $ProjectRoot '*.sln'))) { return 'csharp' }
    return 'base'
}

function New-WorkspaceFromTemplate {
    param([string]$DestPath, [string]$TemplatePath)
    if (Test-Path $TemplatePath) {
        Copy-Item $TemplatePath $DestPath
    }
    else {
        # Minimal fallback if template is missing
        $minimal = @'
{
    "folders": [
        { "path": "." }
    ],
    "settings": {},
    "extensions": {
        "recommendations": []
    }
}
'@
        Set-Content $DestPath $minimal -Encoding UTF8
    }
}

# -- Load registry (if available) --
$registryProjects = @()
if (Test-Path $RegistryPath) {
    try {
        $registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
        $registryProjects = $registry.projects
    }
    catch {
        Write-Warning "Could not read registry at $RegistryPath : $_"
    }
}

# -- Results --
$results = @{
    valid     = [System.Collections.Generic.List[string]]::new()
    misplaced = [System.Collections.Generic.List[hashtable]]::new()
    stalePath = [System.Collections.Generic.List[hashtable]]::new()
    missing   = [System.Collections.Generic.List[string]]::new()
    repaired  = [System.Collections.Generic.List[string]]::new()
    errors    = [System.Collections.Generic.List[string]]::new()
}

Write-Host ''
Write-Host '== DevKit Workspace Repair ==' -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host '   (dry run -- no changes will be made)' -ForegroundColor Yellow
}
Write-Host ''

# -- Phase 1: Scan existing .code-workspace files --
Write-Host 'Scanning for .code-workspace files under ' -NoNewline
Write-Host $DevSpaceRoot -ForegroundColor White
Write-Host ''

$workspaceFiles = Get-ChildItem $DevSpaceRoot -Recurse -Filter '*.code-workspace' -ErrorAction SilentlyContinue

foreach ($file in $workspaceFiles) {
    $filePath = $file.FullName
    $fileDir  = $file.DirectoryName
    $fileName = $file.BaseName  # e.g., "subnetree" from "subnetree.code-workspace"

    $folderRelPath = Get-WorkspaceFolderPath $filePath
    if ($null -eq $folderRelPath) {
        $results.errors.Add($filePath)
        Write-Host "  [ERROR]     $filePath" -ForegroundColor Red
        Write-Host "              Could not parse folders[0].path"
        continue
    }

    $resolvedFolder = Resolve-WorkspaceFolderPath $filePath $folderRelPath
    $folderExists   = Test-Path $resolvedFolder
    $isGitRoot      = $folderExists -and (Test-GitRoot $resolvedFolder)

    # Is the workspace at the canonical project root?
    $projectRoot = Get-ProjectRootFromWorkspace $filePath
    $atProjectRoot = ($projectRoot -ne $null) -and ($fileDir -eq $projectRoot)

    if ($folderExists -and $isGitRoot -and $atProjectRoot) {
        # valid
        $results.valid.Add($filePath)
        Write-Host "  [VALID]     $filePath" -ForegroundColor Green
    }
    elseif (-not $folderExists -and $atProjectRoot) {
        # stale-path: file is at root but folders[0].path does not resolve
        $results.stalePath.Add(@{ file = $filePath; resolved = $resolvedFolder })
        Write-Host "  [STALE-PATH] $filePath" -ForegroundColor Yellow
        Write-Host "               folders[0].path -> $resolvedFolder (not found)"

        if (-not $WhatIf -and $PSCmdlet.ShouldProcess($filePath, 'Rewrite folders[0].path to .')) {
            # Rewrite folders[0].path to "."
            $raw = Get-Content $filePath -Raw
            $raw = $raw -replace '"path"\s*:\s*"[^"]*"', '"path": "."'
            Set-Content $filePath $raw -Encoding UTF8
            $results.repaired.Add($filePath)
            Write-Host "               -> Rewritten to '.' " -ForegroundColor Cyan
        }
        elseif ($WhatIf) {
            Write-Host "               -> Would rewrite folders[0].path to '.'" -ForegroundColor Cyan
        }
    }
    elseif (-not $atProjectRoot) {
        # misplaced: workspace is not at the project root
        $canonicalRoot = if ($projectRoot) { $projectRoot } else { $resolvedFolder }
        $canonicalName = Split-Path -Leaf $canonicalRoot
        $canonicalDest = Join-Path $canonicalRoot "$canonicalName.code-workspace"

        $results.misplaced.Add(@{ file = $filePath; dest = $canonicalDest; root = $canonicalRoot })
        Write-Host "  [MISPLACED] $filePath" -ForegroundColor Yellow
        Write-Host "               -> Canonical location: $canonicalDest"

        if (-not $WhatIf -and $PSCmdlet.ShouldProcess($filePath, "Move to $canonicalDest")) {
            if (-not (Test-Path $canonicalDest)) {
                Move-Item $filePath $canonicalDest
                # Rewrite folders[0].path to "." in the moved file
                $raw = Get-Content $canonicalDest -Raw
                $raw = $raw -replace '"path"\s*:\s*"[^"]*"', '"path": "."'
                Set-Content $canonicalDest $raw -Encoding UTF8
                $results.repaired.Add($canonicalDest)
                Write-Host "               -> Moved and rewritten" -ForegroundColor Cyan
            }
            else {
                Write-Warning "               -> Destination already exists; skipped"
                $results.errors.Add($filePath)
            }
        }
        elseif ($WhatIf) {
            Write-Host "               -> Would move and rewrite folders[0].path to '.'" -ForegroundColor Cyan
        }
    }
    else {
        # edge case: folder exists but is not a git root
        $results.errors.Add($filePath)
        Write-Host "  [UNKNOWN]   $filePath" -ForegroundColor DarkYellow
        Write-Host "               folders[0].path = $resolvedFolder (exists but not a git root)"
    }
}

# -- Phase 2: Check registry for missing workspace files --
if ($registryProjects.Count -gt 0) {
    Write-Host ''
    Write-Host 'Checking registry for projects without workspace files...'
    Write-Host ''

    foreach ($project in $registryProjects) {
        $projectPath = $project.path
        if (-not (Test-Path $projectPath)) { continue }

        $projectName   = Split-Path -Leaf $projectPath
        $expectedPath  = Join-Path $projectPath "$projectName.code-workspace"

        if (-not (Test-Path $expectedPath)) {
            $results.missing.Add($projectPath)
            Write-Host "  [MISSING]   $expectedPath" -ForegroundColor Yellow

            if (-not $WhatIf -and $PSCmdlet.ShouldProcess($expectedPath, 'Scaffold from template')) {
                New-WorkspaceFromTemplate $expectedPath $TemplatePath
                $results.repaired.Add($expectedPath)
                $stackProfile = Detect-StackProfile $projectPath
                Write-Host "               -> Scaffolded from template (stack: $stackProfile)" -ForegroundColor Cyan
                Write-Host "               -> Review and merge settings from devspace/shared-vscode/$stackProfile.jsonc" -ForegroundColor DarkCyan
            }
            elseif ($WhatIf) {
                $stackProfile = Detect-StackProfile $projectPath
                Write-Host "               -> Would scaffold from template (stack: $stackProfile)" -ForegroundColor Cyan
            }
        }
    }
}

# -- Summary --
Write-Host ''
Write-Host '== Summary ==' -ForegroundColor Cyan
Write-Host "  Valid:      $($results.valid.Count)"
Write-Host "  Misplaced:  $($results.misplaced.Count)"
Write-Host "  Stale-path: $($results.stalePath.Count)"
Write-Host "  Missing:    $($results.missing.Count)"
Write-Host "  Errors:     $($results.errors.Count)"
if (-not $WhatIf) {
    Write-Host "  Repaired:   $($results.repaired.Count)" -ForegroundColor Cyan
}
Write-Host ''

if ($results.repaired.Count -gt 0 -and -not $WhatIf) {
    Write-Host 'Repaired files:' -ForegroundColor Cyan
    foreach ($f in $results.repaired) {
        Write-Host "  $f"
    }
    Write-Host ''
    Write-Host 'Next steps:' -ForegroundColor White
    Write-Host '  - Review repaired workspace files'
    Write-Host '  - For scaffolded files: merge settings from devspace/shared-vscode/<stack>.jsonc'
    Write-Host '  - Run: pwsh -File scripts/Sync-WorkspaceExtensions.ps1 -WhatIf'
}
