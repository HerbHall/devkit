#Requires -Version 7.0
# setup/new-project.ps1 -- Kit 3: New project scaffolder (Steps 1-4)
#
# Collects project concept, creates directory structure, initializes
# the git repo and GitHub remote, generates CLAUDE.md, and opens VS Code.
#
# Usage:
#   .\setup\new-project.ps1                                  # Fully interactive
#   .\setup\new-project.ps1 -Name my-tool                   # Pre-fill project name
#   .\setup\new-project.ps1 -Profile go-cli                  # Pre-fill profile
#   .\setup\new-project.ps1 -ConceptFile path\to\brief.md   # Load concept from file
#   .\setup\new-project.ps1 -NoGitHub                        # Skip GitHub repo creation

Set-StrictMode -Version Latest

param(
    [string]$Name,         # Pre-fill project name (skip prompt)
    [string]$Profile,      # Pre-fill profile selection (comma-separated names)
    [string]$ConceptFile,  # Path to filled concept-brief.md
    [switch]$NoGitHub      # Skip GitHub repo creation
)

# ---------------------------------------------------------------------------
# Dot-source dependencies
# install.ps1 brings in checks.ps1 and ui.ps1
# profiles.ps1 sets $script:RepoRoot and provides Get-AllProfiles / Resolve-ProfileDeps
# ---------------------------------------------------------------------------

. "$PSScriptRoot\lib\install.ps1"
. "$PSScriptRoot\lib\profiles.ps1"

# ---------------------------------------------------------------------------
# Helper: parse a concept-brief.md file into a concept hashtable
# ---------------------------------------------------------------------------

function Read-ConceptBriefFile {
    <#
    .SYNOPSIS
        Parses a filled-in concept-brief.md file into a structured hashtable.
    .DESCRIPTION
        Extracts the four key sections from the concept brief template:
        "What is this project?", "What problem does it solve?",
        "What does it do?", and "What does it NOT do?".
        Returns a hashtable with Description, Problem, Features, and NonGoals keys.
    .PARAMETER Path
        Path to the filled-in concept-brief.md file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Fail "Concept brief file not found: $Path"
        return $null
    }

    $content = Get-Content -Path $Path -Raw

    # Extract "What is this project?" section (one-sentence description)
    $description = ''
    if ($content -match '##\s+What is this project\?[^\n]*\n([\s\S]*?)(?=##|\Z)') {
        $block = $Matches[1]
        # Strip HTML comments and blank lines, get first non-empty line
        $lines = $block -split '\r?\n' |
            Where-Object { $_ -notmatch '^\s*<!--' -and $_ -notmatch '-->' -and $_ -notmatch '^\s*$' }
        if ($lines.Count -gt 0) {
            $description = $lines[0].Trim()
        }
    }

    # Extract "What problem does it solve?" section
    $problem = ''
    if ($content -match '##\s+What problem does it solve\?[^\n]*\n([\s\S]*?)(?=##|\Z)') {
        $block = $Matches[1]
        $lines = $block -split '\r?\n' |
            Where-Object { $_ -notmatch '^\s*<!--' -and $_ -notmatch '-->' -and $_ -notmatch '^\s*$' }
        if ($lines.Count -gt 0) {
            $problem = ($lines -join ' ').Trim()
        }
    }

    # Extract "What does it do?" numbered list items
    $features = [System.Collections.Generic.List[string]]::new()
    if ($content -match '##\s+What does it do\?[^\n]*\n([\s\S]*?)(?=##|\Z)') {
        $block = $Matches[1]
        $lines = $block -split '\r?\n' |
            Where-Object { $_ -notmatch '^\s*<!--' -and $_ -notmatch '-->' }
        foreach ($line in $lines) {
            if ($line -match '^\s*\d+\.\s+(.+)$') {
                $item = $Matches[1].Trim()
                if ($item -ne '') {
                    $features.Add($item)
                }
            }
        }
    }

    # Extract "What does it NOT do?" section
    $nonGoals = [System.Collections.Generic.List[string]]::new()
    if ($content -match '##\s+What does it NOT do\?[^\n]*\n([\s\S]*?)(?=##|\Z)') {
        $block = $Matches[1]
        $lines = $block -split '\r?\n' |
            Where-Object { $_ -notmatch '^\s*<!--' -and $_ -notmatch '-->' }
        foreach ($line in $lines) {
            # Accept numbered lists, bullet lists, and plain lines
            if ($line -match '^\s*(?:\d+\.|-|\*)\s+(.+)$') {
                $item = $Matches[1].Trim()
                if ($item -ne '') {
                    $nonGoals.Add($item)
                }
            }
        }
    }

    return @{
        Description = $description
        Problem     = $problem
        Features    = @($features)
        NonGoals    = @($nonGoals)
    }
}

# ---------------------------------------------------------------------------
# Helper: prompt for multi-line list input (one item per line, blank to stop)
# ---------------------------------------------------------------------------

function Read-LineList {
    <#
    .SYNOPSIS
        Prompts the user to enter items one per line until a blank line is entered.
    .PARAMETER Prompt
        Label shown above the input prompt.
    .PARAMETER ItemLabel
        Noun used in the "Enter item N" prompt (e.g., "feature", "non-goal").
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [string]$ItemLabel
    )

    Write-Host ''
    Write-Host "  ${script:Bold}${Prompt}${script:Reset}"
    Write-Host "  ${script:Dim}(Enter one $ItemLabel per line. Press Enter on an empty line when done.)${script:Reset}"

    $items = [System.Collections.Generic.List[string]]::new()
    $num = 1
    while ($true) {
        $line = Read-Host -Prompt "  $ItemLabel $num"
        if ([string]::IsNullOrWhiteSpace($line)) {
            break
        }
        $items.Add($line.Trim())
        $num++
    }

    return @($items)
}

# ---------------------------------------------------------------------------
# STEP 1: Concept Collection
# Returns a hashtable with: Name, DevSpace, GitHubUser, Profiles, Concept
# ---------------------------------------------------------------------------

function Invoke-ConceptCollection {
    Write-Section 'Step 1: Concept Collection'

    # ------------------------------------------------------------------
    # 1a. Project name
    # ------------------------------------------------------------------

    $projectName = $Name
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        Write-Host ''
        Write-Host '  Project name must be a slug: letters, numbers, and hyphens only.'
        Write-Host '  Example: my-tool, go-scanner, iot-garage-door'
        while ($true) {
            $projectName = Read-Host -Prompt '  Project name'
            $projectName = $projectName.Trim()
            if ($projectName -match '^[a-zA-Z0-9][a-zA-Z0-9-]*$') {
                break
            }
            Write-Warn "Invalid name '$projectName'. Use only letters, numbers, and hyphens. Must start with a letter or number."
        }
    } else {
        # Validate pre-filled name
        if ($projectName -notmatch '^[a-zA-Z0-9][a-zA-Z0-9-]*$') {
            Write-Fail "Invalid project name '$projectName'. Use only letters, numbers, and hyphens."
            exit 1
        }
        Write-Step "Project name: $projectName"
    }

    # ------------------------------------------------------------------
    # 1b. DevSpace path
    # ------------------------------------------------------------------

    $devspacePath = $null

    # Try ~/.devkit-config.json first
    $configFile = Join-Path $HOME '.devkit-config.json'
    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile -Raw | ConvertFrom-Json
            if ($config.PSObject.Properties['DevSpace'] -and $config.DevSpace) {
                $devspacePath = $config.DevSpace
            }
        } catch {
            # Ignore parse errors, fall through to other sources
        }
    }

    # Fall back to $env:DEVSPACE
    if ([string]::IsNullOrWhiteSpace($devspacePath) -and $env:DEVSPACE) {
        $devspacePath = $env:DEVSPACE
    }

    # Fall back to D:\DevSpace
    if ([string]::IsNullOrWhiteSpace($devspacePath)) {
        $devspacePath = 'D:\DevSpace'
    }

    Write-Step "DevSpace path: $devspacePath"

    # ------------------------------------------------------------------
    # 1c. GitHub username
    # ------------------------------------------------------------------

    $githubUser = $null

    # Try git config
    try {
        $gitUser = & git config --global user.name 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($gitUser)) {
            $githubUser = $gitUser.Trim()
        }
    } catch { }

    # Try gh api as fallback
    if ([string]::IsNullOrWhiteSpace($githubUser)) {
        try {
            $ghUser = & gh api user --jq '.login' 2>$null
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($ghUser)) {
                $githubUser = $ghUser.Trim()
            }
        } catch { }
    }

    # Prompt if still not found
    if ([string]::IsNullOrWhiteSpace($githubUser)) {
        Write-Host ''
        $githubUser = Read-Required 'GitHub username'
    } else {
        Write-Step "GitHub user: $githubUser"
    }

    # ------------------------------------------------------------------
    # 1d. Show target directory and GitHub repo URL
    # ------------------------------------------------------------------

    $targetDir = Join-Path $devspacePath $projectName
    $repoUrl   = "https://github.com/$githubUser/$projectName"

    Write-Host ''
    Write-Host "  ${script:Bold}Target directory:${script:Reset} $targetDir"
    Write-Host "  ${script:Bold}GitHub repo:${script:Reset}      $repoUrl"

    # ------------------------------------------------------------------
    # 1e. Profile selection (reuse stack.ps1 approach)
    # ------------------------------------------------------------------

    $allProfiles = Get-AllProfiles
    if ($allProfiles.Count -eq 0) {
        Write-Warn 'No profiles found in profiles/ directory. Continuing without profile selection.'
        $selectedProfileNames = @()
    } else {
        if (-not [string]::IsNullOrWhiteSpace($Profile)) {
            # Non-interactive: parse comma-separated names
            $selectedProfileNames = @($Profile -split '\s*,\s*' | Where-Object { $_ -ne '' })
        } else {
            # Interactive: display numbered list
            Write-Host ''
            Write-Host "${script:Bold}Available profiles:${script:Reset}"
            for ($i = 0; $i -lt $allProfiles.Count; $i++) {
                $p      = $allProfiles[$i]
                $reqStr = if ($p.Requires.Count -gt 0) { "  [requires: $($p.Requires -join ', ')]" } else { '' }
                Write-Host "  $($i + 1). $($p.Name.PadRight(16)) $($p.Description)$reqStr"
            }
            Write-Host ''

            $raw  = Read-Host 'Select profile(s) by number (e.g., 1 or 1,2 -- press Enter to skip)'
            $nums = @($raw -split '\s*,\s*' | Where-Object { $_ -match '^\d+$' })

            $selectedProfileNames = [System.Collections.Generic.List[string]]::new()
            foreach ($numStr in $nums) {
                $idx = [int]$numStr - 1
                if ($idx -lt 0 -or $idx -ge $allProfiles.Count) {
                    Write-Warn "Invalid selection: $numStr (valid range: 1-$($allProfiles.Count)) -- skipping"
                    continue
                }
                $selectedProfileNames.Add($allProfiles[$idx].Name)
            }
            $selectedProfileNames = @($selectedProfileNames)
        }

        # Resolve dependencies
        if ($selectedProfileNames.Count -gt 0) {
            try {
                $resolvedNames = Resolve-ProfileDeps -Names $selectedProfileNames
            } catch {
                Write-Fail "Profile dependency resolution failed: $_"
                exit 1
            }

            $addedDeps = @($resolvedNames | Where-Object { $selectedProfileNames -notcontains $_ })
            if ($addedDeps.Count -gt 0) {
                Write-Host "  Auto-added dependencies: $($addedDeps -join ', ')"
            }

            $selectedProfileNames = @($resolvedNames)
        }
    }

    if ($selectedProfileNames.Count -gt 0) {
        Write-Step "Profiles: $($selectedProfileNames -join ', ')"
    } else {
        Write-Step 'Profiles: (none selected)'
    }

    # ------------------------------------------------------------------
    # 1f. Concept brief
    # ------------------------------------------------------------------

    $concept = $null

    if (-not [string]::IsNullOrWhiteSpace($ConceptFile)) {
        # Load from file
        Write-Step "Loading concept brief from: $ConceptFile"
        $concept = Read-ConceptBriefFile -Path $ConceptFile
        if ($null -eq $concept) {
            Write-Fail 'Could not parse concept brief file. Switching to interactive mode.'
        } else {
            Write-OK "Concept brief loaded"
            Write-Step "Description: $($concept.Description)"
            Write-Step "Features: $($concept.Features.Count) item(s)"
        }
    }

    if ($null -eq $concept) {
        # Interactive mode
        Write-Host ''
        Write-Host "${script:Bold}Concept Brief (interactive)${script:Reset}"
        Write-Host "${script:Dim}This information will be used to generate your project's CLAUDE.md.${script:Reset}"

        Write-Host ''
        $description = Read-Required 'What is this project? (one sentence)'

        Write-Host ''
        $problem = Read-Required 'What problem does it solve?'

        $features = Read-LineList -Prompt 'What does it do? (core features)' -ItemLabel 'feature'

        $nonGoals = Read-LineList -Prompt 'What does it NOT do? (non-goals / scope boundaries)' -ItemLabel 'non-goal'

        $concept = @{
            Description = $description
            Problem     = $problem
            Features    = $features
            NonGoals    = $nonGoals
        }
    }

    # Return the collected data
    return @{
        Name       = $projectName
        DevSpace   = $devspacePath
        GitHubUser = $githubUser
        Profiles   = $selectedProfileNames
        Concept    = $concept
    }
}

# ---------------------------------------------------------------------------
# STEP 2: Scaffolding
# ---------------------------------------------------------------------------

function Invoke-Scaffolding {
    <#
    .SYNOPSIS
        Creates the project directory, git repo, GitHub remote, and initial files.
    .PARAMETER Data
        Hashtable returned by Invoke-ConceptCollection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    Write-Section 'Step 2: Scaffolding'

    $projectName = $Data.Name
    $devspace    = $Data.DevSpace
    $githubUser  = $Data.GitHubUser
    $profileNames = @($Data.Profiles)
    $concept     = $Data.Concept
    $targetDir   = Join-Path $devspace $projectName

    # Determine primary profile for file generation decisions
    $primaryProfile = if ($profileNames.Count -gt 0) { $profileNames[0] } else { '' }
    $isGo       = $primaryProfile -in @('go-cli', 'go-web')
    $isIot      = $primaryProfile -eq 'iot-embedded'

    # ------------------------------------------------------------------
    # 2.1 Create project directory (or check if it already exists)
    # ------------------------------------------------------------------

    Write-Step "Target: $targetDir"

    if (Test-Path $targetDir) {
        Write-Warn "Directory already exists: $targetDir"
        $continue = Read-Confirm 'Continue and add scaffolding to existing directory? [y/N]'
        if (-not $continue) {
            Write-Host '  Aborted.'
            exit 1
        }
        Write-Step 'Continuing with existing directory...'
    } else {
        try {
            $null = New-Item -ItemType Directory -Path $targetDir -Force
            Write-OK "Created $targetDir"
        } catch {
            Write-Fail "Failed to create directory: $_"
            exit 1
        }
    }

    # ------------------------------------------------------------------
    # 2.2 Git init
    # ------------------------------------------------------------------

    Write-Step 'Initializing git repository...'
    $gitDir = Join-Path $targetDir '.git'
    if (Test-Path $gitDir) {
        Write-OK 'Git repository already initialized'
    } else {
        try {
            Push-Location $targetDir
            $gitOutput = & git init 2>&1 | Out-String
            $gitExit   = $LASTEXITCODE
            Pop-Location

            if ($gitExit -ne 0) {
                Write-Fail "git init failed (exit $gitExit): $gitOutput"
                exit 1
            }
            Write-OK 'Git repository initialized'
        } catch {
            Pop-Location -ErrorAction SilentlyContinue
            Write-Fail "git init threw exception: $_"
            exit 1
        }
    }

    # ------------------------------------------------------------------
    # 2.3 Create directory structure
    # ------------------------------------------------------------------

    Write-Step 'Creating directory structure...'

    $dirsToCreate = [System.Collections.Generic.List[string]]::new()
    $dirsToCreate.Add('.github/workflows')
    $dirsToCreate.Add('docs')

    if ($isGo) {
        $dirsToCreate.Add("cmd/$projectName")
        $dirsToCreate.Add('internal')
    } elseif ($isIot) {
        $dirsToCreate.Add('src')
        $dirsToCreate.Add('components')
    } else {
        $dirsToCreate.Add('src')
    }

    foreach ($dir in $dirsToCreate) {
        $fullPath = Join-Path $targetDir $dir
        if (-not (Test-Path $fullPath)) {
            try {
                $null = New-Item -ItemType Directory -Path $fullPath -Force
                Write-OK "Created $dir/"
            } catch {
                Write-Warn "Could not create $dir/: $_"
            }
        } else {
            Write-Step "$dir/ already exists"
        }
    }

    # ------------------------------------------------------------------
    # 2.4 Create initial files
    # ------------------------------------------------------------------

    Write-Step 'Creating initial files...'

    # .gitignore
    $gitignorePath = Join-Path $targetDir '.gitignore'
    if (-not (Test-Path $gitignorePath)) {
        if ($isGo) {
            $gitignoreContent = @'
# Go binaries and build artifacts
*.exe
*.exe~
*.dll
*.so
*.dylib
dist/

# Test binary, built with "go test -c"
*.test

# Output of the go coverage tool
*.out

# Dependency vendor directory
vendor/

# Go workspace file
go.work
go.work.sum

# Build artifacts
bin/

# IDE
.vscode/*.log
'@
        } elseif ($isIot) {
            $gitignoreContent = @'
# ESPHome secrets (NEVER commit)
secrets.yaml

# Compiled firmware artifacts
compiled/
.esphome/
*.bin
*.elf
*.map

# Python
__pycache__/
*.pyc
.venv/

# IDE
.vscode/*.log
'@
        } else {
            $gitignoreContent = @'
# Dependencies
node_modules/
vendor/

# Build artifacts
dist/
build/
*.out

# Environment files
.env
.env.local
.env*.local

# IDE
.vscode/*.log
'@
        }

        try {
            Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding utf8NoBOM
            Write-OK 'Created .gitignore'
        } catch {
            Write-Warn "Could not write .gitignore: $_"
        }
    } else {
        Write-Step '.gitignore already exists'
    }

    # README.md
    $readmePath = Join-Path $targetDir 'README.md'
    if (-not (Test-Path $readmePath)) {
        $oneLiner = if ($concept.Description) { $concept.Description } else { 'A new project.' }
        $readmeContent = "# $projectName`n`n$oneLiner`n"
        try {
            Set-Content -Path $readmePath -Value $readmeContent -Encoding utf8NoBOM
            Write-OK 'Created README.md'
        } catch {
            Write-Warn "Could not write README.md: $_"
        }
    } else {
        Write-Step 'README.md already exists'
    }

    # Go-specific files: go.mod and cmd/$Name/main.go
    if ($isGo) {
        $goModPath = Join-Path $targetDir 'go.mod'
        if (-not (Test-Path $goModPath)) {
            $goModContent = "module github.com/$githubUser/$projectName`n`ngo 1.23`n"
            try {
                Set-Content -Path $goModPath -Value $goModContent -Encoding utf8NoBOM
                Write-OK 'Created go.mod'
            } catch {
                Write-Warn "Could not write go.mod: $_"
            }
        } else {
            Write-Step 'go.mod already exists'
        }

        $mainGoPath = Join-Path $targetDir "cmd/$projectName/main.go"
        if (-not (Test-Path $mainGoPath)) {
            $mainGoContent = "package main`n`nimport `"fmt`"`n`nfunc main() {`n`tfmt.Println(`"Hello from $projectName`")`n}`n"
            try {
                Set-Content -Path $mainGoPath -Value $mainGoContent -Encoding utf8NoBOM
                Write-OK "Created cmd/$projectName/main.go"
            } catch {
                Write-Warn "Could not write cmd/$projectName/main.go: $_"
            }
        } else {
            Write-Step "cmd/$projectName/main.go already exists"
        }
    }

    # IoT-specific files: src/main.yaml ESPHome stub
    if ($isIot) {
        $mainYamlPath = Join-Path $targetDir 'src/main.yaml'
        if (-not (Test-Path $mainYamlPath)) {
            $mainYamlContent = @"
esphome:
  name: $projectName
  platform: esp32
  board: esp32doit-devkit-v1

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:
  encryption:
    key: !secret api_key

ota:
  password: !secret ota_password

logger:
"@
            try {
                Set-Content -Path $mainYamlPath -Value $mainYamlContent -Encoding utf8NoBOM
                Write-OK 'Created src/main.yaml'
            } catch {
                Write-Warn "Could not write src/main.yaml: $_"
            }
        } else {
            Write-Step 'src/main.yaml already exists'
        }
    }

    # VS Code workspace file
    $workspacePath = Join-Path $targetDir "$projectName.code-workspace"
    if (-not (Test-Path $workspacePath)) {
        $workspaceContent = @'
{
  "folders": [{ "path": "." }],
  "settings": {}
}
'@
        try {
            Set-Content -Path $workspacePath -Value $workspaceContent -Encoding utf8NoBOM
            Write-OK "Created $projectName.code-workspace"
        } catch {
            Write-Warn "Could not write $projectName.code-workspace: $_"
        }
    } else {
        Write-Step "$projectName.code-workspace already exists"
    }

    # .claude/settings.json with project metadata
    $claudeDir = Join-Path $targetDir '.claude'
    if (-not (Test-Path $claudeDir)) {
        $null = New-Item -ItemType Directory -Path $claudeDir -Force
    }

    $claudeSettingsPath = Join-Path $claudeDir 'settings.json'
    if (-not (Test-Path $claudeSettingsPath)) {
        $profileList = if ($profileNames.Count -gt 0) {
            '[' + (($profileNames | ForEach-Object { "`"$_`"" }) -join ', ') + ']'
        } else {
            '[]'
        }
        $claudeSettingsContent = @"
{
  "project": "$projectName",
  "profiles": $profileList,
  "devspace": "$($devspace -replace '\\', '\\')",
  "github": "https://github.com/$githubUser/$projectName"
}
"@
        try {
            Set-Content -Path $claudeSettingsPath -Value $claudeSettingsContent -Encoding utf8NoBOM
            Write-OK 'Created .claude/settings.json'
        } catch {
            Write-Warn "Could not write .claude/settings.json: $_"
        }
    } else {
        Write-Step '.claude/settings.json already exists'
    }

    # ------------------------------------------------------------------
    # 2.5 Create GitHub repo
    # ------------------------------------------------------------------

    $githubCreated = $false

    if ($NoGitHub) {
        Write-Warn 'Skipping GitHub repo creation (-NoGitHub flag set)'
    } else {
        Write-Step "Creating GitHub repo: $githubUser/$projectName ..."
        try {
            Push-Location $targetDir

            # We need at least one commit before gh repo create --push can work.
            # Stage all created files for the initial commit.
            $null = & git add -A 2>&1
            $null = & git commit -m "chore: initial project scaffolding" 2>&1

            $ghOutput = & gh repo create "$githubUser/$projectName" `
                --private `
                --source . `
                --remote origin `
                --push 2>&1 | Out-String
            $ghExit = $LASTEXITCODE

            Pop-Location

            if ($ghExit -ne 0) {
                Write-Warn "gh repo create failed (exit $ghExit). Manual command:"
                Write-Host "  gh repo create $githubUser/$projectName --private --source . --remote origin --push"
                Write-Host "  (run from $targetDir)"
            } else {
                Write-OK "GitHub repo created: https://github.com/$githubUser/$projectName"
                $githubCreated = $true
            }
        } catch {
            Pop-Location -ErrorAction SilentlyContinue
            Write-Warn "gh repo create threw an exception: $_"
            Write-Warn "Manual command:"
            Write-Host "  cd `"$targetDir`""
            Write-Host "  gh repo create $githubUser/$projectName --private --source . --remote origin --push"
        }
    }

    # If GitHub was skipped or failed, do a local initial commit if not already done
    if (-not $githubCreated) {
        try {
            Push-Location $targetDir

            # Check if there are any commits yet
            $logOutput = & git log --oneline -1 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($logOutput)) {
                # No commits yet -- stage and commit
                $null = & git add -A 2>&1
                $commitOutput = & git commit -m "chore: initial project scaffolding" 2>&1 | Out-String
                $commitExit   = $LASTEXITCODE
                if ($commitExit -eq 0) {
                    Write-OK 'Initial commit created (local only)'
                } else {
                    Write-Warn "Initial commit failed: $commitOutput"
                }
            } else {
                Write-Step 'Repository already has commits'
            }

            Pop-Location
        } catch {
            Pop-Location -ErrorAction SilentlyContinue
            Write-Warn "Could not create initial commit: $_"
        }
    }

    # ------------------------------------------------------------------
    # 2.6 Apply GitHub labels
    # ------------------------------------------------------------------

    if ($githubCreated) {
        Write-Step 'Applying GitHub labels...'
        $labelsFile = Join-Path $script:RepoRoot 'project-templates' 'github-labels.json'

        if (-not (Test-Path $labelsFile)) {
            Write-Warn "Labels file not found: $labelsFile -- skipping label setup"
        } else {
            try {
                $labels = Get-Content $labelsFile -Raw | ConvertFrom-Json
                $labelOk    = 0
                $labelFail  = 0

                foreach ($label in $labels) {
                    try {
                        $ghLabelOutput = & gh label create $label.name `
                            --color $label.color `
                            --description $label.description `
                            --repo "$githubUser/$projectName" `
                            --force 2>&1 | Out-String
                        $ghLabelExit = $LASTEXITCODE
                        if ($ghLabelExit -eq 0) {
                            $labelOk++
                        } else {
                            $labelFail++
                            Write-Warn "Label '$($label.name)' failed: $ghLabelOutput"
                        }
                    } catch {
                        $labelFail++
                        Write-Warn "Label '$($label.name)' threw exception: $_"
                    }
                }

                if ($labelFail -eq 0) {
                    Write-OK "Applied $labelOk GitHub labels"
                } else {
                    Write-Warn "Applied $labelOk labels, $labelFail failed"
                }
            } catch {
                Write-Warn "Could not parse labels file: $_"
            }
        }
    }

    # ------------------------------------------------------------------
    # Return scaffold result summary
    # ------------------------------------------------------------------

    return @{
        TargetDir      = $targetDir
        GitHubCreated  = $githubCreated
        RepoUrl        = if ($githubCreated) { "https://github.com/$githubUser/$projectName" } else { '' }
    }
}

# ---------------------------------------------------------------------------
# STEP 3: CLAUDE.md Generation
# ---------------------------------------------------------------------------

function Invoke-ClaudeMdGeneration {
    <#
    .SYNOPSIS
        Generates a project CLAUDE.md using Claude Code or a template fallback.
    .PARAMETER Data
        Hashtable returned by Invoke-ConceptCollection.
    .PARAMETER ScaffoldResult
        Hashtable returned by Invoke-Scaffolding.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data,

        [Parameter(Mandatory)]
        [hashtable]$ScaffoldResult
    )

    Write-Section 'Step 3: CLAUDE.md Generation'

    $projectName = $Data.Name
    $githubUser  = $Data.GitHubUser
    $targetDir   = $ScaffoldResult.TargetDir
    $concept     = $Data.Concept
    $profiles    = @($Data.Profiles)
    $primaryProfile = if ($profiles.Count -gt 0) { $profiles[0] } else { '' }

    $claudeMdPath = Join-Path $targetDir 'CLAUDE.md'
    $claudeMdWritten = $false
    $issueCreated    = $false
    $issueUrl        = ''

    # ------------------------------------------------------------------
    # 3.1 Check Claude auth and choose generation path
    # ------------------------------------------------------------------

    $authResult = Test-ClaudeAuth
    $useClaudeAi = $authResult.Met

    if ($useClaudeAi) {
        Write-Step 'Claude Code authenticated -- generating CLAUDE.md with AI'

        # Build profile body text for the prompt
        $profileBody = ''
        if ($primaryProfile -ne '') {
            $profileObj = Get-Profile -Name $primaryProfile
            if ($null -ne $profileObj -and $profileObj.Body) {
                $profileBody = $profileObj.Body
            }
        }

        # Read the global CLAUDE.md as format reference
        $globalClaudeMd = ''
        $globalClaudeMdPath = Join-Path $script:RepoRoot 'claude' 'CLAUDE.md'
        if (Test-Path $globalClaudeMdPath) {
            $globalClaudeMd = Get-Content $globalClaudeMdPath -Raw
        }

        # Build features and non-goals as text
        $featuresText = if ($concept.Features.Count -gt 0) {
            ($concept.Features | ForEach-Object { "- $_" }) -join "`n"
        } else {
            '(not specified)'
        }
        $nonGoalsText = if ($concept.NonGoals.Count -gt 0) {
            ($concept.NonGoals | ForEach-Object { "- $_" }) -join "`n"
        } else {
            '(not specified)'
        }

        $prompt = @"
Generate a project CLAUDE.md for a new software project. Include: project context, goals and non-goals, tech stack and conventions, build commands, key constraints, and suggested first steps.

PROJECT CONCEPT BRIEF:
Name: $projectName
Description: $($concept.Description)
Problem: $($concept.Problem)
Features:
$featuresText
Non-goals:
$nonGoalsText
Profile: $primaryProfile
GitHub: https://github.com/$githubUser/$projectName

PROFILE DETAILS:
$profileBody

FORMAT REFERENCE (follow the structure and style of this global CLAUDE.md):
$globalClaudeMd

Generate only the CLAUDE.md content. Do not include any preamble or explanation.
"@

        $generatedContent = $null
        $accepted = $false

        while (-not $accepted) {
            Write-Step 'Calling Claude Code to generate CLAUDE.md...'
            try {
                $rawOutput = & claude --print -p $prompt 2>&1 | Out-String
                if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($rawOutput)) {
                    Write-Warn "Claude returned exit code $LASTEXITCODE or empty output -- falling back to template"
                    $useClaudeAi = $false
                    break
                }
                $generatedContent = $rawOutput.Trim()
            } catch {
                Write-Warn "Claude Code call failed: $_ -- falling back to template"
                $useClaudeAi = $false
                break
            }

            # Display result
            Write-Host ''
            Write-Host "${script:Bold}--- Generated CLAUDE.md ---${script:Reset}"
            Write-Host $generatedContent
            Write-Host "${script:Bold}--- End of CLAUDE.md ---${script:Reset}"
            Write-Host ''

            $choice = Read-Host -Prompt '  Accept this CLAUDE.md? [Y/n/edit]'
            $choice = $choice.Trim().ToLower()

            if ($choice -eq '' -or $choice -eq 'y') {
                $accepted = $true
            } elseif ($choice -eq 'n') {
                Write-Step 'Regenerating...'
                # Loop again
            } elseif ($choice -eq 'edit') {
                $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "claude-md-$projectName.md"
                Set-Content -Path $tempFile -Value $generatedContent -Encoding utf8NoBOM
                Write-Step "Opening in VS Code: $tempFile"
                & code --wait $tempFile
                if (Test-Path $tempFile) {
                    $generatedContent = Get-Content $tempFile -Raw
                }
                $accepted = $true
            } else {
                Write-Warn "Unrecognized choice '$choice'. Press Enter or type y to accept, n to regenerate, edit to open in VS Code."
            }
        }

        if ($useClaudeAi -and $accepted -and $null -ne $generatedContent) {
            try {
                Set-Content -Path $claudeMdPath -Value $generatedContent -Encoding utf8NoBOM
                Write-OK 'CLAUDE.md written from AI generation'
                $claudeMdWritten = $true
            } catch {
                Write-Warn "Could not write CLAUDE.md: $_"
            }
        }
    }

    # ------------------------------------------------------------------
    # 3.2 Fallback: template substitution
    # ------------------------------------------------------------------

    if (-not $claudeMdWritten) {
        Write-Warn 'Claude Code not authenticated -- using template fallback'

        $templatePath = Join-Path $script:RepoRoot 'project-templates' 'claude-md-template.md'
        if (-not (Test-Path $templatePath)) {
            Write-Warn "Template not found: $templatePath -- skipping CLAUDE.md creation"
        } else {
            # Map profile to file extension
            $profileExt = switch ($primaryProfile) {
                'go-cli'      { 'go' }
                'go-web'      { 'go' }
                'iot-embedded' { 'yaml' }
                default        { 'ts' }
            }

            $machine = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { hostname }

            $templateContent = Get-Content $templatePath -Raw
            $templateContent = $templateContent -replace '\{\{PROJECT_NAME\}\}',    $projectName
            $templateContent = $templateContent -replace '\{\{PROJECT_DESCRIPTION\}\}', $concept.Description
            $templateContent = $templateContent -replace '\{\{PROFILE\}\}',         $primaryProfile
            $templateContent = $templateContent -replace '\{\{DEVSPACE\}\}',        $Data.DevSpace
            $templateContent = $templateContent -replace '\{\{AUTHOR\}\}',          $githubUser
            $templateContent = $templateContent -replace '\{\{MACHINE\}\}',         $machine
            $templateContent = $templateContent -replace '\{\{PROFILE_EXT\}\}',     $profileExt

            try {
                Set-Content -Path $claudeMdPath -Value $templateContent -Encoding utf8NoBOM
                Write-OK 'CLAUDE.md written from template'
                $claudeMdWritten = $true
            } catch {
                Write-Warn "Could not write CLAUDE.md: $_"
            }
        }
    }

    # ------------------------------------------------------------------
    # 3.3 Create Phase 0 GitHub issue
    # ------------------------------------------------------------------

    if ($ScaffoldResult.GitHubCreated) {
        Write-Step 'Creating Phase 0 GitHub issue...'

        $featuresSection = if ($concept.Features.Count -gt 0) {
            ($concept.Features | ForEach-Object { "- $_" }) -join "`n"
        } else {
            '- (not specified)'
        }
        $nonGoalsSection = if ($concept.NonGoals.Count -gt 0) {
            ($concept.NonGoals | ForEach-Object { "- $_" }) -join "`n"
        } else {
            '- (not specified)'
        }

        $issueBody = @"
## Concept

$($concept.Description)

## Problem statement

$($concept.Problem)

## Core features

$featuresSection

## Non-goals

$nonGoalsSection

## Acceptance criteria

- [ ] Concept validated with at least one potential user
- [ ] Tech stack confirmed appropriate for the problem
- [ ] Non-goals agreed upon by stakeholders
- [ ] CLAUDE.md reviewed and updated with any corrections

## Next steps

1. Review and refine this concept brief
2. Set up the development environment (`.\setup\stack.ps1`)
3. Create architecture doc in `docs/ARCHITECTURE.md`
4. Break the concept into implementable issues
"@

        try {
            $ghIssueOutput = & gh issue create `
                -R "$githubUser/$projectName" `
                --title "Phase 0 -- Concept validation: $projectName" `
                --body $issueBody `
                --label 'chore' `
                --label 'phase-1' 2>&1 | Out-String
            $ghIssueExit = $LASTEXITCODE

            if ($ghIssueExit -eq 0) {
                $issueUrl = $ghIssueOutput.Trim()
                Write-OK "Phase 0 issue created: $issueUrl"
                $issueCreated = $true
            } else {
                Write-Warn "Could not create GitHub issue (exit $ghIssueExit): $ghIssueOutput"
            }
        } catch {
            Write-Warn "gh issue create threw exception: $_"
        }
    }

    return @{
        ClaudeMdWritten = $claudeMdWritten
        IssueCreated    = $issueCreated
        IssueUrl        = $issueUrl
    }
}

# ---------------------------------------------------------------------------
# STEP 4: Workspace Open
# ---------------------------------------------------------------------------

function Invoke-WorkspaceOpen {
    <#
    .SYNOPSIS
        Displays the project summary and opens VS Code.
    .PARAMETER Data
        Hashtable returned by Invoke-ConceptCollection.
    .PARAMETER ScaffoldResult
        Hashtable returned by Invoke-Scaffolding.
    .PARAMETER ClaudeMdResult
        Hashtable returned by Invoke-ClaudeMdGeneration.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data,

        [Parameter(Mandatory)]
        [hashtable]$ScaffoldResult,

        [Parameter(Mandatory)]
        [hashtable]$ClaudeMdResult
    )

    $projectName = $Data.Name
    $targetDir   = $ScaffoldResult.TargetDir

    Write-Section "Project ready: $projectName"

    Write-Host "  Location: $targetDir"
    if ($ScaffoldResult.GitHubCreated) {
        Write-Host "  GitHub:   $($ScaffoldResult.RepoUrl)"
    }
    if ($ClaudeMdResult.IssueCreated) {
        Write-Host "  Issue #1: $($ClaudeMdResult.IssueUrl)"
    }
    Write-Host ''

    # Open VS Code workspace
    $workspacePath = Join-Path $targetDir "$projectName.code-workspace"
    if (Test-Path $workspacePath) {
        Write-Step "Opening VS Code: $workspacePath"
        try {
            & code $workspacePath
        } catch {
            Write-Warn "Could not open VS Code: $_"
            Write-Host "  Manual: code `"$workspacePath`""
        }
    } else {
        Write-Step "Opening VS Code: $targetDir"
        try {
            & code $targetDir
        } catch {
            Write-Warn "Could not open VS Code: $_"
            Write-Host "  Manual: code `"$targetDir`""
        }
    }

    Write-Host ''
    Write-Host '  Next steps:'
    Write-Host "  1. Review CLAUDE.md in $targetDir"
    if ($ClaudeMdResult.IssueCreated) {
        Write-Host "  2. Open GitHub issue #1 to review the concept: $($ClaudeMdResult.IssueUrl)"
    }
    Write-Host "  3. Run \`claude\` in the project directory to begin planning"
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

Write-Section 'Kit 3: New Project'
Write-Host '  Collects project concept and creates directory structure.'
Write-Host ''

$conceptData    = Invoke-ConceptCollection
$scaffoldResult = Invoke-Scaffolding -Data $conceptData
$claudeMdResult = Invoke-ClaudeMdGeneration -Data $conceptData -ScaffoldResult $scaffoldResult
Invoke-WorkspaceOpen -Data $conceptData -ScaffoldResult $scaffoldResult -ClaudeMdResult $claudeMdResult
